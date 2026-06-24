#!/usr/bin/env bash
# hyprpaper 0.8.4 ignores its config-file preload/wallpaper directives and rejects the
# `preload` IPC verb, but the `wallpaper` verb still works and auto-loads. So we drive
# hyprpaper over IPC instead of a hyprpaper.conf. The chosen wallpaper lives in waypaper's
# config (its GUI writes it there); this runs both as the login restore and as waypaper's
# post_command, so a GUI pick applies live.
set -euo pipefail

waypaper_cfg="$HOME/.config/waypaper/config.ini"
[ -f "$waypaper_cfg" ] || exit 0

wallpaper=$(awk -F'[[:space:]]*=[[:space:]]*' '/^wallpaper[[:space:]]*=/{print $2; exit}' "$waypaper_cfg")
wallpaper="${wallpaper/#\~/$HOME}"

[ -n "$wallpaper" ] && [ -f "$wallpaper" ] || exit 0

pgrep -x hyprpaper >/dev/null 2>&1 || setsid -f hyprpaper >/dev/null 2>&1

for _ in $(seq 1 25); do
    hyprctl hyprpaper listactive >/dev/null 2>&1 && break
    sleep 0.2
done

hyprctl hyprpaper wallpaper ",$wallpaper" >/dev/null 2>&1
