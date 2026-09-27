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

# With the Lua config, `hyprctl dispatch` evaluates its argument as a Lua dispatcher.
lua_quote() { local s=${1//\\/\\\\}; printf '"%s"' "${s//\"/\\\"}"; }

if hyprctl clients -j | grep -qP "\"class\":\s*\"$class\""; then
    hyprctl dispatch "hl.dsp.workspace.toggle_special($(lua_quote "$name"))"
else
    cmd=$(lua_quote "alacritty --class $class -e $*")
    hyprctl dispatch "hl.dsp.exec_cmd($cmd, { workspace = $(lua_quote "special:$name") })"
fi
