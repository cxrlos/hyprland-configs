#!/usr/bin/env bash
# Toggle a region screen recording with wf-recorder.
# First run: slurp-select a region and start recording in the background.
# While running: SIGINT stops it gracefully so the mp4 is finalized correctly.
set -euo pipefail

if pgrep -x wf-recorder >/dev/null 2>&1; then
    pkill -INT wf-recorder
    notify-send "Recording stopped" "Saved to ~/Videos" 2>/dev/null || true
else
    region=$(slurp) || exit 0
    mkdir -p "$HOME/Videos"
    outfile="$HOME/Videos/recording-$(date +%Y%m%d-%H%M%S).mp4"
    setsid -f wf-recorder -g "$region" -f "$outfile" >/dev/null 2>&1
    notify-send "Recording started" "$outfile" 2>/dev/null || true
fi
