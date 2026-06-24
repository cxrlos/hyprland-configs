#!/usr/bin/env bash
# Create-or-toggle a special-workspace scratchpad running a command in Alacritty.
# exec-once does not re-run on `hyprctl reload`, so the scratchpad is created on
# first invocation and toggled thereafter.
#
# Usage: scratch.sh <name> <class> <command> [args...]
set -euo pipefail

name="$1"
class="$2"
shift 2

if hyprctl clients -j | grep -qP "\"class\":\s*\"$class\""; then
    hyprctl dispatch togglespecialworkspace "$name"
else
    hyprctl dispatch exec "[workspace special:$name] alacritty --class $class -e $*"
fi
