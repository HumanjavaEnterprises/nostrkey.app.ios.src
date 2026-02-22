# NostrKey for iOS

> Native iOS wrapper for NostrKey — Nostr key management and encrypted vault on your phone.
>
> **Current release:** v1.0.4 · **Bundled extension:** [v1.5.0](https://github.com/HumanjavaEnterprises/nostrkey.browser.plugin.src/releases/tag/v1.5.0) · **Min iOS:** 16.0 · **License:** MIT

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
- **Native clipboard** — copy keys and npubs to the system clipboard
- **Dark theme** — Monokai color scheme with safe-area insets for notches and home indicators

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

The app uses a **dual-WKWebView** architecture: an invisible background WebView handles message routing and key operations (same as the browser extension's background page), while the visible UI WebView renders the interface. An `IOSBridge` class implementing `WKScriptMessageHandler` bridges JavaScript calls to native iOS APIs. A polyfill layer (`ios-polyfill.js`) maps Chrome extension APIs (`chrome.storage`, `chrome.runtime`) to bridge calls via `webkit.messageHandlers.nostrkey.postMessage()`.

## NIPs Supported

All NIP support is provided by the bundled extension code (v1.5.0):

| NIP | Feature | Status |
|-----|---------|--------|
| [NIP-01](https://github.com/nostr-protocol/nips/blob/master/01.md) | Basic protocol | Supported |
| [NIP-04](https://github.com/nostr-protocol/nips/blob/master/04.md) | Encrypted DMs v1 | Supported (deprecated) |
| [NIP-07](https://github.com/nostr-protocol/nips/blob/master/07.md) | Browser extension API | Supported (via polyfill) |
| [NIP-19](https://github.com/nostr-protocol/nips/blob/master/19.md) | Bech32 encoding | Supported |
| [NIP-44](https://github.com/nostr-protocol/nips/blob/master/44.md) | Encrypted messaging v2 | Supported |
| [NIP-46](https://github.com/nostr-protocol/nips/blob/master/46.md) | Nostr Connect (bunker) | Supported |
| [NIP-49](https://github.com/nostr-protocol/nips/blob/master/49.md) | Encrypted key export | Supported |
| [NIP-78](https://github.com/nostr-protocol/nips/blob/master/78.md) | App-specific data (vault) | Supported |

## Status

### Working
- [x] Full NostrKey extension UI (profiles, vault, settings, security)
- [x] All NIP support listed above (via bundled extension code)
- [x] QR code scanning for key import (AVFoundation)
- [x] Native clipboard integration
- [x] UserDefaults storage (persistent, private)
- [x] Dark theme with safe-area insets
- [x] HTTPS-only for relay connections

### Planned
- [ ] App Store listing
- [ ] Biometric unlock (Face ID / Touch ID)
- [ ] Deep link handling (`nostr:` URIs)
- [ ] Push notifications for signing requests

## Requirements

- iOS 16.0+
- Camera permission (optional, for QR scanning)

| Build property | Value |
|----------------|-------|
| Deployment target | iOS 16.0 |
| Swift | 5.9 |
| Xcode | 15.0+ |

## Install

### From TestFlight
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
│   └── Web/                      # Extension web assets (v1.5.0)
│       ├── ios-polyfill.js       # Browser API → iOS bridge adapter
│       ├── ios-mobile.css        # Mobile theming (Monokai)
│       ├── background.html       # Background page
│       ├── sidepanel.html        # Main UI
│       └── ...                   # Sub-pages, JS bundles, images
└── screenshots/
```

## Privacy

This app does not collect any user data or transmit any data over a network connection except to Nostr relays you explicitly configure. All private key data is stored locally in UserDefaults and never leaves the device. Camera access is only used for QR code scanning and is not required.

## NostrKey Ecosystem

| Platform | Repo | Description |
|----------|------|-------------|
| **Browser** | [nostrkey.browser.plugin.src](https://github.com/HumanjavaEnterprises/nostrkey.browser.plugin.src) | Chrome + Safari extension (the source of all UI/JS) |
| **Android** | [nostrkey.app.android.src](https://github.com/HumanjavaEnterprises/nostrkey.app.android.src) | Native Android app (dual-WebView + AndroidBridge) |
| **iOS** | [nostrkey.app.ios.src](https://github.com/HumanjavaEnterprises/nostrkey.app.ios.src) | Native iOS app (dual-WKWebView + IOSBridge) — this repo |

Both mobile apps bundle the browser extension's HTML/JS/CSS assets and run them inside WebViews. A platform-specific polyfill layer translates Chrome extension APIs (`chrome.storage.local`, `chrome.runtime.sendMessage`) into native equivalents. The apps are independent of the Safari extension companion app found in `nostrkey.browser.plugin.src/apple/`.

Key differences from the browser extension:
- Storage uses iOS UserDefaults instead of `chrome.storage`
- QR code scanning via AVFoundation (not available in browser)
- No `window.nostr` injection (not a browser extension context)
- No cross-device sync (no iCloud storage.sync equivalent yet)

## License

MIT — see [LICENSE](LICENSE)
