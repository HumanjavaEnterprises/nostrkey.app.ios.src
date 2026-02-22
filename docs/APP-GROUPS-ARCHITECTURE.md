# App Groups Architecture — NostrKey iOS

**How the iOS app and Safari extension share data securely**

---

## Overview

The NostrKey iOS app (`com.nostrkey.app`) and the NostrKey Safari extension (`com.nostrkey.Extension`) share profile data through an **Apple App Group** — a shared container that both apps can read and write without any network activity.

This is the core of **Level 1** in the [Progressive Trust Ladder](../../nostrkey.bizdocs.src/Progressive-Trust-Ladder.md).

---

## App Group Configuration

```
App Group ID:  group.com.nostrkey

Members:
  ├── com.nostrkey.app           (standalone iOS app)
  ├── com.nostrkey               (Safari extension container app)
  └── com.nostrkey.Extension     (Safari web extension)
```

### What lives where

```
┌─────────────────────────────────────────────────────┐
│                  App Group Container                │
│              group.com.nostrkey                      │
│                                                     │
│  ┌───────────────────────────────────────────────┐  │
│  │  Shared UserDefaults                          │  │
│  │  (profile metadata — public data)             │  │
│  │                                               │  │
│  │  nostrkey_profiles: [                         │  │
│  │    {                                          │  │
│  │      id: "uuid",                              │  │
│  │      name: "My Profile",                      │  │
│  │      npub: "npub1abc...",                     │  │
│  │      active: true,                            │  │
│  │      backedUp: true,                          │  │
│  │      lastSyncedAt: "2026-02-22T..."           │  │
│  │    }                                          │  │
│  │  ]                                            │  │
│  │                                               │  │
│  │  nostrkey_settings: {                         │  │
│  │    autoLockTimeout: 15,                       │  │
│  │    relays: ["wss://relay.damus.io", ...]      │  │
│  │  }                                            │  │
│  └───────────────────────────────────────────────┘  │
│                                                     │
│  ┌───────────────────────────────────────────────┐  │
│  │  Shared Keychain                              │  │
│  │  (secrets — encrypted, Secure Enclave ready)  │  │
│  │                                               │  │
│  │  kSecAttrAccessGroup: "H48PW6TC25.group..."   │  │
│  │                                               │  │
│  │  Keys stored:                                 │  │
│  │    nostrkey.nsec.<profile-id>  → encrypted    │  │
│  │    nostrkey.master-password    → hash          │  │
│  └───────────────────────────────────────────────┘  │
│                                                     │
└─────────────────────────────────────────────────────┘
         │                              │
         ▼                              ▼
┌─────────────────┐          ┌─────────────────────┐
│  NostrKey App   │          │  Safari Extension    │
│  (com.nostrkey  │          │  (com.nostrkey       │
│   .app)         │          │   .Extension)        │
│                 │          │                      │
│  Reads/writes   │          │  Reads/writes        │
│  shared data    │          │  shared data         │
│                 │          │                      │
│  Also has:      │          │  Also has:           │
│  Private        │          │  Private             │
│  UserDefaults   │          │  chrome.storage      │
│  (app-only)     │          │  (extension-only)    │
└─────────────────┘          └─────────────────────┘
```

---

## Sync Flow

### App → Extension (primary direction)

```
User installs app          App writes to             Extension reads
and creates/imports   ───▶ shared App Group     ───▶ on next launch
a profile                  container                  or activation

  ┌──────────┐            ┌──────────────┐          ┌──────────────┐
  │  App:    │            │  App Group:  │          │  Extension:  │
  │  "Save   │───write──▶│  profiles[]  │──read──▶│  "Profile    │
  │  profile"│            │  keychain[]  │          │   available" │
  └──────────┘            └──────────────┘          └──────────────┘
```

### Extension → App (reverse sync)

```
  Extension creates        Writes to                App detects
  a new profile in    ───▶ shared container    ───▶ new profile
  the browser                                       on next open

  (Same shared storage, bidirectional)
```

### Conflict Resolution

- **Last-write wins** with timestamp (`lastSyncedAt`)
- Each profile has a UUID — no ID collisions
- Keychain items are keyed by profile UUID
- If both sides edit the same profile, most recent timestamp wins
- Master password: if set on either side, synced to both

---

## Implementation Plan

### Step 1: Add App Group capability

**In Xcode (both projects):**

1. NostrKey iOS app → Signing & Capabilities → + App Groups → `group.com.nostrkey`
2. NostrKey Safari extension → same → `group.com.nostrkey`

**In project.yml (iOS app):**
```yaml
settings:
  base:
    CODE_SIGN_ENTITLEMENTS: NostrKey/NostrKey.entitlements
```

**NostrKey.entitlements:**
```xml
<key>com.apple.security.application-groups</key>
<array>
    <string>group.com.nostrkey</string>
</array>
<key>keychain-access-groups</key>
<array>
    <string>$(AppIdentifierPrefix)group.com.nostrkey</string>
</array>
```

### Step 2: SharedStorage.swift (new file)

```
NostrKey/
├── Storage/
│   ├── SharedStorage.swift       ← reads/writes App Group UserDefaults
│   └── SharedKeychain.swift      ← reads/writes App Group Keychain
```

Key APIs:
```swift
class SharedStorage {
    static let shared = SharedStorage()
    private let defaults = UserDefaults(suiteName: "group.com.nostrkey")!

    func saveProfiles(_ profiles: [Profile]) { ... }
    func loadProfiles() -> [Profile] { ... }
    func saveSettings(_ settings: Settings) { ... }
    func loadSettings() -> Settings { ... }
}

class SharedKeychain {
    static let shared = SharedKeychain()
    private let accessGroup = "H48PW6TC25.group.com.nostrkey"

    func saveNsec(profileId: String, nsec: String) { ... }
    func loadNsec(profileId: String) -> String? { ... }
    func deletNsec(profileId: String) { ... }
}
```

### Step 3: Update IOSBridge.swift

Add storage write-through:
- When `storageSet` is called from JS → also write to SharedStorage
- When app launches → merge SharedStorage profiles into local storage
- Conflict resolution by `lastSyncedAt` timestamp

### Step 4: Lock Screen UI

Modify `sidepanel.html` lock screen behavior (in ios-polyfill.js):
- Detect locked state
- Show active profile: name, npub, QR code
- "Copy npub" button (works while locked)
- "Launch in Browser" button → calls `IOSBridge.launchInBrowser()`

### Step 5: "Launch in Browser" (IOSBridge)

```swift
func launchInBrowser() {
    // 1. Ensure profile is written to SharedStorage
    SharedStorage.shared.saveProfiles(currentProfiles)

    // 2. Open Safari
    // Extension will read from shared container on activation
    UIApplication.shared.open(URL(string: "https://snort.social")!)
    // Or open a custom page that explains "Extension is ready"
}
```

### Step 6: Extension reads shared storage

In the Safari extension's background.js:
```javascript
// On activation, check App Group storage for synced profiles
browser.storage.local.get('profiles').then(local => {
    const shared = readFromAppGroup(); // native bridge
    if (shared.lastSyncedAt > local.lastSyncedAt) {
        // App has newer data — merge
        browser.storage.local.set({ profiles: shared.profiles });
    }
});
```

---

## Security Model

| Data | Storage | Encryption | Access |
|------|---------|-----------|--------|
| npub, profile name | Shared UserDefaults | None (public data) | Both apps |
| nsec (private key) | Shared Keychain | AES-256-GCM (Keychain) | Both apps, biometric optional |
| Master password hash | Shared Keychain | bcrypt/scrypt hash | Both apps |
| Vault documents | Private UserDefaults | NIP-44 (app-encrypted) | App only (until synced) |
| Relay config | Shared UserDefaults | None (not secret) | Both apps |

**Key principle:** The nsec never exists in plaintext outside Keychain. The Keychain encrypts at rest and can optionally require Face ID / Touch ID to access.

---

## Files to Create / Modify

| File | Action | Purpose |
|------|--------|---------|
| `NostrKey/NostrKey.entitlements` | Create | App Group + Keychain sharing |
| `NostrKey/Storage/SharedStorage.swift` | Create | App Group UserDefaults wrapper |
| `NostrKey/Storage/SharedKeychain.swift` | Create | Keychain with shared access group |
| `NostrKey/Bridge/IOSBridge.swift` | Modify | Add write-through to SharedStorage |
| `NostrKey/Controllers/MainViewController.swift` | Modify | Add launchInBrowser action |
| `NostrKey/Web/ios-polyfill.js` | Modify | Lock screen profile display |
| `project.yml` | Modify | Add entitlements reference |

---

## References

- [Progressive Trust Ladder](../../nostrkey.bizdocs.src/Progressive-Trust-Ladder.md) — The product vision this serves
- [Apple: App Groups](https://developer.apple.com/documentation/bundleresources/entitlements/com_apple_security_application-groups)
- [Apple: Sharing Keychain Items](https://developer.apple.com/documentation/security/keychain_services/keychain_items/sharing_access_to_keychain_items_among_a_collection_of_apps)

---

*This architecture enables "one tap sync" between the NostrKey app and Safari extension — no relays, no cloud, no configuration. The user taps a button and their identity is everywhere.*

---

*Humanjava Enterprises Inc. — February 2026*
