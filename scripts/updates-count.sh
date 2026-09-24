#!/usr/bin/env bash
# Count of available official-repo updates via checkupdates (pacman-contrib) —
# does NOT hit the AUR, so it's safe to poll on a timer. Click the module to
# actually install (via yay, which also covers AUR packages that this count
# doesn't include).
set -euo pipefail

count=$(checkupdates 2>/dev/null | wc -l | tr -d ' ')

if [[ "$count" -gt 0 ]]; then
    jq -nc --arg n "$count" '{text: "\($n) 󰚰", tooltip: "\($n) package update(s) available\nClick to open yay"}'
else
    printf '{"text": "", "tooltip": ""}\n'
fi
