#!/usr/bin/env bash
set -euo pipefail

ROFI_THEME="$HOME/.config/rofi/gruvbox.rasi"

choice=$(printf "  Lock\n  Suspend\n  Reboot\n  Shutdown" \
    | rofi -dmenu -p " " -theme "$ROFI_THEME" -theme-str 'window { width: 240px; } listview { lines: 4; }')

case "$choice" in
    *Lock)     hyprlock ;;
    *Suspend)  sleep 1 && systemctl suspend ;;  # let the Enter release land before sleep
    *Reboot)   systemctl reboot ;;
    *Shutdown) systemctl poweroff ;;
esac
