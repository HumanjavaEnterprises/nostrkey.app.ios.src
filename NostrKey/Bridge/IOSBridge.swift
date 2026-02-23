import Foundation
import WebKit
import UIKit

/// WKScriptMessageHandler exposed as `nostrkey` to each WKWebView.
///
/// Each WebView (background + UI) gets its own instance. The `webView` reference
/// points to the WebView this bridge is attached to; `peer` points to the other.
///
/// Message routing:
///   UI  → sendMessage   → background's __nostrkey_deliverMessage
///   BG  → sendResponse  → UI's __nostrkey_resolveCallback
///
/// Storage operations always resolve on `webView` (self).
class IOSBridge: NSObject, WKScriptMessageHandler {

    private weak var webView: WKWebView?
    private weak var peer: WKWebView?
    private let onNavigate: (String) -> Void
    private let onScanQR: (() -> Void)?

    private var pendingScanCallbackId: String?
    private let storageKey = "nostrkey_storage"
    private let dataKey = "__data__"

    init(
        webView: WKWebView,
        onNavigate: @escaping (String) -> Void,
        onScanQR: (() -> Void)? = nil
    ) {
        self.webView = webView
        self.onNavigate = onNavigate
        self.onScanQR = onScanQR
        super.init()
    }

    func setPeer(_ peerWebView: WKWebView) {
        self.peer = peerWebView
    }

    // MARK: - WKScriptMessageHandler

    func userContentController(
        _ userContentController: WKUserContentController,
        didReceive message: WKScriptMessage
    ) {
        guard let body = message.body as? [String: Any],
              let action = body["action"] as? String else {
            return
        }

        let callbackId = body["callbackId"] as? String ?? ""
        let data = body["data"] as? String

        switch action {
        case "sendMessage":
            handleSendMessage(callbackId: callbackId, msgJson: data ?? "{}")
        case "sendResponse":
            handleSendResponse(callbackId: callbackId, responseJson: data ?? "null")
        case "storageGet":
            handleStorageGet(callbackId: callbackId, keysJson: data ?? "null")
        case "storageSet":
            handleStorageSet(callbackId: callbackId, itemsJson: data ?? "{}")
        case "storageRemove":
            handleStorageRemove(callbackId: callbackId, keysJson: data ?? "[]")
        case "storageClear":
            handleStorageClear(callbackId: callbackId)
        case "navigateTo":
            if let url = data {
                DispatchQueue.main.async { self.onNavigate(url) }
            }
        case "copyToClipboard":
            if let text = data {
                UIPasteboard.general.string = text
            }
        case "scanQR":
            handleScanQR(callbackId: callbackId)
        default:
            print("[IOSBridge] Unknown action: \(action)")
        }
    }

    // MARK: - Message Routing

    private func handleSendMessage(callbackId: String, msgJson: String) {
        let escapedId = escapeForJS(callbackId)
        let escapedMsg = escapeForJS(msgJson)
        let js = "window.__nostrkey_deliverMessage(\(escapedId),\(escapedMsg))"
        DispatchQueue.main.async { [weak self] in
            self?.peer?.evaluateJavaScript(js, completionHandler: nil)
        }
    }

    private func handleSendResponse(callbackId: String, responseJson: String) {
        let escapedId = escapeForJS(callbackId)
        let escapedResp = escapeForJS(responseJson)
        let js = "window.__nostrkey_resolveCallback(\(escapedId),\(escapedResp))"
        DispatchQueue.main.async { [weak self] in
            self?.peer?.evaluateJavaScript(js, completionHandler: nil)
        }
    }

    // MARK: - Storage

    private func handleStorageGet(callbackId: String, keysJson: String) {
        let storage = getStorage()
        var result: [String: Any] = [:]

        if keysJson == "null" || keysJson.isEmpty {
            // Return everything
            result = storage
        } else if let data = keysJson.data(using: .utf8),
                  let parsed = try? JSONSerialization.jsonObject(with: data) {
            if let key = parsed as? String {
                if let value = storage[key] {
                    result[key] = value
                }
            } else if let keys = parsed as? [String] {
                for key in keys {
                    if let value = storage[key] {
                        result[key] = value
                    }
                }
            } else if let defaults = parsed as? [String: Any] {
                for (key, defaultValue) in defaults {
                    result[key] = storage[key] ?? defaultValue
                }
            }
        }

        resolveOnSelf(callbackId: callbackId, json: toJSON(result))
    }

    private func handleStorageSet(callbackId: String, itemsJson: String) {
        var storage = getStorage()

        guard let data = itemsJson.data(using: .utf8),
              let items = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            resolveOnSelf(callbackId: callbackId, json: "{}")
            return
        }

        for (key, value) in items {
            storage[key] = value
        }
        saveStorage(storage)
        resolveOnSelf(callbackId: callbackId, json: "{}")

        // Write-through to App Group shared storage for Safari extension sync
        syncProfilesToSharedStorage(items: items)

        // Notify both WebViews about the change
        notifyStorageChanged(items: items)
    }

    // MARK: - App Group Sync

    /// When profiles are written to local storage, also write metadata to the
    /// shared App Group container and private keys to the shared Keychain.
    private func syncProfilesToSharedStorage(items: [String: Any]) {
        guard let profilesArray = items["profiles"] as? [[String: Any]] else { return }

        // Track which profile IDs are still present
        var currentIds = Set<String>()
        var sharedProfiles: [[String: Any]] = []

        for var profile in profilesArray {
            // Use existing id or pubKey as stable identifier
            let profileId = profile["id"] as? String
                ?? profile["pubKey"] as? String
                ?? UUID().uuidString

            currentIds.insert(profileId)

            // Save private key to shared Keychain separately
            if let privKey = profile["privKey"] as? String, !privKey.isEmpty {
                // Only sync plaintext hex keys — skip encrypted blobs
                if privKey.count == 64, privKey.range(of: "^[0-9a-f]+$", options: .regularExpression) != nil {
                    SharedKeychain.shared.savePrivateKey(profileId: profileId, privKey: privKey)
                }
            }

            // Strip private key from shared metadata
            profile.removeValue(forKey: "privKey")

            // Ensure the profile has a stable id for cross-app matching
            profile["id"] = profileId
            profile["lastSyncedAt"] = ISO8601DateFormatter().string(from: Date())
            sharedProfiles.append(profile)
        }

        SharedStorage.shared.saveProfiles(sharedProfiles)

        // Clean up Keychain entries for profiles that were removed
        let existingIds = SharedKeychain.shared.listProfileIds()
        for id in existingIds where !currentIds.contains(id) {
            SharedKeychain.shared.deletePrivateKey(profileId: id)
        }
    }

    private func handleStorageRemove(callbackId: String, keysJson: String) {
        var storage = getStorage()

        if let data = keysJson.data(using: .utf8),
           let keys = try? JSONSerialization.jsonObject(with: data) as? [String] {
            for key in keys {
                storage.removeValue(forKey: key)
            }
        }
        saveStorage(storage)
        resolveOnSelf(callbackId: callbackId, json: "{}")
    }

    private func handleStorageClear(callbackId: String) {
        saveStorage([:])
        resolveOnSelf(callbackId: callbackId, json: "{}")
    }

    // MARK: - QR Scanning

    private func handleScanQR(callbackId: String) {
        guard onScanQR != nil else {
            rejectOnSelf(callbackId: callbackId, message: "QR scanning not available")
            return
        }
        pendingScanCallbackId = callbackId
        DispatchQueue.main.async { self.onScanQR?() }
    }

    func deliverScanResult(_ text: String) {
        guard let id = pendingScanCallbackId else { return }
        pendingScanCallbackId = nil
        resolveOnSelf(callbackId: id, json: escapeForJS(text))
    }

    func deliverScanError(_ message: String) {
        guard let id = pendingScanCallbackId else { return }
        pendingScanCallbackId = nil
        rejectOnSelf(callbackId: id, message: message)
    }

    // MARK: - Internal Helpers

    private func getStorage() -> [String: Any] {
        guard let raw = UserDefaults.standard.string(forKey: storageKey),
              let data = raw.data(using: .utf8),
              let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return [:]
        }
        return obj
    }

    private func saveStorage(_ obj: [String: Any]) {
        if let data = try? JSONSerialization.data(withJSONObject: obj),
           let str = String(data: data, encoding: .utf8) {
            UserDefaults.standard.set(str, forKey: storageKey)
        }
    }

    private func resolveOnSelf(callbackId: String, json: String) {
        let escapedId = escapeForJS(callbackId)
        let escapedJson = escapeForJS(json)
        let js = "window.__nostrkey_resolveCallback(\(escapedId),\(escapedJson))"
        DispatchQueue.main.async { [weak self] in
            self?.webView?.evaluateJavaScript(js, completionHandler: nil)
        }
    }

    private func rejectOnSelf(callbackId: String, message: String) {
        let escapedId = escapeForJS(callbackId)
        let escapedMsg = escapeForJS(message)
        let js = "window.__nostrkey_rejectCallback(\(escapedId),\(escapedMsg))"
        DispatchQueue.main.async { [weak self] in
            self?.webView?.evaluateJavaScript(js, completionHandler: nil)
        }
    }

    private func notifyStorageChanged(items: [String: Any]) {
        // Build changes in the format storage.onChanged expects:
        // { key: { newValue: value } }
        var changes: [String: Any] = [:]
        for (key, value) in items {
            changes[key] = ["newValue": value]
        }
        let changesJson = toJSON(changes)
        let escapedChanges = escapeForJS(changesJson)
        let js = "if(window.__nostrkey_storageChanged){window.__nostrkey_storageChanged(\(escapedChanges),'local')}"
        DispatchQueue.main.async { [weak self] in
            self?.webView?.evaluateJavaScript(js, completionHandler: nil)
            self?.peer?.evaluateJavaScript(js, completionHandler: nil)
        }
    }

    private func escapeForJS(_ string: String) -> String {
        // JSONSerialization requires a top-level array/dict, so wrap in array
        // then extract the quoted string from the result: ["escaped"] → "escaped"
        if let data = try? JSONSerialization.data(withJSONObject: [string]),
           let json = String(data: data, encoding: .utf8) {
            // json is like: ["the \"escaped\" string"]
            // Drop the leading [ and trailing ]
            let start = json.index(after: json.startIndex)
            let end = json.index(before: json.endIndex)
            return String(json[start..<end])
        }
        // Fallback: manual escaping
        let escaped = string
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
            .replacingOccurrences(of: "\n", with: "\\n")
            .replacingOccurrences(of: "\r", with: "\\r")
            .replacingOccurrences(of: "\t", with: "\\t")
        return "\"\(escaped)\""
    }

    private func toJSON(_ obj: Any) -> String {
        guard let data = try? JSONSerialization.data(withJSONObject: obj),
              let str = String(data: data, encoding: .utf8) else {
            return "{}"
        }
        return str
    }
}
