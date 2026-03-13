import Foundation

/// Manages Nostr profile metadata (display name, about, picture, etc.)
/// This is separate from key management — profiles are public metadata
/// that can be updated without touching the keys.
class ProfileManager {

    /// NIP-01 profile metadata
    struct Metadata: Codable {
        var name: String?
        var displayName: String?
        var about: String?
        var picture: String?
        var banner: String?
        var nip05: String?
        var lud16: String?  // Lightning address
        var website: String?
    }

    /// Cached metadata keyed by pubkey hex
    private var cache: [String: Metadata] = [:]

    /// Get cached metadata for a pubkey
    func metadata(for pubkeyHex: String) -> Metadata? {
        cache[pubkeyHex]
    }

    /// Update local metadata cache
    func updateMetadata(for pubkeyHex: String, metadata: Metadata) {
        cache[pubkeyHex] = metadata
        persistCache()
    }

    // MARK: - Persistence

    private let cacheKey = "profile_metadata_cache"

    private var sharedDefaults: UserDefaults? {
        UserDefaults(suiteName: "group.com.nostrkeep.signer")
    }

    func loadCache() {
        guard let data = sharedDefaults?.data(forKey: cacheKey),
              let decoded = try? JSONDecoder().decode([String: Metadata].self, from: data) else { return }
        cache = decoded
    }

    private func persistCache() {
        guard let data = try? JSONEncoder().encode(cache) else { return }
        sharedDefaults?.set(data, forKey: cacheKey)
    }
}
