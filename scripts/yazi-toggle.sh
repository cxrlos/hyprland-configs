#!/usr/bin/env bash

if hyprctl clients -j | grep -q 'yazi-scratch'; then
    hyprctl dispatch togglespecialworkspace yazi
else
    hyprctl dispatch exec "[workspace special:yazi] alacritty --class yazi-scratch -e $HOME/.config/scripts/yazi-loop.sh"
fi
