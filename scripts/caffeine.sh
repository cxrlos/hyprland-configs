#!/usr/bin/env bash
# Caffeine — toggle idle inhibition by pausing/resuming hypridle.
# One mechanism (hypridle on/off) so the waybar icon and the keybind agree.
#
#   caffeine.sh           toggle on/off (default)
#   caffeine.sh status    print waybar JSON for the custom/caffeine module
set -euo pipefail

_running() { pgrep -x hypridle >/dev/null 2>&1; }

case "${1:-toggle}" in
    status)
        if _running; then
            printf '{"text":"󰅶","tooltip":"Auto-lock active — click for caffeine","class":"inactive"}\n'
        else
            printf '{"text":"󰅶","tooltip":"Caffeine on — auto-lock paused","class":"active"}\n'
        fi
        ;;
    *)
        if _running; then
            pkill -x hypridle || true
            _state="on";  _body="Idle & lock paused"
        else
            setsid -f hypridle >/dev/null 2>&1 || true
            _state="off"; _body="Normal idle & lock"
        fi
        notify-send -i caffeine "Caffeine $_state" "$_body" 2>/dev/null || true
        pkill -RTMIN+8 waybar 2>/dev/null || true
        ;;
esac
