#!/usr/bin/env bash
set -euo pipefail

ROFI_THEME="$HOME/.config/rofi/rose-pine.rasi"

choice=$(printf "  Lock\n  Suspend\n  Reboot\n  Shutdown" \
    | rofi -dmenu -p " " -theme "$ROFI_THEME" -lines 4 -width 20)

case "$choice" in
    *Lock)     hyprlock ;;
    *Suspend)  systemctl suspend ;;
    *Reboot)   systemctl reboot ;;
    *Shutdown) systemctl poweroff ;;
esac
