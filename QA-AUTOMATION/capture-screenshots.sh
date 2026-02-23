#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CONFIG="$SCRIPT_DIR/ui-target-map.json"
SCREENSHOTS_DIR="$SCRIPT_DIR/screenshots"
CURRENT_DIR="$SCREENSHOTS_DIR/current"
PREVIOUS_DIR="$SCREENSHOTS_DIR/previous"
CLICK_TOOL="$SCRIPT_DIR/tools/click"
CLICK_SOURCE="$SCRIPT_DIR/tools/click.swift"

# --- Helpers ---

die() { echo "ERROR: $*" >&2; exit 1; }

require() {
  command -v "$1" >/dev/null 2>&1 || die "$1 is required but not found. $2"
}

json_val() {
  jq -r "$1" "$CONFIG"
}

# --- Prerequisites ---

require jq "Install with: brew install jq"
[ -f "$CONFIG" ] || die "Config not found: $CONFIG"

# --- Compile click tool if needed ---

ensure_click_tool() {
  if [ ! -f "$CLICK_TOOL" ]; then
    echo "Compiling click tool..."
    swiftc "$CLICK_SOURCE" -o "$CLICK_TOOL" || die "Failed to compile click.swift"
    echo "Click tool compiled: $CLICK_TOOL"
  fi
}

# --- Discover booted simulator ---

get_udid() {
  require xcrun "Install Xcode from the App Store"
  local udid
  udid=$(xcrun simctl list devices booted -j | jq -r '.devices[][] | select(.state=="Booted") | .udid' | head -1)
  [ -n "$udid" ] && [ "$udid" != "null" ] || die "No booted simulator found. Boot one with: xcrun simctl boot \"iPhone 17 Pro Max\""
  echo "$udid"
}

# --- Status bar ---

set_status_bar() {
  local udid="$1"
  echo "Setting clean status bar..."
  xcrun simctl status_bar "$udid" override \
    --time "9:41" \
    --batteryState charged \
    --batteryLevel 100 \
    --wifiBars 3 \
    --cellularBars 4
}

clear_status_bar() {
  local udid="$1"
  xcrun simctl status_bar "$udid" clear 2>/dev/null || true
}

# --- Screenshot rotation ---

rotate_screenshots() {
  if [ -d "$CURRENT_DIR" ] && [ "$(ls -A "$CURRENT_DIR" 2>/dev/null)" ]; then
    echo "Rotating current/ → previous/..."
    rm -rf "$PREVIOUS_DIR"
    mkdir -p "$PREVIOUS_DIR"
    mv "$CURRENT_DIR"/*.png "$PREVIOUS_DIR"/ 2>/dev/null || true
  fi
  mkdir -p "$CURRENT_DIR"
}

# --- Click actions ---

do_click() {
  local x="$1" y="$2"
  ensure_click_tool
  "$CLICK_TOOL" "$x" "$y"
}

click_tab() {
  local tab_name="$1"
  local tab_x tab_y
  tab_x=$(json_val ".tab_bar.tabs.${tab_name}.x")
  tab_y=$(json_val ".tab_bar.y")
  [ "$tab_x" != "null" ] || die "Unknown tab: $tab_name"
  do_click "$tab_x" "$tab_y"
}

# --- Execute action from sequence entry ---

execute_pre_actions() {
  local udid="$1"
  local entry="$2"
  local count
  count=$(echo "$entry" | jq '.pre_actions | length')

  for ((i=0; i<count; i++)); do
    local action_type
    action_type=$(echo "$entry" | jq -r ".pre_actions[$i].type")

    case "$action_type" in
      terminate)
        local bundle_id
        bundle_id=$(echo "$entry" | jq -r ".pre_actions[$i].bundle_id")
        echo "  Terminating $bundle_id..."
        xcrun simctl terminate "$udid" "$bundle_id" 2>/dev/null || true
        sleep 1
        ;;
      launch)
        local bundle_id
        bundle_id=$(echo "$entry" | jq -r ".pre_actions[$i].bundle_id")
        echo "  Launching $bundle_id..."
        xcrun simctl launch "$udid" "$bundle_id"
        ;;
      wait)
        local seconds
        seconds=$(echo "$entry" | jq -r ".pre_actions[$i].seconds")
        echo "  Waiting ${seconds}s..."
        sleep "$seconds"
        ;;
      dismiss_sheet)
        echo "  Dismissing sheet (swipe down)..."
        # Click above the sheet area to dismiss
        local win_x win_y
        win_x=$(json_val ".simulator_window.position.x")
        win_y=$(json_val ".simulator_window.position.y")
        do_click "$((win_x + 247))" "$((win_y + 100))"
        sleep 1
        ;;
      *)
        echo "  Unknown pre_action type: $action_type (skipping)"
        ;;
    esac
  done
}

execute_action() {
  local entry="$1"
  local action_type
  action_type=$(echo "$entry" | jq -r '.action.type')

  case "$action_type" in
    click_tab)
      local tab
      tab=$(echo "$entry" | jq -r '.action.tab')
      echo "  Clicking tab: $tab"
      click_tab "$tab"
      ;;
    click_target)
      local x y
      x=$(echo "$entry" | jq -r '.action.x')
      y=$(echo "$entry" | jq -r '.action.y')
      echo "  Clicking target at ($x, $y)"
      do_click "$x" "$y"
      ;;
    none)
      ;;
    *)
      echo "  Unknown action type: $action_type (skipping)"
      ;;
  esac
}

# --- Capture a single screenshot ---

capture_one() {
  local udid="$1"
  local entry="$2"
  local id filename title

  id=$(echo "$entry" | jq -r '.id')
  filename=$(echo "$entry" | jq -r '.filename')
  title=$(echo "$entry" | jq -r '.title')

  echo "[$id] $title"

  # Pre-actions
  execute_pre_actions "$udid" "$entry"

  # Main action
  execute_action "$entry"

  # Wait for UI to settle
  local wait_after
  wait_after=$(echo "$entry" | jq -r '.wait_after')
  sleep "$wait_after"

  # Capture
  local output="$CURRENT_DIR/$filename"
  xcrun simctl io "$udid" screenshot "$output"
  echo "  Saved: $output"
}

# --- Calibrate: show simulator window position ---

calibrate() {
  echo "Simulator window calibration"
  echo "============================"
  echo ""
  echo "Current config values:"
  echo "  Window position: ($(json_val '.simulator_window.position.x'), $(json_val '.simulator_window.position.y'))"
  echo "  Window size: $(json_val '.simulator_window.size.width')x$(json_val '.simulator_window.size.height')"
  echo "  Tab bar y: $(json_val '.tab_bar.y')"
  echo ""
  echo "Tab positions:"
  for tab in home vault apps relays settings; do
    local x
    x=$(json_val ".tab_bar.tabs.${tab}.x")
    echo "  $tab: ($x, $(json_val '.tab_bar.y'))"
  done
  echo ""

  # Try to get actual window position via AppleScript
  local actual_pos
  actual_pos=$(osascript -e '
    tell application "Simulator"
      if (count of windows) > 0 then
        set w to bounds of window 1
        return (item 1 of w) & "," & (item 2 of w) & "," & (item 3 of w) & "," & (item 4 of w)
      else
        return "not running"
      end if
    end tell
  ' 2>/dev/null || echo "unavailable")

  if [ "$actual_pos" != "unavailable" ] && [ "$actual_pos" != "not running" ]; then
    echo "Actual Simulator window bounds: $actual_pos"
    echo "(format: left, top, right, bottom)"
    echo ""
    echo "If these differ from config, update simulator_window.position in ui-target-map.json"
  else
    echo "Could not detect Simulator window position."
    echo "Make sure Simulator.app is running with a device booted."
  fi
}

# --- List screens ---

list_screens() {
  echo "Available screenshot IDs:"
  echo ""
  local count
  count=$(json_val '.screenshots_sequence | length')
  for ((i=0; i<count; i++)); do
    local id title
    id=$(jq -r ".screenshots_sequence[$i].id" "$CONFIG")
    title=$(jq -r ".screenshots_sequence[$i].title" "$CONFIG")
    echo "  $id  —  $title"
  done
}

# --- Main ---

main() {
  local do_rotate=true
  local target_id=""

  # Parse arguments
  while [ $# -gt 0 ]; do
    case "$1" in
      --list)
        list_screens
        exit 0
        ;;
      --calibrate)
        calibrate
        exit 0
        ;;
      --no-rotate)
        do_rotate=false
        shift
        ;;
      --help|-h)
        echo "Usage: capture-screenshots.sh [OPTIONS] [SCREEN_ID]"
        echo ""
        echo "Options:"
        echo "  --list        Show available screen IDs"
        echo "  --calibrate   Show simulator window position for calibration"
        echo "  --no-rotate   Don't rotate current/ to previous/"
        echo "  --help        Show this help"
        echo ""
        echo "Examples:"
        echo "  capture-screenshots.sh                  # All 6 screens"
        echo "  capture-screenshots.sh 01-lock-screen   # Just one screen"
        echo "  capture-screenshots.sh --no-rotate      # Keep previous/"
        exit 0
        ;;
      -*)
        die "Unknown option: $1 (use --help for usage)"
        ;;
      *)
        target_id="$1"
        shift
        ;;
    esac
  done

  # Discover simulator
  local udid
  udid=$(get_udid)
  echo "Using simulator: $udid"

  # Set clean status bar
  set_status_bar "$udid"

  # Rotate screenshots
  if [ "$do_rotate" = true ] && [ -z "$target_id" ]; then
    rotate_screenshots
  else
    mkdir -p "$CURRENT_DIR"
  fi

  # Get sequence
  local count
  count=$(json_val '.screenshots_sequence | length')

  if [ -n "$target_id" ]; then
    # Capture single screen
    local entry
    entry=$(jq -c ".screenshots_sequence[] | select(.id == \"$target_id\")" "$CONFIG")
    [ -n "$entry" ] || die "Unknown screen ID: $target_id (use --list to see available IDs)"
    capture_one "$udid" "$entry"
  else
    # Capture all screens
    echo "Capturing $count screenshots..."
    echo ""
    for ((i=0; i<count; i++)); do
      local entry
      entry=$(jq -c ".screenshots_sequence[$i]" "$CONFIG")
      capture_one "$udid" "$entry"
      echo ""
    done
  fi

  # Clean up status bar
  clear_status_bar "$udid"

  echo "Done! Screenshots saved to: $CURRENT_DIR"
}

main "$@"
