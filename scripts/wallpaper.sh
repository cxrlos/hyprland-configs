#!/usr/bin/env bash
# hyprpaper 0.8.4 ignores its config-file preload/wallpaper directives and rejects the
# `preload` IPC verb, but the `wallpaper` verb still works and auto-loads. So we drive
# hyprpaper over IPC instead of a hyprpaper.conf. The chosen wallpaper lives in waypaper's
# config (its GUI writes it there); this runs both as the login restore and as waypaper's
# post_command, so a GUI pick applies live.
#
# It also publishes the pick for the lock screens: a stable symlink for hyprlock (which
# blurs it itself) and a pre-blurred copy for ReGreet, which can't blur and runs as the
# greeter user, so it reads from a world-readable dir that install.sh hands to us.
set -euo pipefail

readonly LOCK_LINK="${XDG_CACHE_HOME:-$HOME/.cache}/wallpaper/current"
readonly GREETER_BG=/usr/local/share/greeter/background.jpg

waypaper_cfg="$HOME/.config/waypaper/config.ini"
[ -f "$waypaper_cfg" ] || exit 0

wallpaper=$(awk -F'[[:space:]]*=[[:space:]]*' '/^wallpaper[[:space:]]*=/{print $2; exit}' "$waypaper_cfg")
wallpaper="${wallpaper/#\~/$HOME}"

[ -n "$wallpaper" ] && [ -f "$wallpaper" ] || exit 0

mkdir -p "${LOCK_LINK%/*}"
ln -sfn "$wallpaper" "$LOCK_LINK"

if [[ -w ${GREETER_BG%/*} ]] && command -v magick >/dev/null; then
    (
        magick "$wallpaper" -resize 1280x -blur 0x18 -modulate 62 -resize 200% \
            -quality 90 "$GREETER_BG.tmp" && mv "$GREETER_BG.tmp" "$GREETER_BG"
    ) &
fi

pgrep -x hyprpaper >/dev/null 2>&1 || setsid -f hyprpaper >/dev/null 2>&1

for _ in $(seq 1 25); do
    hyprctl hyprpaper listactive >/dev/null 2>&1 && break
    sleep 0.2
done

hyprctl hyprpaper wallpaper ",$wallpaper" >/dev/null 2>&1
