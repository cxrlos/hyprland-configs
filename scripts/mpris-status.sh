#!/usr/bin/env bash
# Now-playing track via playerctl, for the custom/mpris waybar module.
set -euo pipefail

max_len=40

if ! playerctl status >/dev/null 2>&1; then
    printf '{"text": "", "tooltip": "", "class": "empty"}\n'
    exit 0
fi

track=$(playerctl metadata --format '{{ artist }} - {{ title }}' 2>/dev/null || echo "")
if [[ -z "$track" ]]; then
    printf '{"text": "", "tooltip": "", "class": "empty"}\n'
    exit 0
fi

if (( ${#track} > max_len )); then
    display="${track:0:max_len}…"
else
    display="$track"
fi

status=$(playerctl status 2>/dev/null || echo "Unknown")
printf '{"text": "󰝚 %s", "tooltip": "%s\n%s", "class": "mpris"}\n' "$display" "$track" "$status"
