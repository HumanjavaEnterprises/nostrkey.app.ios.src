# CLAUDE.md — nostrkey.app.ios.src

## What This Is
NostrKeep Signer iOS app — a native SwiftUI Nostr identity authenticator. QR scanner as primary interface, Secure Enclave key storage, NIP-46 remote signing, Apple Wallet integration, and deep link relay management.

## Architecture (v2 — March 2026 Rebuild)
Complete rewrite from WebView-wrapper to native SwiftUI. No more bundled browser extension. The app is a standalone authenticator that holds keys and signs on behalf of any Nostr client.

### Source: `NostrKeepSigner-v2/`
```
NostrKeepSigner-v2/
├── App/           # SwiftUI app entry (NostrKeepSignerApp.swift), AppState, ContentView, DeepLinkHandler
├── Scanner/       # AVFoundation QR camera view
├── Identity/      # KeyManager (Secure Enclave), NostrProfile, ProfileManager
├── Relay/         # RelayManager, RelayInfo, NIP-11 metadata
├── NIP46/         # NIP-46 remote signing session management
├── Crypto/        # Bech32, NostrCrypto (nsec/npub encoding), event hashing
├── UI/            # IdentityCardView, RelayListView, SettingsView (NostrKeepSignerTheme colors)
├── Info.plist     # App config (camera + Face ID permissions, deep link schemes)
└── NostrKeepSigner.entitlements  # App Groups + Keychain sharing
```

### Legacy Source: `NostrKeepSigner/`
The original WebView-wrapper app (v1.x) is preserved in `NostrKeepSigner/` for reference. The v2 project.yml points to `NostrKeepSigner-v2/` sources but still uses `NostrKeepSigner/Assets.xcassets` for icons.

## Ecosystem Position
The authenticator for Nostr. Holds keys in Secure Enclave, signs via NIP-46 for any client. Shares keys with the Safari extension via App Group Keychain (`group.com.nostrkeep.signer`).

## Current Version
v2.0.0 (Build 1) — Native SwiftUI rebuild

## Tech Stack
- Swift 5.9, SwiftUI, Xcode 16.0+, iOS 17.0+
- AVFoundation (QR camera)
- Security framework + CryptoKit (Keychain with Secure Enclave protection)
- LocalAuthentication (Face ID / Touch ID)
- CoreImage (QR code generation)
- URLSessionWebSocketTask (NIP-46 relay communication)
- XcodeGen for project generation

## Theme
- Teal (#2dd4bf) on navy (#0f172a)
- Color names: NostrKeepSignerTheme
- Bundle ID: `com.nostrkeep.signer`

## Build
```bash
xcodegen generate
open NostrKeepSigner.xcodeproj
# Build & Run in Xcode (requires physical device for camera + Secure Enclave)
```

## Key Architecture Decisions
- **SwiftUI-only** — no UIKit except for AVCaptureSession (camera requires UIKit)
- **Secure Enclave via Keychain** — secp256k1 keys stored with biometric access policy
- **App Group sharing** — `group.com.nostrkeep.signer` shared Keychain + UserDefaults
- **NIP-46 over WebSocket** — remote signing without key exposure
- **Deep links** — `nostrkeepsigner://add-relay`, `nostrkeepsigner://connect`, `nostrconnect://`
- **No web views** — pure native UI, no embedded browser extension

## TODO: Before Shipping
- [ ] Integrate swift-secp256k1 package for real key derivation + Schnorr signing
- [ ] Complete NIP-46 message parsing and encrypted response flow
- [ ] Apple Wallet pass generation (PassKit + server-side signing)
- [ ] Pass update push notification service
- [ ] NIP-49 (ncryptsec) encrypted relay backup
- [ ] App Store screenshots for authenticator flow

## Deep Link Schemes
- `nostrkeepsigner://add-relay?url=wss://...&name=...&paid=true`
- `nostrkeepsigner://connect?pubkey=...&relay=wss://...`
- `nostrkeepsigner://import-keys?nsec=nsec1...`
- `nostrkeepsigner://wallet-pass?npub=npub1...`
- `nostrconnect://pubkey?relay=wss://...&secret=...`

## Related Repos
- `nostrkey.browser.plugin.src` — Safari/Chrome extension (NIP-07)
- `nostrkey.app.android.src` — Android equivalent
- `nostrkey.bizdocs.src` — business strategy (see NostrKeep-Signer-App-Architecture.md)
