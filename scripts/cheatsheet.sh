#!/usr/bin/env bash
rofi -dmenu \
    -p "  Keybinds" \
    -theme ~/.config/rofi/rose-pine.rasi \
    -theme-str 'window { width: 680px; } listview { lines: 18; }' \
    -no-custom \
    -kb-accept-entry "" \
    -kb-cancel "Escape,q" \
    << 'EOF'
  APPLICATIONS
  Super + Return         Terminal (alacritty)
  Super + Y              File manager (Thunar)
  Super + N              Notes (Obsidian)
  Super+Shift+N          Obsidian quick-capture
  Super + Space          App launcher (rofi)
  Super + W              Browser (Firefox)
  Super+Shift+W          Browser — private window (Firefox)
  Super+Shift+O          Window switcher (rofi)
  WINDOWS
  Super + Q              Close window
  Super + F              Fullscreen toggle
  Super+Shift+V          Float toggle
  Super + B              Toggle Waybar
  Super + Tab            Cycle windows
  FOCUS  (vim hjkl)
  Super + H/J/K/L        Focus  left / down / up / right
  MOVE
  Super+Shift+H/J/K/L    Move window  left / down / up / right
  RESIZE
  Super+Alt+H/J/K/L      Resize window  (−30 / +30 px)
  WORKSPACES
  Super + 1–9 / 0        Switch to workspace 1–10
  Super+Shift+1–9        Move window to workspace
  Super + Scroll         Workspace ±1
  SCRATCHPADS
  Super + `              Terminal scratchpad
  Super + M              btop system monitor
  Super+Shift+B          Bluetooth (bluetui)
  SCREENSHOTS  (no Print key)
  Super+Shift+A          Area screenshot  (copy + save)
  Super+Shift+F          Full screenshot  (copy + save)
  CLIPBOARD
  Super + C              Copy selection → clipboard
  Super + V              Clipboard history picker
  SYSTEM
  Super + Escape         Lock screen (hyprlock)
  Super+Shift+P          Color picker (hyprpicker)
  Super+Shift+M          Power menu
  Super+Shift+I          Wallpaper picker (waypaper)
  Super+Shift+C          Caffeine (pause auto-lock)
  Super+Shift+/          This cheatsheet
  MEDIA
  XF86AudioRaiseVolume   Volume +5%
  XF86AudioLowerVolume   Volume −5%
  XF86AudioMute          Mute toggle
  XF86AudioPlay          Play / pause
  XF86AudioNext/Prev     Next / previous track
  MOUSE
  Super + LMB            Move window
  Super + RMB            Resize window
EOF
