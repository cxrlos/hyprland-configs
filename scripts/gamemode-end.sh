#!/usr/bin/env bash
set -euo pipefail

if command -v notify-send &>/dev/null; then
    notify-send -a "GameMode" -u low "GameMode Deactivated" "Back to normal"
fi
