# App Store Submission — NostrKey for iOS

This document contains all the information needed to submit NostrKey for iOS to the Apple App Store.

> **Note:** This is the standalone iOS app (dual-WKWebView wrapper), NOT the Safari extension companion app at `nostrkey.browser.plugin.src/apple/`.

## Prerequisites

- [x] Apple Developer account ($99/year)
- [x] Xcode with valid signing certificate
- [x] App Store Connect access
- [x] App icon (1024x1024px, SVG-rendered)
- [ ] Screenshots for iPhone (6.9" / 6.7")
- [ ] Privacy Policy URL live at nostrkey.com/privacy.html
- [ ] Archive build uploaded

## App Store Listing

### App Name (30 chars max)
**NostrKey**

### Subtitle (30 chars max)
**Nostr Keys & Encrypted Vault**

### Promotional Text (170 chars, can update without new build)
```
Manage your Nostr keys, sign events, and store encrypted documents — all on your phone. Lock screen QR sharing, master password, QR scanner, and NIP-44/46 support built in.
```

### Keywords (100 chars, comma-separated)
```
nostr,keys,nsec,npub,vault,encryption,signing,nsecbunker,privacy,qr,nip-07,nip-44,crypto,identity
```

### Description (4000 chars max)
```
NostrKey for iOS puts your Nostr identity in your pocket. Manage keys, sign events, and store encrypted documents — all without exposing your private key.

This app runs the full NostrKey extension natively on iOS, with platform integrations like QR code scanning and native clipboard.

KEY FEATURES

• Key management — create, import, and manage multiple Nostr profiles
• NIP-44 encryption — modern ChaCha20-Poly1305 encrypted messaging
• NIP-46 nsecBunker — remote signing, your private key never touches a browser
• NIP-49 encrypted export — ncryptsec key backup and restore
• Encrypted document vault — zero-knowledge .md storage on Nostr relays (NIP-78)
• API key vault — encrypted secret storage with relay sync
• Master password — keys encrypted at rest with configurable auto-lock (5/15/30/60 min)
• QR code scanner — scan npub, nsec, or ncryptsec keys with your camera
• Lock screen QR code — share your npub QR code without unlocking the app
• Lock screen profile display — see your active profile name and npub at a glance
• Dark theme — Monokai color scheme designed for key management
• Relay configuration — connect to your preferred Nostr relays

SECURITY

All private key material stays on your device. Documents are encrypted client-side before publishing to relays — relay operators see only ciphertext. Master password protects keys at rest with configurable auto-lock.

SUPPORTED NIPS

NIP-01 (Basic protocol), NIP-04 (Encrypted DMs v1, legacy), NIP-07 (Key management), NIP-19 (Bech32 encoding), NIP-44 (Encrypted messaging v2), NIP-46 (Nostr Connect / nsecBunker), NIP-49 (Encrypted key export), NIP-78 (App-specific data / vault)

OPEN SOURCE

NostrKey is fully open source under the MIT license. Audit the code yourself at github.com/HumanjavaEnterprises.

Your keys. Your control. No data collection. No tracking.
```

### Category
**Utilities**

### Secondary Category
**Social Networking**

### Content Rights
**Does not contain third-party content that requires rights.**

### Age Rating
**4+** (no objectionable content)

## Privacy Details (App Store Connect)

### Data Collection
**We do NOT collect any user data.**

Select: **Data Not Collected**

### Privacy Policy URL
**https://nostrkey.com/privacy.html**

### Privacy Nutrition Label
| Data Type | Collected | Linked to Identity | Tracking |
|-----------|-----------|-------------------|----------|
| All types | No | No | No |

## Required Assets

### App Icon
- 1024x1024px PNG (rendered from NostrKey-logo.svg)
- Located: `NostrKey/Assets.xcassets/AppIcon.appiconset/icon-1024.png`

### Screenshots

#### iPhone 6.9" (required — iPhone 17 Pro Max)
- Resolution: 1320x2868
- Located: `screenshots/`
- Screens to capture:
  1. Lock screen — active profile with npub and "Show QR Code" button
  2. Lock screen QR — bottom sheet with npub QR code
  3. Home — profile list with QR code
  4. Vault — encrypted document list
  5. Settings — security & relay config with toggle switches
  6. QR Scanner — camera view (device only)

#### iPhone 6.7" (optional — covers iPhone 15 Pro Max, 14 Pro Max)
- Resolution: 1290x2796
- Can reuse 6.9" screenshots (App Store Connect auto-scales)

## App Review Information

### Demo Account
Not applicable — NostrKey generates keys locally. No account or login needed.

### Review Notes
```
NostrKey for iOS is a standalone Nostr key management app. It runs the NostrKey browser extension UI natively in WKWebViews with a native Swift bridge for platform integration.

Key functionality:
1. Generate or import Nostr private keys (nsec/hex format)
2. View public key (npub) with QR code for sharing
3. Sign Nostr events (NIP-01)
4. Encrypt/decrypt messages (NIP-44 ChaCha20-Poly1305)
5. Connect to remote signers (NIP-46 nsecBunker)
6. Store encrypted documents in a zero-knowledge vault on relays
7. Scan QR codes to import keys (nsec, npub, ncryptsec)
8. Export keys in encrypted format (NIP-49 ncryptsec)

To test:
1. Launch the app — a default profile is created automatically
2. The lock screen shows your active profile name, truncated npub, and a "Show QR Code" button
3. Tap "Show QR Code" before unlocking — a bottom sheet prompts you to unlock first
4. The "Secure Your Vault" prompt lets you set up a master password
5. After unlocking, tap "Show QR Code" — the bottom sheet displays your npub QR code
6. Tap the profile to view npub, QR code, and edit options
7. Use the Vault tab to create encrypted documents
8. Use the Relays tab to configure relay connections
9. Use Settings for security options (master password, auto-lock timeout, toggle switches)

No external account, server, or subscription is needed. All data is stored locally in the app sandbox. Network connections go only to user-configured Nostr relays.

This app does NOT inject window.nostr — it is not a browser extension. It is a standalone key manager and vault.
```

### Contact Information
- **Website:** https://nostrkey.com
- **Support URL:** https://nostrkey.com/support.html
- **Marketing URL:** https://nostrkey.com
- **GitHub:** https://github.com/HumanjavaEnterprises/nostrkey.app.ios.src

## Build & Archive

### Version
- `MARKETING_VERSION`: 1.0.4
- `CURRENT_PROJECT_VERSION`: 5
- Bundle ID: `com.nostrkey.app`

### Archive from Xcode
```bash
# 1. Generate project
cd nostrkey.app.ios.src
xcodegen generate

# 2. Open in Xcode
open NostrKey.xcodeproj

# 3. Select signing team in project settings
#    Xcode → NostrKey target → Signing & Capabilities → Team

# 4. Archive
#    Product → Archive (requires "Any iOS Device" destination)

# 5. Distribute
#    Window → Organizer → select archive → Distribute App → App Store Connect
```

### Archive from command line
```bash
# Archive
xcodebuild -project NostrKey.xcodeproj \
    -scheme NostrKey \
    -destination 'generic/platform=iOS' \
    -configuration Release \
    -archivePath build/NostrKey.xcarchive \
    archive

# Export for App Store
xcodebuild -exportArchive \
    -archivePath build/NostrKey.xcarchive \
    -exportOptionsPlist ExportOptions.plist \
    -exportPath build/AppStore
```

## Submission Checklist

- [ ] Apple Developer account active
- [ ] App Store Connect entry created for "NostrKey" (com.nostrkey.app)
- [ ] Fill out app description, subtitle, keywords
- [ ] Upload promotional text
- [ ] Set categories (Utilities + Social Networking)
- [ ] Upload screenshots (iPhone 6.9" minimum)
- [ ] Set privacy declarations (Data Not Collected)
- [ ] Add privacy policy URL
- [ ] Add support URL
- [ ] Add review notes
- [ ] Select signing team in Xcode
- [ ] Archive and upload build from Xcode
- [ ] Select build in App Store Connect
- [ ] Submit for review

## Review Timeline

- Initial review: typically 1-3 days
- This app may receive questions about:
  - Cryptographic functionality — explain NIP-44 (ChaCha20-Poly1305)
  - Key storage — explain local-only storage in app sandbox
  - Relay connections — explain NSAllowsArbitraryLoadsInWebContent (WebSocket to user-configured relays)

## Post-Submission

### If Approved
- Update README.md with App Store link and badge
- Update nostrkey.com with iOS download link
- Announce on Nostr

### If Rejected
- Review feedback in Resolution Center
- Common issues:
  - WebView-based app concerns → explain native bridge integration (QR scanner, clipboard, storage)
  - NSAllowsArbitraryLoadsInWebContent → explain Nostr relay WebSocket connections
  - Minimal functionality → demonstrate vault, key management, QR scanning, encryption

---

*Last updated: February 22, 2026*
*Published by Humanjava Enterprises Inc*
