#!/usr/bin/env bash
# Caffeine — idle inhibition through a systemd idle inhibitor (hypridle honours
# `systemd-inhibit --what=idle`), in three modes:
#   off     no inhibitor (normal auto-lock)
#   on      inhibitor held until turned off, or for the given minutes
#   claude  inhibitor held while any Claude session is mid-turn, then back to off
#           (busy state comes from claude-busy.sh Claude Code hooks)
# hypridle keeps running in every mode: its before_sleep_cmd is what locks the session
# before a lid-close or menu suspend, so stopping it would let those resume unlocked.
# That same hook runs `caffeine.sh off`, so going to sleep ends any mode. The inhibitor
# only covers idle, so it never holds off a lid-close suspend.
#
#   caffeine.sh off|claude      switch to that mode (the bar dropdown)
#   caffeine.sh on [MINUTES]    caffeine until turned off, or for MINUTES
#   caffeine.sh status          print JSON for the bar icon
set -euo pipefail

readonly HOLD_PIDFILE="${XDG_RUNTIME_DIR:-/tmp}/caffeine-on.pid" # "<pid> <end epoch, 0 = none>"
readonly WATCH_PIDFILE="${XDG_RUNTIME_DIR:-/tmp}/caffeine-claude.pid"
readonly WATCH_INTERVAL=10
readonly CLAUDE_BUSY="${0%/*}/claude-busy.sh"

_alive() { local pid _; [[ -f $1 ]] && read -r pid _ <"$1" && kill -0 "$pid" 2>/dev/null; }
_holding() { _alive "$HOLD_PIDFILE"; }
_watching() { _alive "$WATCH_PIDFILE"; }
_claude_busy() { local busy _; read -r busy _ < <("$CLAUDE_BUSY" count); ((busy > 0)); }
_ends() { local _ ends; [[ -f $HOLD_PIDFILE ]] && read -r _ ends <"$HOLD_PIDFILE"; echo "${ends:-0}"; }

_refresh_bar() { qs ipc call caffeine refresh >/dev/null 2>&1 || true; }
_notify() { notify-send -i caffeine "$1" "$2" 2>/dev/null || true; }

_mode() {
    if _watching; then echo claude
    elif _holding; then echo on
    else echo off
    fi
}

# Runs `caffeine.sh <subcommand> [arg]` detached under an idle inhibitor that lasts as long as it does.
_inhibit() {
    setsid -f systemd-inhibit --what=idle --who=Caffeine --why="$1" "$0" "${@:2}" >/dev/null 2>&1
}

_release() {
    local pid _
    [[ -f $1 ]] && read -r pid _ <"$1" && kill "$pid" 2>/dev/null || true
    rm -f "$1"
}

_ensure_hypridle() { pgrep -x hypridle >/dev/null 2>&1 || setsid -f hypridle >/dev/null 2>&1 || true; }

_set_off() {
    _release "$WATCH_PIDFILE"
    _release "$HOLD_PIDFILE"
    _notify "Caffeine off" "Normal idle & lock"
}

_set_on() {
    _release "$WATCH_PIDFILE"
    _release "$HOLD_PIDFILE"
    if [[ -n $1 ]]; then
        _inhibit "Caffeine for $1 min" _hold "$1"
        _notify "Caffeine on" "Idle paused until $(date -d "+$1 min" +%H:%M), or until the laptop sleeps"
    else
        _inhibit "Caffeine on" _hold
        _notify "Caffeine on" "Idle paused until turned off, or until the laptop sleeps"
    fi
}

_set_claude() {
    if ! _claude_busy; then
        _notify "Caffeine" "No Claude session is working"
        return
    fi
    _release "$HOLD_PIDFILE"
    _watching || _inhibit "A Claude session is working" _watch
    _notify "Caffeine while Claude works" "Auto-lock resumes once every session is idle"
}

case "${1:-}" in
    status)
        case "$(_mode)" in
            claude) printf '{"mode":"claude","text":"\\uf525","class":"claude"}\n' ;;
            off)    printf '{"mode":"off","text":"\\uefef","class":"inactive"}\n' ;;
            on)     printf '{"mode":"on","ends":%d,"text":"\\uefef","class":"active"}\n' "$(_ends)" ;;
        esac
        ;;
    off | claude)
        _ensure_hypridle
        [[ $(_mode) == "$1" ]] || "_set_$1"
        _refresh_bar
        ;;
    on)
        minutes="${2:-}"
        if [[ -n $minutes && ! $minutes =~ ^[1-9][0-9]*$ ]]; then
            echo "${0##*/}: minutes must be a positive whole number" >&2
            exit 2
        fi
        _ensure_hypridle
        _set_on "$minutes"
        _refresh_bar
        ;;
    _hold)
        # Killed by _release (switch or sleep) or ends on its own after the minutes.
        trap 'kill "${sleeper:-}" 2>/dev/null; exit 0' TERM
        secs=infinity ends=0
        if [[ -n ${2:-} ]]; then
            secs=$(($2 * 60))
            ends=$((EPOCHSECONDS + secs))
        fi
        echo "$$ $ends" >"$HOLD_PIDFILE"
        _refresh_bar
        sleep "$secs" &
        sleeper=$!
        wait "$sleeper"
        rm -f "$HOLD_PIDFILE"
        _notify "Caffeine ended" "Normal idle & lock"
        _refresh_bar
        ;;
    _watch)
        echo $$ >"$WATCH_PIDFILE"
        _refresh_bar
        while _claude_busy; do sleep "$WATCH_INTERVAL"; done
        rm -f "$WATCH_PIDFILE"
        _notify "Claude sessions idle" "Normal idle & lock"
        _refresh_bar
        ;;
    *)
        echo "usage: ${0##*/} off|on [MINUTES]|claude|status" >&2
        exit 2
        ;;
esac
