#!/usr/bin/env bash
# Launch Thunar with the Catppuccin GTK theme.
export GTK_THEME=catppuccin-mocha-sky-standard+default
export GTK_APPLICATION_PREFER_DARK_THEME=1
exec thunar "$@"
