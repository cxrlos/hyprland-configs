#!/usr/bin/env bash
set -euo pipefail

# Strip compositor blur for maximum throughput during gameplay
# (Animations are already disabled globally in Pro profile)
hyprctl keyword decoration:blur:enabled 0

if command -v notify-send &>/dev/null; then
    notify-send -a "GameMode" -u low "GameMode Active" "Compositor blur bypassed for maximum throughput"
fi
