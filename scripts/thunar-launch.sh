#!/usr/bin/env bash
# Launch Thunar with Rose Pine theme (GTK theme name is rose-pine-gtk per upstream).
export GTK_THEME=rose-pine-gtk
export GTK_APPLICATION_PREFER_DARK_THEME=1
exec thunar "$@"
