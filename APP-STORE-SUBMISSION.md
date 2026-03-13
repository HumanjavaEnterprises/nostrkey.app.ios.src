# App Store Submission — NostrKeep Signer Authenticator for iOS

This document contains all the information needed to submit the NostrKeep Signer Authenticator for iOS to the Apple App Store.

> **Two-Product Strategy:** This is the standalone **Authenticator** app (`com.nostrkeep.signer`), distinct from the Safari Web Extension companion app at `nostrkey.browser.plugin.src/apple/` (`com.nostrkeep.signer.extension`). The two apps share a Keychain via App Groups but serve different primary functions and target different App Store categories. See "Relationship to Safari Extension" below.

## Prerequisites

- [x] Apple Developer account ($99/year)
- [x] Xcode 16.0+ with valid signing certificate
- [x] App Store Connect access
- [x] App icon (1024x1024px, SVG-rendered)
- [ ] Screenshots for iPhone (6.9" / 6.7")
- [ ] Privacy Policy URL live at nostrkeep.com/privacy.html
- [ ] Archive build uploaded

## App Store Listing

### App Name (30 chars max)
**NostrKeep Signer**

### Subtitle (30 chars max)
**Nostr Identity Authenticator**

### Promotional Text (170 chars, can update without new build)
```
Your Nostr identity, hardware-secured. Scan a QR code to authenticate on any Nostr service. Keys protected by Secure Enclave + Face ID. Add your npub to Apple Wallet.
```

### Keywords (100 chars, comma-separated)
```
nostr,authenticator,identity,keys,qr,scanner,secure-enclave,nip-46,signing,npub,nsec,privacy,wallet
```

### Description (4000 chars max)
```
NostrKeep Signer is the authenticator for the Nostr protocol. Scan a QR code, and you're signed in. Your private keys live in the Secure Enclave — hardware-isolated, biometric-protected, never extractable.

Think of NostrKeep Signer as the 1Password or Authy for Nostr. Websites and apps show you a QR code, you scan it with NostrKeep Signer, and you're authenticated — your private key never leaves your device.

HOW IT WORKS

1. Create or import your Nostr identity
2. Your private key is stored in the Secure Enclave with Face ID protection
3. When a Nostr app needs you to sign in, it shows a QR code
4. Scan the QR code with NostrKeep Signer — authentication happens instantly
5. Your key never touches the browser or the app you're signing into

KEY FEATURES

• QR Code Scanner — scan to authenticate on any Nostr service, add relays, or import keys
• Secure Enclave Storage — private keys protected by hardware isolation + Face ID / Touch ID
• Dashboard — manage multiple Nostr identities, switch profiles, see relay status at a glance
• NIP-46 Remote Signing — apps request signatures over relays, your key stays on your device
• One-Tap Relay Management — add relays by scanning a QR code or tapping a deep link
• Identity Card — your npub as a shareable QR code with copy and share actions
• Apple Wallet Integration — add your Nostr identity as a Wallet pass for meetups and events
• Deep Link Support — nostrkeepsigner:// URLs for add-relay, connect, import-keys, and wallet-pass
• Dark Theme — NostrKeep teal-on-navy color scheme matching the NostrKeep Signer browser extension

WORKS WITH THE NOSTRKEEP SIGNER SAFARI EXTENSION

NostrKeep Signer Authenticator and the NostrKeep Signer Safari Web Extension share a secure Keychain via App Groups. When both are installed:

• The Safari extension detects your Secure Enclave keys automatically
• Browser signing is upgraded from software keys to hardware-secured keys
• No manual configuration needed — they find each other through the shared Keychain
• Use the extension for quick browser interactions, the app for high-security signing

You don't need both — each works independently — but together they form a two-tier security model: convenience in the browser, hardware security on your device.

SECURITY

All private key material stays on your device. Keys are stored in the Secure Enclave with biometric access control — every signing operation requires Face ID or Touch ID. No data is collected, no analytics, no tracking. NostrKeep Signer is fully open source under the MIT license.

SUPPORTED NIPS

NIP-01 (Basic protocol), NIP-07 (Key management), NIP-19 (Bech32 encoding), NIP-44 (Encrypted messaging v2), NIP-46 (Nostr Connect / remote signing)

OPEN SOURCE

Audit the code yourself at github.com/HumanjavaEnterprises.

Your identity. Your keys. Your rules.
```

### What's New (Version 2.0)
```
Completely rebuilt from the ground up as a native SwiftUI authenticator.

• New: QR code scanner for NIP-46 remote signing
• New: Secure Enclave key storage with Face ID
• New: Dashboard with profile management
• New: One-tap relay management via QR codes and deep links
• New: Identity card with shareable npub QR code
• New: Camera permission handling with Settings redirect
• New: NostrKeep teal-on-navy dark theme
• New: Shared Keychain bridge with Safari extension
```

### Category
**Utilities**

### Secondary Category
**Productivity**

### Content Rights
**Does not contain third-party content that requires rights.**

### Age Rating
**4+** (no objectionable content)

## Relationship to Safari Extension

NostrKeep Signer exists as two complementary products on the App Store:

| | NostrKeep Signer Authenticator | NostrKeep Signer Web Extension |
|---|---|---|
| **Bundle ID** | `com.nostrkeep.signer` | `com.nostrkeep.signer.extension` |
| **Category** | Utilities | Safari Extensions |
| **Primary UI** | Camera / QR scanner + dashboard | Browser toolbar popup |
| **Key Storage** | Secure Enclave (hardware) | Keychain (software) |
| **Authentication** | Face ID / Touch ID per operation | Master password + auto-lock |
| **Primary Function** | QR-based identity authentication | NIP-07 browser signing injection |
| **App Groups** | `group.com.nostrkeep.signer` (shared) | `group.com.nostrkeep.signer` (shared) |

**Why two apps?** The Safari extension injects `window.nostr` into web pages for seamless browser-based signing. The authenticator app provides hardware-secured key storage and QR-based authentication that works with any Nostr client, not just browsers. Different app categories, different primary interfaces, different use cases — like how 1Password has both a Safari extension and a standalone app.

**Bridge behavior:** When both apps are installed, the Safari extension automatically detects Secure Enclave keys stored by the authenticator via the shared App Group Keychain (`H48PW6TC25.group.com.nostrkeep.signer`). It upgrades its signing operations from software keys to hardware-secured keys transparently.

## Privacy Details (App Store Connect)

### Data Collection
**We do NOT collect any user data.**

Select: **Data Not Collected**

### Privacy Policy URL
**https://nostrkeep.com/privacy.html**

### Privacy Nutrition Label
| Data Type | Collected | Linked to Identity | Tracking |
|-----------|-----------|-------------------|----------|
| All types | No | No | No |

## Required Assets

### App Icon
- 1024x1024px PNG (rendered from NostrKeepSigner-logo.svg)
- Located: `NostrKeepSigner/Assets.xcassets/AppIcon.appiconset/icon-1024.png`

### Screenshots

#### iPhone 6.9" (required — iPhone 17 Pro Max)
- Resolution: 1320x2868
- Located: `QA-AUTOMATION/screenshots/appstore/phone-6.9/`
- Screens to capture:
  1. Home dashboard — active profile card with QR, profile list, relay status
  2. QR Scanner — camera viewfinder with scan overlay
  3. Scan result — relay URL detected, "Add Relay" confirmation sheet
  4. Identity card — full npub QR code with copy/share/wallet actions
  5. Relay list — configured relays with status indicators
  6. Settings — security status, NIP-46 sessions, profile management

#### iPhone 6.7" (optional — covers iPhone 15 Pro Max, 14 Pro Max)
- Resolution: 1290x2796
- Can reuse 6.9" screenshots (App Store Connect auto-scales)

## App Review Information

### Demo Account
Not applicable — NostrKeep Signer generates keys locally. No account, server, or subscription needed.

### Review Notes
```
NostrKeep Signer Authenticator is a native SwiftUI app that provides QR-based Nostr identity authentication with Secure Enclave key storage. It is NOT a browser extension wrapper — it is a standalone authenticator built with AVFoundation (camera), Security framework (Keychain/Secure Enclave), LocalAuthentication (Face ID), and CoreImage (QR generation).

This app is distinct from our NostrKeep Signer Safari Web Extension (com.nostrkeep.signer.extension). The web extension injects window.nostr into Safari for browser-based signing. This authenticator app provides hardware-secured key storage and QR-based authentication — a different app category, different primary interface, and different use case. They share a Keychain via App Groups so users who install both get upgraded security automatically.

Key functionality:
1. Generate or import Nostr private keys (nsec bech32 format)
2. Store keys in the Keychain with Secure Enclave protection + Face ID
3. Scan QR codes to authenticate on Nostr services (NIP-46 remote signing)
4. Scan QR codes to add relays or import keys
5. View public key (npub) as a QR code for sharing
6. Manage multiple Nostr identities with profile switching
7. Configure relay connections with NIP-11 metadata fetching
8. Deep link support for nostrkeepsigner:// and nostrconnect:// URI schemes

To test:
1. Launch the app — tap "Create New Identity" on the onboarding screen
2. The Home tab shows your active profile with npub QR code
3. Tap profiles in the list to switch active identity
4. Go to the Scanner tab — grant camera permission when prompted
5. Visit nostrkeep.com/test-qr-codes on another device to get test QR codes
6. Scan a relay URL QR (wss://relay.damus.io) — the app offers to add it
7. Scan an npub QR — the app shows the profile view
8. View the Identity tab for your full npub QR with copy/share actions
9. The Relays tab shows configured relays with status
10. Settings shows security status and profile management

Camera usage: Required for QR code scanning (AVFoundation). If permission is denied, the Scanner tab shows an "Open Settings" button to re-enable it.

Face ID usage: Protects private key access. If biometrics aren't available (e.g., Simulator), falls back to device-unlock-only Keychain protection.

No external account, server, or subscription is needed. Network connections go only to user-configured Nostr relays for NIP-46 sessions and NIP-11 metadata fetching. All key material is stored locally in the device Keychain.

Precedent: This two-product model (browser extension + standalone authenticator) follows the pattern established by 1Password, Authy, and Microsoft Authenticator, all of which have both Safari extensions and standalone iOS apps on the App Store.
```

### Contact Information
- **Website:** https://nostrkeep.com
- **Support URL:** https://nostrkeep.com/support.html
- **Marketing URL:** https://nostrkeep.com
- **GitHub:** https://github.com/HumanjavaEnterprises/nostrkey.app.ios.src

## Build & Archive

### Version
- `MARKETING_VERSION`: 2.0.0
- `CURRENT_PROJECT_VERSION`: 1
- Bundle ID: `com.nostrkeep.signer`
- Minimum iOS: 17.0
- Swift: 5.9
- Xcode: 16.0+

### Archive from Xcode
```bash
# 1. Generate project (if using XcodeGen)
cd nostrkey.app.ios.src
xcodegen generate

# 2. Open in Xcode
open NostrKeepSigner.xcodeproj

# 3. Select signing team in project settings
#    Xcode → NostrKeepSigner target → Signing & Capabilities → Team

# 4. Verify entitlements
#    - App Groups: group.com.nostrkeep.signer
#    - Keychain Sharing: $(AppIdentifierPrefix)group.com.nostrkeep.signer

# 5. Archive
#    Product → Archive (requires "Any iOS Device" destination)

# 6. Distribute
#    Window → Organizer → select archive → Distribute App → App Store Connect
```

### Archive from command line
```bash
# Archive
xcodebuild -project NostrKeepSigner.xcodeproj \
    -scheme NostrKeepSigner \
    -destination 'generic/platform=iOS' \
    -configuration Release \
    -archivePath build/NostrKeepSigner.xcarchive \
    archive

# Export for App Store
xcodebuild -exportArchive \
    -archivePath build/NostrKeepSigner.xcarchive \
    -exportOptionsPlist ExportOptions.plist \
    -exportPath build/AppStore
```

## Submission Checklist

- [ ] Apple Developer account active
- [ ] App Store Connect entry created for "NostrKeep Signer" (com.nostrkeep.signer)
- [ ] Fill out app description, subtitle, keywords
- [ ] Upload promotional text
- [ ] Set categories (Utilities + Productivity)
- [ ] Upload screenshots (iPhone 6.9" minimum)
- [ ] Set privacy declarations (Data Not Collected)
- [ ] Add privacy policy URL
- [ ] Add support URL
- [ ] Add review notes (include two-product explanation)
- [ ] Select signing team in Xcode
- [ ] Verify App Groups + Keychain entitlements
- [ ] Archive and upload build from Xcode
- [ ] Select build in App Store Connect
- [ ] Submit for review

## Review Timeline

- Initial review: typically 1-3 days
- This app may receive questions about:
  - **Relationship to Safari extension** — explain two-product model with different categories, interfaces, and use cases (see review notes)
  - **Secure Enclave usage** — keys stored in Keychain with SecAccessControl biometric policy, not native SE key generation (secp256k1 is not SE-native)
  - **Camera usage** — AVFoundation for QR code scanning, not photo/video capture
  - **Relay connections** — WebSocket connections to user-configured Nostr relays only

## Post-Submission

### If Approved
- Update README.md with App Store link and badge
- Update nostrkeep.com with iOS authenticator download link
- Add deep link from Safari extension to App Store listing
- Announce on Nostr

### If Rejected
- Review feedback in Resolution Center
- Common issues:
  - **4.3(a) Spam (duplicate app)** — respond with two-product comparison table showing different categories, different primary interfaces, different bundle IDs, different use cases. Cite 1Password/Authy precedent.
  - **Camera permission** — explain AVFoundation QR scanning for NIP-46 authentication
  - **Minimal functionality** — demonstrate dashboard, QR scanner, identity card, relay management, profile switching, deep links

---

*Last updated: March 9, 2026*
*Published by Humanjava Enterprises Inc.*
