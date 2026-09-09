#!/usr/bin/env bash
# Launch Steam with SDL_VIDEODRIVER=x11 so games use XWayland and detect
# the correct display resolution (e.g. 2560x1080). With SDL_VIDEODRIVER=wayland
# (set globally in Hyprland), many games see a scaled/wrong resolution.
export SDL_VIDEODRIVER=x11
export SDL_HAPTIC_DISABLED=1
export DXVK_FRAME_RATE=60
exec /usr/bin/steam "$@"
