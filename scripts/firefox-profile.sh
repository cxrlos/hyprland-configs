#!/usr/bin/env bash
# Launch Firefox for profile dir $1, or focus existing window if that profile is already open.
set -e
PROFILE_DIR="$1"
[[ -z "$PROFILE_DIR" ]] && { echo "Usage: $0 <profile-dir>" >&2; exit 1; }
PROFILE_PATH="$HOME/.config/mozilla/firefox/$PROFILE_DIR"

# Find PID of firefox process using this profile (cmdline contains the profile path)
for pid in $(pgrep -x firefox 2>/dev/null); do
  if [[ -r /proc/$pid/cmdline ]]; then
    cmd=$(tr '\0' ' ' < /proc/$pid/cmdline 2>/dev/null)
    if [[ "$cmd" == *"$PROFILE_DIR"* ]]; then
      hyprctl dispatch workspace 2
      hyprctl dispatch focuswindow "pid:$pid"
      exit 0
    fi
  fi
done

hyprctl dispatch workspace 2
exec firefox -profile "$PROFILE_PATH"
