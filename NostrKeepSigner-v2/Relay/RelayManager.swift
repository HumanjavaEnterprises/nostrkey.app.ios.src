import Foundation

/// Relay connection info
struct RelayInfo: Identifiable, Codable, Equatable {
    let id: UUID
    let url: String
    var name: String
    var paid: Bool
    let addedAt: Date
    var isConnected: Bool

    init(id: UUID = UUID(), url: String, name: String, paid: Bool = false, addedAt: Date = Date(), isConnected: Bool = false) {
        self.id = id
        self.url = url
        self.name = name
        self.paid = paid
        self.addedAt = addedAt
        self.isConnected = isConnected
    }
}

/// Manages the user's relay list
/// Persisted in the shared App Group UserDefaults so the Safari extension
/// can also access the relay list.
class RelayManager {

    private let storageKey = "relay_list"
    private let accessGroup = "group.com.nostrkeep.signer"

    private var sharedDefaults: UserDefaults? {
        UserDefaults(suiteName: accessGroup)
    }

    // MARK: - Persistence

    func loadRelays() -> [RelayInfo] {
        guard let data = sharedDefaults?.data(forKey: storageKey),
              let relays = try? JSONDecoder().decode([RelayInfo].self, from: data) else {
            return defaultRelays()
        }
        return relays
    }

    func saveRelays(_ relays: [RelayInfo]) {
        guard let data = try? JSONEncoder().encode(relays) else { return }
        sharedDefaults?.set(data, forKey: storageKey)
    }

    // MARK: - Defaults

    /// Default relays for new users
    private func defaultRelays() -> [RelayInfo] {
        [
            RelayInfo(url: "wss://relay.damus.io", name: "Damus"),
            RelayInfo(url: "wss://relay.nostr.band", name: "Nostr Band"),
            RelayInfo(url: "wss://nos.lol", name: "nos.lol"),
        ]
    }

    // MARK: - Relay Metadata (NIP-11)

    /// Fetch relay metadata using NIP-11 (HTTP request to relay URL)
    func fetchMetadata(for relayURL: String) async throws -> RelayMetadata? {
        // Convert wss:// to https:// for NIP-11 info document
        let httpURL = relayURL
            .replacingOccurrences(of: "wss://", with: "https://")
            .replacingOccurrences(of: "ws://", with: "http://")

        guard let url = URL(string: httpURL) else { return nil }

        var request = URLRequest(url: url)
        request.addValue("application/nostr+json", forHTTPHeaderField: "Accept")
        request.timeoutInterval = 10

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else { return nil }

        return try JSONDecoder().decode(RelayMetadata.self, from: data)
    }
}

/// NIP-11 relay metadata
struct RelayMetadata: Codable {
    let name: String?
    let description: String?
    let pubkey: String?
    let contact: String?
    let supportedNips: [Int]?
    let software: String?
    let version: String?

    enum CodingKeys: String, CodingKey {
        case name, description, pubkey, contact
        case supportedNips = "supported_nips"
        case software, version
    }
}
