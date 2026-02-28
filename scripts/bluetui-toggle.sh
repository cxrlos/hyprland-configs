#!/usr/bin/env bash
if hyprctl clients -j | grep -q 'bluetui-float'; then
    hyprctl dispatch togglespecialworkspace bluetui
else
    hyprctl dispatch exec "[workspace special:bluetui] alacritty --class bluetui-float -e bluetui"
fi
