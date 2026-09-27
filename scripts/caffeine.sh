#!/usr/bin/env bash
# Caffeine — idle inhibition by pausing/resuming hypridle, in three modes:
#   off     hypridle running (normal auto-lock)
#   on      hypridle stopped
#   claude  hypridle stopped while any Claude session is mid-turn, then back to off
#           (busy state comes from claude-busy.sh Claude Code hooks)
#
#   caffeine.sh off|on|claude   switch to that mode (the bar dropdown)
#   caffeine.sh status          print JSON for the bar icon
set -euo pipefail

readonly WATCH_PIDFILE="${XDG_RUNTIME_DIR:-/tmp}/caffeine-claude.pid"
readonly WATCH_INTERVAL=10
readonly CLAUDE_BUSY="${0%/*}/claude-busy.sh"

_running() { pgrep -x hypridle >/dev/null 2>&1; }
_watching() { [[ -f $WATCH_PIDFILE ]] && kill -0 "$(<"$WATCH_PIDFILE")" 2>/dev/null; }
_claude_busy() { local busy _; read -r busy _ < <("$CLAUDE_BUSY" count); ((busy > 0)); }

_refresh_bar() { qs ipc call caffeine refresh >/dev/null 2>&1 || true; }
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

case "${1:-}" in
    status)
        case "$(_mode)" in
            claude) printf '{"mode":"claude","text":"\\uf525","class":"claude"}\n' ;;
            off)    printf '{"mode":"off","text":"\\uefef","class":"inactive"}\n' ;;
            on)     printf '{"mode":"on","text":"\\uefef","class":"active"}\n' ;;
        esac
        ;;
    off | on | claude)
        [[ $(_mode) == "$1" ]] || "_set_$1"
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
        echo "usage: ${0##*/} off|on|claude|status" >&2
        exit 2
        ;;
esac
