#!/usr/bin/env bash
rofi -dmenu \
    -p "  Keybinds" \
    -theme ~/.config/rofi/catppuccin.rasi \
    -theme-str 'window { width: 680px; } listview { lines: 18; }' \
    -markup-rows \
    -no-custom \
    -kb-accept-entry "" \
    -kb-cancel "Escape,q" \
    << 'EOF'
<b><span foreground='#89dceb'>  APPLICATIONS</span></b>
  Super + Return         Terminal (alacritty)
  Super + Y              File manager (Thunar)
  Super + N              Notes (Obsidian)
  Super+Shift+N          Obsidian quick-capture
  Super + Space          App launcher (rofi)
  Super + W              Browser (Zen)
  Super+Shift+W          Browser — private window (Zen)
  Super+Shift+O          Window switcher (rofi)
<b><span foreground='#89dceb'>  WINDOWS</span></b>
  Super + Q              Close window
  Super + F              Fullscreen toggle
  Super+Shift+V          Float toggle
  Super + B              Toggle Waybar
  Super + Tab            Cycle windows
<b><span foreground='#89dceb'>  FOCUS  (vim hjkl)</span></b>
  Super + H/J/K/L        Focus  left / down / up / right
<b><span foreground='#89dceb'>  MOVE</span></b>
  Super+Shift+H/J/K/L    Move window  left / down / up / right
<b><span foreground='#89dceb'>  RESIZE</span></b>
  Super+Alt+H/J/K/L      Resize window  (−30 / +30 px)
<b><span foreground='#89dceb'>  WORKSPACES</span></b>
  Super + 1–9 / 0        Switch to workspace 1–10
  Super+Shift+1–9        Move window to workspace
  Super + Scroll         Workspace ±1
<b><span foreground='#89dceb'>  SCRATCHPADS</span></b>
  Super + `              Terminal scratchpad
  Super + M              btop system monitor
  Super+Shift+B          Bluetooth (bluetui)
  Super+Shift+T          Tasks (ratatoist)
<b><span foreground='#89dceb'>  SCREENSHOTS  (no Print key)</span></b>
  Super+Shift+A          Area screenshot  (copy + save)
  Super+Shift+F          Full screenshot  (copy + save)
<b><span foreground='#89dceb'>  CLIPBOARD</span></b>
  Super + C              Copy selection → clipboard
  Super + V              Clipboard history picker
<b><span foreground='#89dceb'>  SYSTEM</span></b>
  Super + Escape         Lock screen (hyprlock)
  Super+Shift+P          Color picker (hyprpicker)
  Super+Shift+M          Power menu
  Super+Shift+I          Wallpaper picker (waypaper)
  Super+Shift+C          Caffeine (pause auto-lock)
  Super+Shift+/          This cheatsheet
<b><span foreground='#89dceb'>  MEDIA</span></b>
  XF86AudioRaiseVolume   Volume +5%
  XF86AudioLowerVolume   Volume −5%
  XF86AudioMute          Mute toggle
  XF86AudioPlay          Play / pause
  XF86AudioNext/Prev     Next / previous track
<b><span foreground='#89dceb'>  MOUSE</span></b>
  Super + LMB            Move window
  Super + RMB            Resize window
EOF
