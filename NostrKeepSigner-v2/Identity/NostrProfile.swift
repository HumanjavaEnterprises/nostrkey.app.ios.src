import Foundation

/// A Nostr identity (key pair) managed by NostrKeep Signer
struct NostrProfile: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    let npub: String
    let pubkeyHex: String
    var isActive: Bool
    let createdAt: Date
    let isSecureEnclave: Bool

    /// Truncated npub for display (npub1abc...xyz)
    var displayNpub: String {
        guard npub.count > 20 else { return npub }
        let prefix = npub.prefix(12)
        let suffix = npub.suffix(8)
        return "\(prefix)...\(suffix)"
    }
}
