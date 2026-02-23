#!/usr/bin/env bash
if hyprctl clients -j | grep -q 'btop-scratch'; then
    hyprctl dispatch togglespecialworkspace btop
else
    hyprctl dispatch exec "[workspace special:btop] alacritty --class btop-scratch --option 'window.dimensions.columns=160' --option 'window.dimensions.lines=42' -e btop"
fi
