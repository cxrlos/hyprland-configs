#!/usr/bin/env bash
# Tracks Claude Code sessions for caffeine.sh's claude mode and menu counts.
# One file per session under $STATE_DIR: "<claude PID> <busy|idle>".
#
#   claude-busy.sh start|busy|stop|idle|end   Claude Code hook (hook JSON on stdin)
#   claude-busy.sh count                      print "<busy> <open>" for live sessions
set -euo pipefail

readonly STATE_DIR="${XDG_RUNTIME_DIR:-/run/user/$UID}/claude-busy"

_is_claude() { [[ $(cat "/proc/$1/comm" 2>/dev/null) == claude ]]; }

_claude_pid() {
    local pid=$PPID
    while ((pid > 1)); do
        _is_claude "$pid" && { echo "$pid"; return; }
        pid=$(awk '/^PPid:/ {print $2}' "/proc/$pid/status")
    done
    return 1
}

_record() {
    local session pid
    session=$(jq -r .session_id <<<"$hook_input")
    pid=$(_claude_pid) || return 0
    mkdir -p "$STATE_DIR"
    echo "$pid $1" >"$STATE_DIR/$session"
}

case "${1:-}" in
    count)
        busy=0 open=0
        for f in "$STATE_DIR"/*; do
            [[ -f $f ]] || continue
            read -r pid state <"$f"
            if _is_claude "$pid"; then
                open=$((open + 1))
                [[ $state == busy ]] && busy=$((busy + 1))
            else
                rm -f "$f"
            fi
        done
        echo "$busy $open"
        ;;
    start | idle)
        hook_input=$(cat)
        _record idle
        ;;
    busy)
        hook_input=$(cat)
        _record busy
        ;;
    stop)
        # The main turn ended, but background subagents/shells/workflows may still
        # be running; their completion re-enters the session via UserPromptSubmit.
        hook_input=$(cat)
        if jq -e 'any(.background_tasks[]?; .status == "running")' <<<"$hook_input" >/dev/null; then
            _record busy
        else
            _record idle
        fi
        ;;
    end)
        rm -f "$STATE_DIR/$(jq -r .session_id)"
        ;;
esac
