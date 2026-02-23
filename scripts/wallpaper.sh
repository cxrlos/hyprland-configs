#!/usr/bin/env bash
set -euo pipefail

REPO="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")/.." && pwd)"
CONF="$REPO/hyprpaper/hyprpaper.conf"

if [[ $# -eq 0 ]]; then
    grep -oP 'wallpaper = [^,]+,\K.+' "$CONF" | head -1
    exit 0
fi

img="$(realpath "$1")"
[[ -f "$img" ]] || { printf 'file not found: %s\n' "$img" >&2; exit 1; }

monitors=$(hyprctl monitors -j 2>/dev/null | grep -oP '"name":\s*"\K[^"]+' || true)

{
    printf 'preload = %s\n' "$img"
    if [[ -n "$monitors" ]]; then
        while IFS= read -r mon; do
            printf 'wallpaper = %s,%s\n' "$mon" "$img"
        done <<< "$monitors"
    else
        printf 'wallpaper = ,%s\n' "$img"
    fi
    printf 'ipc = off\nsplash = false\n'
} > "$CONF"

killall hyprpaper 2>/dev/null || true
sleep 0.3
hyprpaper &
printf 'wallpaper → %s\n' "$img"
