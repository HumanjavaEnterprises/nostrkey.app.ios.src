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

The script rotates `current/` → `previous/` before each full capture run.
Use `--no-rotate` to skip rotation.
