#!/usr/bin/env bash
if hyprctl clients -j | grep -q 'wiremix-scratch'; then
    hyprctl dispatch togglespecialworkspace wiremix
else
    hyprctl dispatch exec "[workspace special:wiremix] alacritty --class wiremix-scratch -e wiremix"
fi
