# NostrKey for iOS

> Native iOS app for NostrKey — Nostr key management and encrypted vault on your phone.
>
> **Current release:** [v1.1.1](https://github.com/HumanjavaEnterprises/nostrkey.app.ios.src/releases/tag/v1.1.1) · **Bundled extension:** [v1.5.4](https://github.com/HumanjavaEnterprises/nostrkey.browser.plugin.src/releases/tag/v1.5.4) · **Min iOS:** 16.0 · **License:** MIT

> **NostrKey and Humanjava Enterprises Inc. do not have a cryptocurrency, token, or coin. Nor will there be one.** If anyone suggests or sells a cryptocurrency associated with this project, they are acting fraudulently. [Report scams](https://github.com/HumanjavaEnterprises/nostrkey.app.ios.src/issues).

## What It Does

This app runs the full [NostrKey browser extension](https://github.com/HumanjavaEnterprises/nostrkey.browser.plugin.src) UI natively on iOS, with native platform integrations:

- **NIP-07 key management** — create, import, and manage multiple Nostr profiles
- **NIP-44 / NIP-04 encryption** — modern ChaCha20-Poly1305 and legacy DM support
- **NIP-46 nsecBunker** — remote signing, your private key never touches a browser
- **NIP-49 encrypted export** — ncryptsec key backup and restore
- **Encrypted .md vault** — zero-knowledge documents stored on relays (NIP-78)
- **API key vault** — encrypted secret storage with relay sync
- **Master password** — keys encrypted at rest with configurable auto-lock
- **QR code scanner** — scan npub/nsec/ncryptsec keys directly with the camera (AVFoundation)
- **Lock screen QR code** — share your npub QR code without unlocking the app (bottom sheet)
- **Lock screen npub display** — active profile's truncated npub shown on the lock screen with copy button
- **App Groups** — profile sharing between iOS app and Safari extension (planned)
- **Dark theme** — Monokai color scheme with safe-area insets for notches and home indicators

## Get NostrKey

| Platform | Install |
|----------|---------|
| **iOS** | App Store — submission in progress |
| **Chrome / Brave / Edge** | [Chrome Web Store](https://chromewebstore.google.com/detail/nostrkey/cggakcmbihnpmcddkkfmoglgaocnmaop) |
| **Android** | [Google Play](https://play.google.com/store/apps/details?id=com.nostrkey.app) |

## Architecture

```
┌─────────────────────────────────────────────┐
│           MainViewController                │
│                                             │
│  ┌─────────────────┐  ┌──────────────────┐  │
│  │ backgroundWebView│  │   uiWebView      │  │
│  │ (background.html)│  │ (sidepanel.html) │  │
│  │                  │  │                  │  │
│  │  Message routing │  │  User interface  │  │
│  │  Key operations  │  │  Profile mgmt    │  │
│  │  Relay comms     │  │  Vault access    │  │
│  └────────┬─────────┘  └────────┬─────────┘  │
│           │     IOSBridge       │            │
│           └──────────┬──────────┘            │
│                      │                       │
│  ┌───────────────────▼───────────────────┐  │
│  │           IOSBridge.swift             │  │
│  │  • storageGet/Set/Remove/Clear        │  │
│  │  • sendMessage / sendResponse         │  │
│  │  • copyToClipboard                    │  │
│  │  • scanQR                             │  │
│  │  • navigateTo                         │  │
│  └───────────────────┬───────────────────┘  │
│                      │                       │
│            UserDefaults (JSON)               │
└─────────────────────────────────────────────┘
```

**Dual-WKWebView architecture:** an invisible background WebView handles message routing and key operations (same as the browser extension's background page), while the visible UI WebView renders the interface. `IOSBridge.swift` (implementing `WKScriptMessageHandler`) bridges JavaScript to native iOS APIs via `webkit.messageHandlers.nostrkey.postMessage()`. A polyfill layer (`ios-polyfill.js`) maps Chrome extension APIs (`chrome.storage`, `chrome.runtime`) to bridge calls.

## The Humanjava Ecosystem

NostrKey is the key management layer for the full product stack.

```
npub.bio ($7/year)           Sovereign identity (NIP-05, Lightning, bunker)
    │                        Uses NostrKey for NIP-07 connect
    ▼
NostrKeep ($5-7/month)       Private relay + Blossom media server
    │                        NostrKey points your keys at your relay
    ▼
NostrKey (free)              ◀── You are here (iOS app)
    │                        Key management, signing, vault
    ▼
Lx7 / Vaiku                 LLM.being infrastructure
```

| Product | What it does | URL |
|---------|-------------|-----|
| **NostrKey** | Key management — browser extension + mobile apps | [nostrkey.com](https://nostrkey.com) |
| **npub.bio** | Sovereign Nostr identity — NIP-05, Lightning address, profile pages | [npub.bio](https://npub.bio) |
| **NostrKeep** | Private Nostr relay + Blossom media server (subscription) | [nostrkeep.com](https://nostrkeep.com) |

## NIPs Supported

All NIP support is provided by the bundled extension code (v1.5.4):

| NIP | Feature | Status |
|-----|---------|--------|
| [NIP-01](https://github.com/nostr-protocol/nips/blob/master/01.md) | Basic protocol | Done |
| [NIP-04](https://github.com/nostr-protocol/nips/blob/master/04.md) | Encrypted DMs v1 | Done (deprecated) |
| [NIP-07](https://github.com/nostr-protocol/nips/blob/master/07.md) | Browser extension API | Done (via polyfill) |
| [NIP-19](https://github.com/nostr-protocol/nips/blob/master/19.md) | Bech32 encoding | Done |
| [NIP-44](https://github.com/nostr-protocol/nips/blob/master/44.md) | Encrypted messaging v2 | Done |
| [NIP-46](https://github.com/nostr-protocol/nips/blob/master/46.md) | Nostr Connect (bunker) | Done |
| [NIP-49](https://github.com/nostr-protocol/nips/blob/master/49.md) | Encrypted key export | Done |
| [NIP-78](https://github.com/nostr-protocol/nips/blob/master/78.md) | App-specific data (vault) | Done |

## Feature Status

### Shipped
- Full NostrKey extension UI (profiles, vault, settings, security, key management)
- All NIP support listed above (via bundled extension code v1.5.4)
- QR code scanning for key import (AVFoundation)
- Lock screen QR code sharing (bottom sheet with on-demand generation)
- Lock screen npub display with copy-to-clipboard
- Native clipboard integration
- UserDefaults storage (persistent, private)
- Dark theme with safe-area insets
- Material-style toggle switches in Settings
- HTTPS-only for relay connections

### Planned
- App Store listing (submission in progress)
- App Groups cross-app signing (iOS app ↔ Safari extension)
- Biometric unlock (Face ID / Touch ID)
- Deep link handling (`nostr:` URIs)
- Push notifications for signing requests

## Requirements

- iOS 16.0+
- Camera permission (optional, for QR scanning)

| Build property | Value |
|----------------|-------|
| Deployment target | iOS 16.0 |
| Swift | 5.9 |
| Xcode | 15.0+ |

## Install

### App Store
Coming soon — submission in progress.

### From Source (Sideload)
1. Clone this repo
2. Generate Xcode project: `xcodegen generate`
3. Open `NostrKey.xcodeproj` in Xcode
4. Select your team for code signing
5. Build and run on your device

## Development Setup

### Prerequisites
- Xcode 15.0+
- [xcodegen](https://github.com/yonaskolb/XcodeGen): `brew install xcodegen`

### Build

```bash
# Generate Xcode project from project.yml
xcodegen generate

# Build for simulator
xcodebuild -project NostrKey.xcodeproj -scheme NostrKey \
    -destination 'platform=iOS Simulator,name=iPhone 17 Pro,OS=latest' \
    -configuration Debug build

# Or open in Xcode
open NostrKey.xcodeproj
```

### Debugging WebViews

In debug builds, WebView inspection is enabled. Connect Safari on macOS:
1. Open Safari → Develop menu → [Your Device/Simulator]
2. Select the WebView to inspect (background or UI)

### Project Structure

```
nostrkey.app.ios.src/
├── project.yml                   # xcodegen spec → generates .xcodeproj
├── NostrKey/
│   ├── Info.plist
│   ├── App/
│   │   ├── AppDelegate.swift     # UIKit entry point
│   │   └── SceneDelegate.swift   # Window setup
│   ├── Controllers/
│   │   ├── MainViewController.swift      # Dual WKWebView container
│   │   └── QRScannerViewController.swift # AVFoundation QR scanner
│   ├── Bridge/
│   │   └── IOSBridge.swift       # WKScriptMessageHandler bridge
│   ├── Assets.xcassets/          # App icon + accent color
│   └── Web/                      # Extension web assets (v1.5.4)
│       ├── ios-polyfill.js       # Browser API → iOS bridge adapter
│       ├── ios-mobile.css        # Mobile theming (Monokai)
│       ├── qrcode.min.js         # Standalone QR code generator
│       ├── background.html       # Background page
│       ├── sidepanel.html        # Main UI (lock screen, QR bottom sheet)
│       └── ...                   # Sub-pages, JS bundles, images
```

## Related Repositories

| Repo | What | Status |
|------|------|--------|
| [nostrkey.browser.plugin.src](https://github.com/HumanjavaEnterprises/nostrkey.browser.plugin.src) | Browser extension (Chrome + Safari) | v1.5.5 |
| [nostrkey.app.android.src](https://github.com/HumanjavaEnterprises/nostrkey.app.android.src) | Android app (WebView wrapper) | v1.1.1 |
| [nostrkey.app.ios.src](https://github.com/HumanjavaEnterprises/nostrkey.app.ios.src) | iOS app (this repo) | v1.1.1 |

### Key Differences from Browser Extension
- Storage uses iOS UserDefaults instead of `chrome.storage`
- QR code scanning via AVFoundation (not available in browser)
- No `window.nostr` injection (not a browser extension context)
- No cross-device sync (no iCloud storage.sync equivalent yet)

### Profile Sharing: iOS vs Android
- **iOS:** App Groups allow the iOS app and Safari extension to share a storage container automatically — profiles created in the app appear in the Safari extension with no user action required (planned)
- **Android:** No equivalent of App Groups — the Android app provides a "Share to Browser" button that encrypts the private key as ncryptsec (NIP-49) for manual import

## Privacy

This app does not collect any user data or transmit any data over a network connection except to Nostr relays you explicitly configure. All private key data is stored locally in UserDefaults and never leaves the device. Camera access is only used for QR code scanning and is not required.

## License

MIT — see [LICENSE](LICENSE)

A product by [Humanjava Enterprises Inc](https://humanjava.com) · British Columbia, Canada
