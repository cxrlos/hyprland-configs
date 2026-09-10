#!/usr/bin/env bash
set -euo pipefail

if command -v notify-send &>/dev/null; then
    notify-send -a "GameMode" -u low "GameMode Active" "CPU governor + priority tuned for gameplay"
fi
