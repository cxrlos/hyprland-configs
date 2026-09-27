#!/usr/bin/env bash
# Renumber workspaces so occupied ones sit at 1..N with no gaps, since the bar shows
# unnumbered dots. Windows move without stealing focus; the focused workspace counts as
# occupied even when empty (so nothing slides onto the screen you're looking at) and
# focus follows it if it gets renumbered. Special workspaces (scratchpads) are untouched.
set -euo pipefail

clients=$(hyprctl clients -j)
active=$(hyprctl activeworkspace -j | jq '.id')

mapfile -t occupied < <(jq -r --argjson active "$active" \
    '[.[].workspace.id, $active] | map(select(. > 0)) | unique | .[]' <<<"$clients")

target=1
refocus=""
for id in "${occupied[@]}"; do
    if ((id != target)); then
        while read -r address; do
            hyprctl dispatch "hl.dsp.window.move({ workspace = \"$target\", follow = false, window = \"address:$address\" })" >/dev/null
        done < <(jq -r --argjson id "$id" '.[] | select(.workspace.id == $id) | .address' <<<"$clients")
        ((id == active)) && refocus=$target
    fi
    ((target += 1))
done

if [[ -n $refocus ]]; then
    hyprctl dispatch "hl.dsp.focus({ workspace = \"$refocus\" })" >/dev/null
fi
