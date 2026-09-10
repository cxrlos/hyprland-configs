#!/usr/bin/env bash
set -euo pipefail

selected=$(cliphist list | rofi -dmenu \
    -p "  Clipboard" \
    -theme ~/.config/rofi/rose-pine.rasi \
    -no-custom) || exit 0

[[ -n "$selected" ]] && printf '%s' "$selected" | cliphist decode | wl-copy
