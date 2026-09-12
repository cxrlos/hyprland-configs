#!/usr/bin/env bash
# Focus an existing window of the given class, or spawn it if none exists.
# Usage: focus-or-spawn.sh <class> <spawn-command...>
set -euo pipefail

class="$1"
shift

if hyprctl clients -j | jq -e --arg class "$class" '.[] | select(.class == $class)' >/dev/null; then
    hyprctl dispatch focuswindow "class:$class"
else
    hyprctl dispatch exec "$*"
fi
