# QA-AUTOMATION — iOS Screenshot Capture

Automated screenshot capture for App Store submission using iOS Simulator.

## Prerequisites

| Tool | Install | Purpose |
|------|---------|---------|
| Xcode | App Store | Simulator, `simctl` |
| `jq` | `brew install jq` | Parse `ui-target-map.json` |
| `swiftc` | Included with Xcode | Compile `tools/click.swift` |
| Simulator.app | Open via Xcode | Must be running with device booted |

## Quick Start

```bash
# 1. Boot simulator and launch the app
xcrun simctl boot "iPhone 17 Pro Max"
open -a Simulator

# 2. Run all 6 screenshots
./QA-AUTOMATION/capture-screenshots.sh

# 3. Check results
ls QA-AUTOMATION/screenshots/current/
```

## Usage

```bash
./QA-AUTOMATION/capture-screenshots.sh                  # All 6 screens
./QA-AUTOMATION/capture-screenshots.sh 01-lock-screen   # Just one
./QA-AUTOMATION/capture-screenshots.sh --list           # Show screen IDs
./QA-AUTOMATION/capture-screenshots.sh --calibrate      # Show simulator window position
./QA-AUTOMATION/capture-screenshots.sh --no-rotate      # Keep previous/ intact
```

## Calibration

The script clicks UI elements using macOS screen coordinates relative to the Simulator window. If you reposition the Simulator window, coordinates will be wrong.

To recalibrate:

1. Run `./QA-AUTOMATION/capture-screenshots.sh --calibrate` to see current window position
2. Update `simulator_window.position` in `ui-target-map.json`
3. Adjust tab bar and button coordinates accordingly

**Tab bar coordinates** are in macOS screen space:
- `tab_bar.y`: vertical position of the tab bar
- `tab_bar.tabs.<name>.x`: horizontal center of each tab icon

## How It Works

1. Discovers booted simulator UDID via `xcrun simctl list`
2. Overrides status bar (9:41, full battery/signal)
3. Rotates `screenshots/current/` → `screenshots/previous/`
4. Iterates through `screenshots_sequence` in `ui-target-map.json`
5. For each screen: executes pre-actions → action → wait → `simctl io screenshot`
6. Saves PNGs to `screenshots/current/`

### Click Method

`simctl` has no tap API. The `tools/click` binary uses CoreGraphics CGEvent to send mouse clicks at macOS screen coordinates into the Simulator window. First run compiles automatically:

```bash
swiftc tools/click.swift -o tools/click
```

### Text Input

`simctl keyboard` does not work with WKWebView. Use clipboard paste instead:

```bash
echo "text" | xcrun simctl pbcopy <udid>
osascript -e 'tell application "System Events" to keystroke "v" using command down'
```

## Resizing Screenshots

After capturing, resize for review and store submission:

```bash
./QA-AUTOMATION/resize-screenshots.sh              # Both review + store sizes
./QA-AUTOMATION/resize-screenshots.sh --review     # Max 2000px height only
./QA-AUTOMATION/resize-screenshots.sh --appstore   # Store sizes only
```

Output goes to `screenshots/review/` and `screenshots/appstore/` (gitignored).

Requires Python 3 with Pillow (`pip3 install Pillow`).

## Known Limitations

- Coordinates are absolute macOS screen positions — moving the Simulator window requires recalibration
- CGEvent clicking requires Accessibility permission for Terminal/IDE
- WKWebView text fields cannot receive `simctl keyboard` input
- Screenshot dimensions depend on simulator device (iPhone 17 Pro Max = 1320x2868)
