import Foundation
import PassKit

/// Manages Apple Wallet pass requests for Nostr identity cards.
/// Downloads signed .pkpass files from the relay server using NIP-98 HTTP auth.
@MainActor
class WalletPassManager: ObservableObject {

    enum WalletState: Equatable {
        case idle
        case loading
        case success(Data)
        case error(String)

        static func == (lhs: WalletState, rhs: WalletState) -> Bool {
            switch (lhs, rhs) {
            case (.idle, .idle): return true
            case (.loading, .loading): return true
            case (.success, .success): return true
            case (.error(let a), .error(let b)): return a == b
            default: return false
            }
        }
    }

    @Published var state: WalletState = .idle
    @Published var pass: PKPass?

    // TODO: NIP-98 auth produces invalid signatures until swift-secp256k1 is integrated into KeyManager
    // TODO: Add pass update push notification registration (PKPassLibrary.addPasses + webServiceURL)
    // TODO: Cache downloaded .pkpass locally so users can re-add without re-downloading

    /// The relay endpoint that generates signed .pkpass files
    private let passEndpoint = "https://relay.nostrkeep.com/pass"

    /// Whether PassKit is available on this device (not available in Simulator)
    static var isAvailable: Bool {
        PKPassLibrary.isPassLibraryAvailable()
    }

    /// Check if a pass for this npub already exists in Apple Wallet
    func hasExistingPass(for npub: String) -> Bool {
        guard Self.isAvailable else { return false }
        let library = PKPassLibrary()
        return library.passes().contains { $0.serialNumber == npub }
    }

    /// Request a signed .pkpass from the relay server
    /// - Parameters:
    ///   - npub: The bech32-encoded public key
    ///   - displayName: Name shown on the pass
    ///   - keyManager: KeyManager instance for signing the NIP-98 event
    ///   - pubkeyHex: Hex-encoded public key for signing
    func requestPass(npub: String, displayName: String, keyManager: KeyManager, pubkeyHex: String) async {
        state = .loading

        do {
            // Build NIP-98 kind 27235 auth event
            let createdAt = Int(Date().timeIntervalSince1970)
            let tags: [[String]] = [
                ["u", passEndpoint],
                ["method", "POST"]
            ]
            let content = ""

            let eventIdData = NostrCrypto.computeEventId(
                pubkey: pubkeyHex,
                createdAt: createdAt,
                kind: 27235,
                tags: tags,
                content: content
            )
            let eventId = NostrCrypto.hexEncode(eventIdData)

            // Sign the event hash (placeholder until swift-secp256k1)
            let sigData = try keyManager.signEvent(eventHash: eventIdData, withPubkey: pubkeyHex)
            let sig = NostrCrypto.hexEncode(sigData)

            // Build the Nostr event JSON
            let event: [String: Any] = [
                "id": eventId,
                "pubkey": pubkeyHex,
                "created_at": createdAt,
                "kind": 27235,
                "tags": tags,
                "content": content,
                "sig": sig
            ]

            let eventJson = try JSONSerialization.data(withJSONObject: event)
            let base64Event = eventJson.base64EncodedString()

            // Build the pass request body
            let body: [String: String] = [
                "npub": npub,
                "name": displayName
            ]

            var request = URLRequest(url: URL(string: passEndpoint)!)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue("Nostr \(base64Event)", forHTTPHeaderField: "Authorization")
            request.httpBody = try JSONSerialization.data(withJSONObject: body)

            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                state = .error("Invalid server response")
                return
            }

            if httpResponse.statusCode == 401 {
                state = .error("Authentication failed. NIP-98 signing requires secp256k1 integration.")
                return
            }

            guard httpResponse.statusCode == 200 else {
                let errorBody = String(data: data, encoding: .utf8) ?? "Unknown error"
                state = .error("Server error (\(httpResponse.statusCode)): \(errorBody)")
                return
            }

            // Parse the .pkpass data
            let pkPass = try PKPass(data: data)
            pass = pkPass
            state = .success(data)

        } catch let error as NostrError {
            state = .error(error.localizedDescription)
        } catch {
            state = .error("Failed to download pass: \(error.localizedDescription)")
        }
    }

    func reset() {
        state = .idle
        pass = nil
    }
}
