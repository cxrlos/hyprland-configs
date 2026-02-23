#!/usr/bin/env bash
rofi -dmenu \
    -p "  Keybinds" \
    -theme ~/.config/rofi/rose-pine.rasi \
    -theme-str 'window { width: 680px; } listview { lines: 18; }' \
    -markup-rows \
    -no-custom \
    -kb-accept-entry "" \
    -kb-cancel "Escape,q" \
    << 'EOF'
<b><span foreground='#c4a7e7'>  APPLICATIONS</span></b>
  Super + Return         Terminal (alacritty)
  Super + E              File manager (yazi — q quits, not :q)
  Super + Space          App launcher (rofi)
  Super + W              Window switcher (rofi)
<b><span foreground='#c4a7e7'>  WINDOWS</span></b>
  Super + Q              Close window
  Super + F              Fullscreen toggle
  Super+Shift+V          Float toggle
  Super + P              Pseudotile toggle
  Super + B              Toggle Waybar
<b><span foreground='#c4a7e7'>  FOCUS  (vim hjkl)</span></b>
  Super + H/J/K/L        Focus  left / down / up / right
<b><span foreground='#c4a7e7'>  MOVE</span></b>
  Super+Shift+H/J/K/L    Move window  left / down / up / right
<b><span foreground='#c4a7e7'>  RESIZE</span></b>
  Super+Alt+H/J/K/L      Resize window  (−30 / +30 px)
<b><span foreground='#c4a7e7'>  WORKSPACES</span></b>
  Super + 1–9 / 0        Switch to workspace 1–10
  Super+Shift+1–9        Move window to workspace
  Super + Scroll         Workspace ±1
<b><span foreground='#c4a7e7'>  SCREENSHOTS  (no Print key)</span></b>
  Super+Shift+A          Area screenshot  (copy + save)
  Super+Shift+F          Full screenshot  (copy + save)
<b><span foreground='#c4a7e7'>  CLIPBOARD</span></b>
  Super + C              Copy selection → clipboard
  Super + V              Clipboard history picker
<b><span foreground='#c4a7e7'>  SYSTEM</span></b>
  Super + Escape         Lock screen (hyprlock)
  Super+Shift+P          Color picker (hyprpicker)
  Super+Shift+M          Power menu
  Super+Shift+/          This cheatsheet
<b><span foreground='#c4a7e7'>  MEDIA</span></b>
  XF86AudioRaiseVolume   Volume +5%
  XF86AudioLowerVolume   Volume −5%
  XF86AudioMute          Mute toggle
  XF86MonBrightnessUp    Brightness +5%
  XF86MonBrightnessDown  Brightness −5%
  XF86AudioPlay          Play / pause
  XF86AudioNext/Prev     Next / previous track
<b><span foreground='#c4a7e7'>  MOUSE</span></b>
  Super + LMB            Move window
  Super + RMB            Resize window
<b><span foreground='#c4a7e7'>  WALLPAPER</span></b>
  wallpaper /path/img    Set new wallpaper (live reload)
  wallpaper              Print current wallpaper path
EOF
