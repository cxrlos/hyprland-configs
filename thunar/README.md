# Thunar — Rose Pine

Thunar file manager config tuned to match the Hyprland stack (Rose Pine palette, BerkeleyMono, compact details view). **Super+Y** opens Thunar as a normal tiled window (no scratchpad or floating).

## What’s in this folder

- **thunarrc** — Default view (details), tree side pane, status bar, compact zoom, column order.
- **gtk.css** — Thunar-only GTK3 CSS overrides (sidebar, list, toolbar, status bar in Rose Pine colors).  
  The installer appends this to `~/.config/gtk-3.0/gtk.css` so it applies to Thunar without overwriting other GTK settings.

## Visual style

Uses the same palette as waybar/swaync/rofi:

- Base/surface/overlay: `#191724`, `#1f1d2e`, `#26233a`
- Text/subtle/muted: `#e0def4`, `#908caa`, `#6e6a86`
- Accent (selection): `#c4a7e7` (iris)

Global GTK theme (Rose Pine), font (BerkeleyMono Nerd Font Mono 12), and icon theme (Papirus-Dark) are set by the main installer. The theme name is **rose-pine-gtk** (upstream). Thunar is launched via `scripts/thunar-launch.sh`, which sets `GTK_THEME=rose-pine-gtk` and `GTK_APPLICATION_PREFER_DARK_THEME=1`.

**If Thunar still shows a light theme:** ensure the Rose Pine GTK theme is installed (`yay -S rose-pine-gtk-theme`) and run the main `install.sh` so `~/.config/gtk-3.0/settings.ini` has `gtk-theme-name=rose-pine-gtk` and `gtk-application-prefer-dark-theme=1`. Check the exact theme name with `ls /usr/share/themes` (e.g. `rose-pine-gtk` or `Rosé Pine`). Then fully quit and reopen Thunar (`thunar -q; thunar`).

## After install

Restart Thunar to apply config/CSS changes:

```bash
thunar -q; thunar
```

## Optional: xfconf tweaks

For hidden options (e.g. always-show-tabs, compact-view max chars), use:

```bash
xfconf-query --channel thunar -lv
xfconf-query --channel thunar --property /misc-always-show-tabs --create --type bool --set true
```

Quit Thunar before changing xfconf (`thunar -q`).
