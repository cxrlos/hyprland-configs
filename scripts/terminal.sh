#!/usr/bin/env bash
set -euo pipefail

ACTIVE_WIN=$(hyprctl activewindow -j)
ACTIVE_CLASS=$(printf '%s' "$ACTIVE_WIN" | grep -oP '"class":\s*"\K[^"]+' || true)
APID=$(printf '%s' "$ACTIVE_WIN" | grep -oP '"pid":\s*\K[0-9]+' || true)

if [[ "$ACTIVE_CLASS" == "float-term" ]]; then
    hyprctl dispatch killactive
    exit 0
fi

if hyprctl clients -j | grep -q 'float-term'; then
    hyprctl dispatch focuswindow "class:float-term"
    exit 0
fi

CWD=""

_tmux_pane_path() {
    local pid="$1" env_line sock
    env_line=$(tr '\0' '\n' < "/proc/$pid/environ" 2>/dev/null | grep '^TMUX=' || true)
    [[ -z "$env_line" ]] && return
    sock="${env_line#TMUX=}"
    sock="${sock%%,*}"
    tmux -S "$sock" display-message -p '#{pane_current_path}' 2>/dev/null || true
}

if [[ -n "$APID" ]]; then
    SPID=$(pgrep -P "$APID" 2>/dev/null | head -1 || true)
    if [[ -n "$SPID" ]]; then
        SNAME=$(cat "/proc/$SPID/comm" 2>/dev/null || true)
        if [[ "$SNAME" == "tmux"* ]]; then
            CWD=$(_tmux_pane_path "$SPID")
        else
            GPID=$(pgrep -P "$SPID" 2>/dev/null | head -1 || true)
            if [[ -n "$GPID" ]]; then
                GNAME=$(cat "/proc/$GPID/comm" 2>/dev/null || true)
                if [[ "$GNAME" == "tmux"* ]]; then
                    CWD=$(_tmux_pane_path "$GPID")
                else
                    CWD=$(readlink "/proc/$SPID/cwd" 2>/dev/null || true)
                fi
            else
                CWD=$(readlink "/proc/$SPID/cwd" 2>/dev/null || true)
            fi
        fi
    fi
fi

[[ -d "$CWD" ]] || CWD="$HOME"
exec env TERM_FLOAT=1 alacritty --class float-term --working-directory "$CWD"
