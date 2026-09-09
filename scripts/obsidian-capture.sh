#!/usr/bin/env bash
# Obsidian quick-capture — prompt for a title in rofi, create the note in the
# default (last-used) vault via the core obsidian:// URI, ready to type.
# Empty title falls back to a timestamp. No community plugin required.
set -euo pipefail

ROFI_THEME="$HOME/.config/rofi/rose-pine.rasi"

title=$(printf '' | rofi -dmenu -p "  Capture" -theme "$ROFI_THEME" -lines 0 -width 30) || exit 0
[ -n "$title" ] || title="$(date +'%Y-%m-%d %H-%M')"

name=$(printf '%s' "$title" | sed 's/ /%20/g')
xdg-open "obsidian://new?name=$name" >/dev/null 2>&1
