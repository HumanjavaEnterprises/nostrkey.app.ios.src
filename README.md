# NostrKey for iOS

> Native iOS wrapper for NostrKey — Nostr key management and encrypted vault on your phone.
>
> **Current release:** v1.0.4 · **Min iOS:** 16.0 · **License:** MIT

> **NostrKey and Humanjava Enterprises Inc. do not have a cryptocurrency, token, or coin. Nor will there be one.** If anyone suggests or sells a cryptocurrency associated with this project, they are acting fraudulently. [Report scams](https://github.com/HumanjavaEnterprises/nostrkey.app.ios.src/issues).

## What It Does

- **WKWebView wrapper** — runs the full NostrKey extension UI natively on iOS
- **QR code scanner** — scan npub/nsec/ncryptsec keys directly into the app (AVFoundation)
- **Native clipboard** — copy keys and npubs to the system clipboard
- **Local storage** — keys and settings stored in UserDefaults (never leaves the device)
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

## Status

### Working
- [x] Full NostrKey extension UI (profiles, vault, settings, security)
- [x] NIP-07, NIP-04, NIP-19, NIP-44, NIP-46, NIP-49 support (via extension code)
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
    -destination 'platform=iOS Simulator,name=iPhone 16,OS=latest' \
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
│   └── Web/                      # Extension web assets
│       ├── ios-polyfill.js       # Browser API → iOS bridge adapter
│       ├── ios-mobile.css        # Mobile theming (Monokai)
│       ├── background.html       # Background page
│       ├── sidepanel.html        # Main UI
│       └── ...                   # Sub-pages, JS bundles, images
└── screenshots/
```

## Privacy

This app does not collect any user data or transmit any data over a network connection except to Nostr relays you explicitly configure. All private key data is stored locally in UserDefaults and never leaves the device. Camera access is only used for QR code scanning and is not required.

## Relationship to Browser Extension

This iOS app wraps the same web UI as the [NostrKey browser extension](https://github.com/HumanjavaEnterprises/nostrkey.browser.plugin.src). The extension's HTML/JS/CSS assets are bundled into the app and run inside WKWebViews. The `IOSBridge` + polyfill layer translates Chrome extension APIs (`chrome.storage.local`, `chrome.runtime.sendMessage`) into native iOS equivalents.

This is **not** the Safari extension companion app (found in `nostrkey.browser.plugin.src/apple/`). This is a standalone iOS app that runs the full NostrKey UI independently.

Key differences from the browser extension:
- Storage uses iOS UserDefaults instead of `chrome.storage`
- QR code scanning via AVFoundation (not available in browser)
- No `window.nostr` injection (not a browser extension context)
- No cross-device sync (no iCloud storage.sync equivalent yet)

## License

MIT — see [LICENSE](LICENSE)
