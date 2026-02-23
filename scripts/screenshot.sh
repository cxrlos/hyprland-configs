#!/usr/bin/env bash
set -euo pipefail

SAVE_DIR="$HOME/Pictures/screenshots"
ROFI_THEME="$HOME/.config/rofi/rose-pine.rasi"

_notify() {
    command -v notify-send &>/dev/null && notify-send "Screenshot" "$1" -i camera-photo -t 3000
}

TMP="$(mktemp /tmp/screenshot-XXXXX.png)"

_capture() {
    local mode="$1"
    if command -v grimblast &>/dev/null; then
        grimblast save "$mode" "$TMP" || { rm -f "$TMP"; exit 0; }
    else
        case "$mode" in
            area)   grim -g "$(slurp)" "$TMP"  || { rm -f "$TMP"; exit 0; } ;;
            screen) grim "$TMP"                 || { rm -f "$TMP"; exit 0; } ;;
        esac
    fi
}

case "${1:-area}" in
    area)   _capture area ;;
    screen) _capture screen ;;
    *)
        printf 'Usage: screenshot [area|screen]\n' >&2
        rm -f "$TMP"
        exit 1
        ;;
esac

choice=$(printf "  Copy\n  Save\n  Copy+Save" \
    | rofi -dmenu -p " Screenshot" -theme "$ROFI_THEME" -lines 3 -width 22)

mkdir -p "$SAVE_DIR"
TIMESTAMP="$(date +'%Y-%m-%d_%H-%M-%S')"
FINAL="$SAVE_DIR/$TIMESTAMP.png"

case "$choice" in
    *Copy+Save)
        cp "$TMP" "$FINAL"
        wl-copy < "$TMP"
        _notify "Saved and copied: $(basename "$FINAL")"
        ;;
    *Save)
        mv "$TMP" "$FINAL"
        _notify "Saved: $(basename "$FINAL")"
        ;;
    *Copy)
        wl-copy < "$TMP"
        _notify "Copied to clipboard"
        ;;
    *)
        ;;
esac

rm -f "$TMP"
