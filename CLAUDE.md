# CLAUDE.md — nostrkey.app.ios.src

## What This Is
NostrKey iOS app — native wrapper that runs the full NostrKey browser extension UI on iOS with native platform integrations (QR scanner, clipboard, lock screen npub display).

## Ecosystem Position
Mobile surface for NostrKey — the key management layer. Same role as the browser extension but on iOS. Uses dual-WKWebView architecture with IOSBridge.swift bridging JS to native APIs.

## Current Version
v1.1.1 — Bundled extension v1.5.4 — App Store submission in progress

## Tech Stack
- Swift 5.9, Xcode 15.0+
- Dual-WKWebView (background + UI)
- IOSBridge.swift (`WKScriptMessageHandler`)
- ios-polyfill.js maps `chrome.storage`/`chrome.runtime` to bridge calls
- UserDefaults for storage
- AVFoundation for QR scanning
- xcodegen for project generation

## Build
```bash
xcodegen generate
open NostrKey.xcodeproj
# Build & Run in Xcode
```

## Key Differences from Browser Extension
- Storage: UserDefaults (not `chrome.storage`)
- QR scanning: AVFoundation (native)
- No `window.nostr` injection
- No cross-device sync yet
- Lock screen QR code + npub display (iOS-only features)

## Planned
- App Store listing
- App Groups (share profiles between iOS app ↔ Safari extension)
- Biometric unlock (Face ID / Touch ID)
- Deep links (`nostr:` URIs)

## Related Repos
- `nostrkey.browser.plugin.src` — core extension code (bundled here as web assets)
- `nostrkey.app.android.src` — Android equivalent
- `nostrkey.bizdocs.src` — business strategy
