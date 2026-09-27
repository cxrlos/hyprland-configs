#!/usr/bin/env bash
# Focus an existing window of the given class, or spawn it if none exists.
# Usage: focus-or-spawn.sh <class> <spawn-command...>
set -euo pipefail

class="$1"
shift

# With the Lua config, `hyprctl dispatch` evaluates its argument as a Lua dispatcher.
lua_quote() { local s=${1//\\/\\\\}; printf '"%s"' "${s//\"/\\\"}"; }

if hyprctl clients -j | jq -e --arg class "$class" '.[] | select(.class == $class)' >/dev/null; then
    hyprctl dispatch "hl.dsp.focus({ window = $(lua_quote "class:$class") })"
else
    hyprctl dispatch "hl.dsp.exec_cmd($(lua_quote "$*"))"
fi
