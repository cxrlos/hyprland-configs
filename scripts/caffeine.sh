#!/usr/bin/env bash
# Caffeine — idle inhibition by pausing/resuming hypridle, in three modes:
#   off     hypridle running (normal auto-lock)
#   on      hypridle stopped
#   claude  hypridle stopped while any Claude session is mid-turn, then back to off
#           (busy state comes from claude-busy.sh Claude Code hooks)
#
#   caffeine.sh           toggle off/on (default; leaves claude mode to off)
#   caffeine.sh menu      rofi mode picker with Claude session counts
#   caffeine.sh status    print waybar JSON for the custom/caffeine module
set -euo pipefail

readonly ROFI_THEME="$HOME/.config/rofi/gruvbox.rasi"
readonly WATCH_PIDFILE="${XDG_RUNTIME_DIR:-/tmp}/caffeine-claude.pid"
readonly WATCH_INTERVAL=10
readonly CLAUDE_BUSY="${0%/*}/claude-busy.sh"
readonly MENU_THEME='
    mainbox { children: [inputbar, message, listview]; }
    message { padding: 8px 12px; }
    textbox { text-color: @subtle; }
    listview { lines: 3; }
    element normal.active, element alternate.active { text-color: #fe8019; }
    element selected.active { text-color: #fe8019; }
'

_running() { pgrep -x hypridle >/dev/null 2>&1; }
_watching() { [[ -f $WATCH_PIDFILE ]] && kill -0 "$(<"$WATCH_PIDFILE")" 2>/dev/null; }
_claude_busy() { local busy _; read -r busy _ < <("$CLAUDE_BUSY" count); ((busy > 0)); }

_refresh_bar() { pkill -RTMIN+8 waybar 2>/dev/null || true; }
_notify() { notify-send -i caffeine "$1" "$2" 2>/dev/null || true; }

_mode() {
    if _watching; then echo claude
    elif _running; then echo off
    else echo on
    fi
}

_stop_watch() {
    _watching && kill "$(<"$WATCH_PIDFILE")" 2>/dev/null || true
    rm -f "$WATCH_PIDFILE"
}

_set_off() {
    _stop_watch
    _running || setsid -f hypridle >/dev/null 2>&1 || true
    _notify "Caffeine off" "Normal idle & lock"
}

_set_on() {
    _stop_watch
    pkill -x hypridle || true
    _notify "Caffeine on" "Idle & lock paused"
}

_set_claude() {
    if ! _claude_busy; then
        _notify "Caffeine" "No Claude session is working"
        return
    fi
    pkill -x hypridle || true
    _watching || setsid -f "$0" _watch >/dev/null 2>&1
    _notify "Caffeine while Claude works" "Auto-lock resumes once every session is idle"
}

_menu() {
    local mode busy open active mesg choice
    mode=$(_mode)
    read -r busy open < <("$CLAUDE_BUSY" count)
    case "$mode" in off) active=0 ;; on) active=1 ;; claude) active=2 ;; esac
    if ((open == 0)); then
        mesg="No Claude sessions open"
    else
        mesg="Claude   $busy running · $((open - busy)) idle"
    fi

    choice=$(printf '󰒲  Auto-lock\n󰅶  Caffeine\n󰚩  Caffeine while Claude works' \
        | rofi -dmenu -i -p "󰅶 " -mesg "$mesg" -a "$active" -selected-row "$active" \
            -theme "$ROFI_THEME" -theme-str "$MENU_THEME") || return 0

    case "$choice" in
        *Auto-lock) [[ $mode == off ]] || _set_off ;;
        *Claude*)   [[ $mode == claude ]] || _set_claude ;;
        *Caffeine)  [[ $mode == on ]] || _set_on ;;
    esac
}

case "${1:-toggle}" in
    status)
        case "$(_mode)" in
            claude) printf '{"text":"󰅶","tooltip":"Caffeine while Claude works","class":"claude"}\n' ;;
            off)    printf '{"text":"󰅶","tooltip":"Auto-lock active","class":"inactive"}\n' ;;
            on)     printf '{"text":"󰅶","tooltip":"Caffeine on — auto-lock paused","class":"active"}\n' ;;
        esac
        ;;
    menu)
        _menu
        _refresh_bar
        ;;
    _watch)
        echo $$ >"$WATCH_PIDFILE"
        _refresh_bar
        while _claude_busy; do sleep "$WATCH_INTERVAL"; done
        rm -f "$WATCH_PIDFILE"
        _running || setsid -f hypridle >/dev/null 2>&1 || true
        _notify "Claude sessions idle" "Normal idle & lock"
        _refresh_bar
        ;;
    *)
        if [[ $(_mode) == off ]]; then _set_on; else _set_off; fi
        _refresh_bar
        ;;
esac
