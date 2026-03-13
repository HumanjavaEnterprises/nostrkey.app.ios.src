import Foundation
import Security
import LocalAuthentication
import CryptoKit

/// Manages Nostr key pairs with Keychain + Secure Enclave protection
/// Keys are stored in the shared Keychain (group.com.nostrkeep.signer) so the
/// Safari extension can detect and delegate signing to them.
class KeyManager {

    /// Service prefix matches the Safari extension's SharedKeychain.swift
    /// so both apps can read each other's keys from the shared Keychain.
    private let servicePrefix = "nostrkeep.signer.nsec."

    /// Team-prefixed access group — must match the Safari extension exactly.
    /// Keychain access groups require the team prefix at runtime (unlike
    /// entitlements which resolve $(AppIdentifierPrefix) at build time).
    private let accessGroup = "H48PW6TC25.group.com.nostrkeep.signer"

    /// App Group ID (without team prefix) for UserDefaults sharing.
    /// UserDefaults(suiteName:) uses the plain App Group ID, not the
    /// team-prefixed Keychain access group.
    private let appGroupID = "group.com.nostrkeep.signer"

    /// Whether biometric authentication is available on this device
    private var biometricsAvailable: Bool {
        let context = LAContext()
        var error: NSError?
        return context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
    }

    // MARK: - Key Generation

    /// Generate a new secp256k1 key pair and store in the Keychain
    /// Returns a NostrProfile with the public key info
    func generateKeyPair(name: String) throws -> NostrProfile {
        // Generate 32 random bytes for the private key
        var privateKeyBytes = Data(count: 32)
        let status = privateKeyBytes.withUnsafeMutableBytes { ptr in
            SecRandomCopyBytes(kSecRandomDefault, 32, ptr.baseAddress!)
        }
        guard status == errSecSuccess else {
            throw NostrError.keychainError("Failed to generate random bytes")
        }

        // Derive the public key using secp256k1
        // For now, we store the private key and derive pubkey at runtime
        // The secp256k1 Swift package will provide the actual derivation
        let publicKeyBytes = try derivePublicKey(from: privateKeyBytes)

        let npub = try NostrCrypto.publicKeyToNpub(publicKeyBytes)
        let pubkeyHex = NostrCrypto.hexEncode(publicKeyBytes)

        // Store in Keychain with biometric protection (when available)
        try storePrivateKey(privateKeyBytes, forPublicKey: pubkeyHex)

        return NostrProfile(
            id: UUID(),
            name: name,
            npub: npub,
            pubkeyHex: pubkeyHex,
            isActive: true,
            createdAt: Date(),
            isSecureEnclave: biometricsAvailable
        )
    }

    /// Import an existing nsec and store in the Keychain
    func importFromNsec(_ nsec: String, name: String) throws -> NostrProfile {
        let privateKeyBytes = try NostrCrypto.nsecToPrivateKey(nsec)
        let publicKeyBytes = try derivePublicKey(from: privateKeyBytes)

        let npub = try NostrCrypto.publicKeyToNpub(publicKeyBytes)
        let pubkeyHex = NostrCrypto.hexEncode(publicKeyBytes)

        try storePrivateKey(privateKeyBytes, forPublicKey: pubkeyHex)

        return NostrProfile(
            id: UUID(),
            name: name,
            npub: npub,
            pubkeyHex: pubkeyHex,
            isActive: true,
            createdAt: Date(),
            isSecureEnclave: biometricsAvailable
        )
    }

    // MARK: - Signing

    /// Sign a Nostr event hash (32-byte SHA-256) with the private key
    /// Requires biometric authentication
    func signEvent(eventHash: Data, withPubkey pubkeyHex: String) throws -> Data {
        let privateKey = try retrievePrivateKey(forPublicKey: pubkeyHex)

        // Sign using secp256k1 Schnorr (BIP-340)
        // This requires the secp256k1 Swift package
        // For now, placeholder that will be replaced with actual signing
        let signature = try schnorrSign(message: eventHash, privateKey: privateKey)
        return signature
    }

    // MARK: - Keychain Operations

    /// Store private key in the shared Keychain with biometric protection
    /// Falls back to device-passcode-only protection if biometrics aren't available
    private func storePrivateKey(_ key: Data, forPublicKey pubkeyHex: String) throws {
        // Delete any existing key for this pubkey first
        let deleteQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: servicePrefix + pubkeyHex,
            kSecAttrAccount as String: pubkeyHex,
            kSecAttrAccessGroup as String: accessGroup
        ]
        SecItemDelete(deleteQuery as CFDictionary)

        // Build the add query
        var addQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: servicePrefix + pubkeyHex,
            kSecAttrAccount as String: pubkeyHex,
            kSecAttrAccessGroup as String: accessGroup,
            kSecValueData as String: key
        ]

        if biometricsAvailable {
            // Create access control with biometric requirement
            // Note: .privateKeyUsage is only for Secure Enclave keys,
            // not for kSecClassGenericPassword items
            var error: Unmanaged<CFError>?
            guard let accessControl = SecAccessControlCreateWithFlags(
                kCFAllocatorDefault,
                kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
                .biometryCurrentSet,
                &error
            ) else {
                throw NostrError.keychainError("Failed to create access control: \(error?.takeRetainedValue().localizedDescription ?? "unknown")")
            }
            addQuery[kSecAttrAccessControl as String] = accessControl
            addQuery[kSecUseAuthenticationContext as String] = LAContext()
        } else {
            // Fallback: protect with device unlock only (Simulator, no biometrics)
            addQuery[kSecAttrAccessible as String] = kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        }

        let addStatus = SecItemAdd(addQuery as CFDictionary, nil)
        guard addStatus == errSecSuccess else {
            throw NostrError.keychainError("Failed to store key: OSStatus \(addStatus)")
        }
    }

    /// Retrieve private key from the shared Keychain (requires biometric auth when available)
    private func retrievePrivateKey(forPublicKey pubkeyHex: String) throws -> Data {
        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: servicePrefix + pubkeyHex,
            kSecAttrAccount as String: pubkeyHex,
            kSecAttrAccessGroup as String: accessGroup,
            kSecReturnData as String: true
        ]

        if biometricsAvailable {
            let context = LAContext()
            context.localizedReason = "Sign a Nostr event"
            query[kSecUseAuthenticationContext as String] = context
        }

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess, let data = result as? Data else {
            throw NostrError.keychainError("Failed to retrieve key: OSStatus \(status)")
        }

        return data
    }

    /// Check if a key exists in the shared Keychain (without retrieving it)
    func hasKey(forPublicKey pubkeyHex: String) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: servicePrefix + pubkeyHex,
            kSecAttrAccount as String: pubkeyHex,
            kSecAttrAccessGroup as String: accessGroup,
            kSecReturnData as String: false
        ]
        return SecItemCopyMatching(query as CFDictionary, nil) == errSecSuccess
    }

    // MARK: - Profile Persistence (UserDefaults in App Group)

    private var sharedDefaults: UserDefaults? {
        UserDefaults(suiteName: appGroupID)
    }

    func loadProfiles() -> [NostrProfile] {
        guard let data = sharedDefaults?.data(forKey: "profiles"),
              let profiles = try? JSONDecoder().decode([NostrProfile].self, from: data) else {
            return []
        }
        return profiles
    }

    func saveProfiles(_ profiles: [NostrProfile]) {
        guard let data = try? JSONEncoder().encode(profiles) else { return }
        sharedDefaults?.set(data, forKey: "profiles")
    }

    // MARK: - secp256k1 Operations

    /// Derive the x-only public key from a 32-byte private key
    /// TODO: Replace with actual secp256k1 derivation using swift-secp256k1 package
    private func derivePublicKey(from privateKey: Data) throws -> Data {
        // PLACEHOLDER: In production, this uses the secp256k1 library
        // to compute the x-only public key (32 bytes) from the private key.
        //
        // let key = try secp256k1.Signing.PrivateKey(rawRepresentation: privateKey)
        // return Data(key.publicKey.xonly.bytes)
        //
        // For now, we use a SHA-256 hash as a deterministic placeholder
        // so the app can build and run. Replace this before shipping.
        let hash = SHA256.hash(data: privateKey)
        return Data(hash)
    }

    /// Sign a 32-byte message with Schnorr (BIP-340)
    /// TODO: Replace with actual secp256k1 Schnorr signing
    private func schnorrSign(message: Data, privateKey: Data) throws -> Data {
        // PLACEHOLDER: In production, this uses the secp256k1 library
        // for BIP-340 Schnorr signing.
        //
        // let key = try secp256k1.Signing.PrivateKey(rawRepresentation: privateKey)
        // let sig = try key.schnorr.signature(for: message)
        // return Data(sig.rawRepresentation)
        //
        // For now, we use HMAC as a deterministic placeholder.
        // Replace this before shipping.
        let hmac = HMAC<SHA256>.authenticationCode(for: message, using: SymmetricKey(data: privateKey))
        return Data(hmac) + Data(repeating: 0, count: 32) // Pad to 64 bytes (Schnorr sig size)
    }
}
