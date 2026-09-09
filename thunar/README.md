# Thunar

Thunar config matched to the Hyprland stack (compact details view).
**Super+Y** opens Thunar as a normal tiled window.

## Files

- **thunarrc** — default view (details), tree side pane, status bar, compact zoom, column order.
- **uca.xml** — custom actions (Open Terminal Here).
- **accels.scm** — keyboard accelerators.

## Theme

Global GTK icon theme (`Papirus-Dark`), font (`MonaspiceNe Nerd Font 11`), and cursor are written
by the main installer to `~/.config/gtk-{3,4}.0/settings.ini`. Thunar is launched via the plain
`thunar` command.

## After install

```bash
thunar -q; thunar
```
