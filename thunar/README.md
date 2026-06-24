# Thunar — Catppuccin Mocha

Thunar config matched to the Hyprland stack (Catppuccin Mocha, compact details view).
**Super+Y** opens Thunar as a normal tiled window.

## Files

- **thunarrc** — default view (details), tree side pane, status bar, compact zoom, column order.
- **gtk.css** — Thunar-only GTK3 overrides (sidebar, list, toolbar, status bar). The installer
  appends this to `~/.config/gtk-3.0/gtk.css` so it applies without overwriting other GTK settings.
- **uca.xml** — custom actions (Open Terminal Here).

## Theme

Global GTK theme (`catppuccin-mocha-sky-standard+default`), font (`MonaspiceNe Nerd Font 11`),
icon theme (`Papirus-Dark`), and cursor are written by the main installer. Thunar is launched via
`scripts/thunar-launch.sh`, which sets `GTK_THEME` and `GTK_APPLICATION_PREFER_DARK_THEME=1`.

If Thunar shows a light theme: ensure `catppuccin-gtk-theme-mocha` is installed (`yay -S catppuccin-gtk-theme-mocha`),
confirm the exact theme name with `ls ~/.local/share/themes /usr/share/themes`, set it in
`~/.config/gtk-3.0/settings.ini`, then restart Thunar (`thunar -q; thunar`).

## After install

```bash
thunar -q; thunar
```
