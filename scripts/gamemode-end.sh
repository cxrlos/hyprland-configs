#!/usr/bin/env bash
set -euo pipefail

# Restore compositor blur upon game exit
hyprctl keyword decoration:blur:enabled 1

if command -v notify-send &>/dev/null; then
    notify-send -a "GameMode" -u low "GameMode Deactivated" "Compositor blur restored"
fi
