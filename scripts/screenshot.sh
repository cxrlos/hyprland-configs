#!/usr/bin/env bash
# Capture an area or the whole screen, copy it straight away, and offer Save / Edit /
# Open from the notification (macOS-style). Unsaved captures are deleted once it closes.
set -euo pipefail

readonly SAVE_DIR="$HOME/Pictures/screenshots"

mode="${1:-area}"
case "$mode" in
    area | screen) ;;
    *)
        printf 'Usage: screenshot [area|screen]\n' >&2
        exit 2
        ;;
esac

tmp="$(mktemp --suffix=.png "${XDG_RUNTIME_DIR:-/tmp}/screenshot-XXXXX")"
trap 'rm -f "$tmp"' EXIT

if command -v grimblast &>/dev/null; then
    grimblast save "$mode" "$tmp" >/dev/null || exit 0
elif [[ $mode == area ]]; then
    grim -g "$(slurp)" "$tmp" || exit 0
else
    grim "$tmp"
fi

wl-copy <"$tmp"

# notify-send blocks until the notification closes and prints the chosen action.
action=$(notify-send -a Screenshot -i camera-photo -h "string:image-path:$tmp" \
    -A save=Save -A edit=Edit -A open=Open \
    "Screenshot copied" "Save it to Pictures, mark it up, or open it") || true

case "$action" in
    edit)
        # satty saves into Pictures and copies the marked-up version on Ctrl+S / Ctrl+C.
        mkdir -p "$SAVE_DIR"
        satty --filename "$tmp" --output-filename "$SAVE_DIR/%Y-%m-%d_%H-%M-%S.png" \
            --copy-command wl-copy --early-exit all
        ;;
    save | open)
        mkdir -p "$SAVE_DIR"
        final="$SAVE_DIR/$(date +'%Y-%m-%d_%H-%M-%S').png"
        cp "$tmp" "$final"
        if [[ $action == open ]]; then
            xdg-open "$final" >/dev/null 2>&1 &
        fi
        ;;
esac
