#!/usr/bin/env bash
rofi -dmenu \
    -p "  Keybinds" \
    -theme ~/.config/rofi/gruvbox.rasi \
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
  Super + W              Browser (Zen)
  Super+Shift+W          Browser — private window (Zen)
  Super+Shift+O          Window switcher (rofi)
  WINDOWS
  Super + Q              Close window
  Super + F              Fullscreen toggle
  Super+Shift+V          Float toggle
  Super + B              Toggle Waybar
  Super + Tab            Cycle windows  (Shift reverses)
  FOCUS  (vim hjkl)
  Super + H/J/K/L        Focus  left / down / up / right
  MOVE
  Super+Shift+H/J/K/L    Move window  left / down / up / right
  RESIZE
  Super + R, then H/J/K/L  Resize (±30 px)  · Esc/Return exits
  WORKSPACES
  Super + 1–9 / 0        Switch to workspace 1–10
  Super+Shift+1–9 / 0    Move window to workspace
  Super + D              Jump to an empty workspace
  SCRATCHPADS
  Super + `              Terminal scratchpad
  Super + M              btop system monitor
  Super+Shift+B          Bluetooth (bluetui)
  SCREENSHOTS  (no Print key)
  Super+Shift+A          Area screenshot  (copy / save menu)
  Super+Shift+F          Full screenshot  (copy / save menu)
  Super+Shift+R          Screen recording  (press again to stop)
  CLIPBOARD
  Super + C              Copy selection → clipboard
  Super + V              Clipboard history picker
  SYSTEM
  Super + Escape         Lock screen (hyprlock)
  Super + S, then L/U/R/P  Lock / suspend / reboot / power off
  Super+Shift+M          Power menu
  Super+Shift+C          Caffeine toggle  (bar click: mode menu)
  Super+Shift+D          Notifications: do not disturb
  Super+Shift+P          Color picker (hyprpicker)
  Super+Shift+I          Wallpaper picker (waypaper)
  Super+Shift+/          This cheatsheet
  MEDIA
  XF86AudioRaiseVolume   Volume +5%
  XF86AudioLowerVolume   Volume −5%
  XF86AudioMute          Mute toggle
  XF86AudioMicMute       Mic mute toggle
  XF86AudioPlay          Play / pause
  XF86AudioNext/Prev     Next / previous track
  MOUSE
  Super + LMB            Move window
  Super + RMB            Resize window
EOF
