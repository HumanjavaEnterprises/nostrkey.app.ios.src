# Screenshots

App Store submission screenshots captured by `capture-screenshots.sh`.

## Screenshot Slots

| File | Screen |
|------|--------|
| `01-lock-screen.png` | Lock screen — profile card, npub, toggle, Show QR |
| `02-lock-screen-qr.png` | QR bottom sheet (or "Unlock to enable" prompt) |
| `03-home.png` | Home tab — profile list with QR code |
| `04-vault.png` | Vault tab — encrypted documents |
| `05-relays.png` | Relays tab — relay configuration |
| `06-settings.png` | Settings tab — security, sync, advanced |

## Directories

- `current/` — Latest capture (6 PNGs)
- `previous/` — Auto-rotated one version back
- `review/` — Resized to max 2000px height (for conversation review)
- `appstore/` — Exact App Store dimensions:
  - `phone-6.9/` — 1320x2868 (iPhone 17 Pro Max)
  - `phone-6.7/` — 1290x2796 (iPhone 15 Pro Max)
  - `phone-6.7b/` — 1284x2778 (iPhone 14 Pro Max)
  - `phone-6.5/` — 1242x2688 (iPhone Xs Max etc)
  - `tablet-12.9/` — 2048x2732 (iPad Pro 12.9")

Run `./resize-screenshots.sh` to regenerate `review/` and `appstore/` from `current/`.
The script rotates `current/` → `previous/` before each full capture run.
Use `--no-rotate` to skip rotation.
