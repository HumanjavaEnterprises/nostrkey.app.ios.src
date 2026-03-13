import Foundation

/// Handles nostrkeepsigner:// and nostrconnect:// deep links
@MainActor
enum DeepLinkHandler {

    static func handle(url: URL, appState: AppState) {
        guard let scheme = url.scheme?.lowercased() else { return }

        switch scheme {
        case "nostrkeepsigner":
            handleNostrKeepSignerLink(url: url, appState: appState)
        case "nostrconnect":
            handleNostrConnect(url: url, appState: appState)
        default:
            break
        }
    }

    // MARK: - nostrkeepsigner:// links

    private static func handleNostrKeepSignerLink(url: URL, appState: AppState) {
        guard let host = url.host?.lowercased() else { return }
        let params = url.queryParameters

        switch host {
        case "add-relay":
            handleAddRelay(params: params, appState: appState)

        case "connect":
            handleConnect(params: params, appState: appState)

        case "import-keys":
            handleImportKeys(params: params, appState: appState)

        case "wallet-pass":
            handleWalletPass(params: params, appState: appState)

        default:
            break
        }
    }

    // MARK: - nostrkeepsigner://add-relay

    private static func handleAddRelay(params: [String: String], appState: AppState) {
        guard let relayURL = params["url"] else { return }

        let name = params["name"] ?? relayURL
        let paid = params["paid"] == "true"

        appState.addRelay(url: relayURL, name: name, paid: paid)
        appState.selectedTab = .relays
    }

    // MARK: - nostrkeepsigner://connect (NIP-46)

    private static func handleConnect(params: [String: String], appState: AppState) {
        guard params["pubkey"] != nil,
              params["relay"] != nil else { return }

        // TODO: Initiate NIP-46 connection with params["pubkey"] and params["relay"]
        appState.selectedTab = .scanner
    }

    // MARK: - nostrconnect:// (NIP-46 standard URI)

    private static func handleNostrConnect(url: URL, appState: AppState) {
        // nostrconnect://pubkey?relay=wss://...&secret=...
        guard url.host != nil else { return }
        let params = url.queryParameters

        guard params["relay"] != nil else { return }

        // TODO: Initiate NIP-46 session using url.host, params["relay"], params["secret"]
        appState.selectedTab = .scanner
    }

    // MARK: - nostrkeepsigner://import-keys

    private static func handleImportKeys(params: [String: String], appState: AppState) {
        guard let nsec = params["nsec"] else { return }
        do {
            try appState.importKeys(nsec: nsec, name: params["name"] ?? "Imported")
        } catch {
            // TODO: Show error to user
            print("Import failed: \(error)")
        }
    }

    // MARK: - nostrkeepsigner://wallet-pass

    private static func handleWalletPass(params: [String: String], appState: AppState) {
        // TODO: Trigger WalletPassManager.requestPass() from deep link (nostrkeepsigner://wallet-pass?npub=...)
        appState.selectedTab = .identity
    }
}

// MARK: - URL Extension

extension URL {
    var queryParameters: [String: String] {
        guard let components = URLComponents(url: self, resolvingAgainstBaseURL: false),
              let items = components.queryItems else { return [:] }
        return items.reduce(into: [:]) { result, item in
            result[item.name] = item.value
        }
    }
}
