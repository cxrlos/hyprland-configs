# Hyprland Configuration

Hyprland WM setup for Arch Linux — Rose Pine, BerkeleyMono Nerd Font, fully keyboard-driven.

## Install

```bash
git clone https://github.com/cxrlos/hyprland-configs.git
cd hyprland-configs
bash install.sh
```

Installs pacman + AUR dependencies, symlinks all configs to `~/.config/`, writes GTK theme settings, and optionally configures greetd as the boot greeter.

## Structure

```
hyprland-configs/
├── install.sh              Arch Linux installer
├── hypr/
│   ├── hyprland.conf       entry point — sources all sub-configs + autostart
│   ├── monitors.conf       monitor layout (edit for your hardware)
│   ├── keybinds.conf       all keybindings
│   ├── rules.conf          window + layer rules
│   ├── animations.conf     bezier curves + animation config
│   ├── hyprlock.conf       lockscreen (Rose Pine, blur, clock)
│   └── hypridle.conf       idle chain: dim → lock → suspend
├── waybar/
│   ├── config.jsonc        bar layout
│   └── style.css           Rose Pine CSS
├── rofi/
│   └── rose-pine.rasi      launcher theme (shared by all rofi calls)
├── swaync/
│   ├── config.json         notification center config
│   └── style.css           Rose Pine CSS
├── thunar/
│   ├── thunarrc            file manager defaults (details view, tree pane)
│   ├── gtk.css             Thunar-only Rose Pine GTK overrides
│   └── README.md           usage and xfconf notes
├── waypaper/
│   └── config.ini          waypaper config (wallpaper restore)
└── scripts/
    ├── install.sh           → install.sh (symlinked)
    ├── screenshot.sh        area/screen capture → rofi picker (copy/save/both)
    ├── clipboard.sh         cliphist | rofi picker → wl-copy
    ├── power.sh             rofi power menu (lock/suspend/reboot/shutdown)
    ├── wallpaper.sh         live wallpaper swap (also exposed as `wallpaper` in PATH)
    ├── terminal.sh          Super+T toggle: CWD-aware float terminal (tmux-aware)
    ├── thunar-launch.sh      Launches Thunar with Rose Pine GTK theme env
    ├── btop-toggle.sh       Super+M toggle: btop scratchpad (create-or-toggle)
    └── cheatsheet.sh        Super+Shift+/ floating keybind reference
```

## Keybindings

`Super` is the WM modifier. Vim `hjkl` for all directional actions.

### Applications

| Key | Action |
|---|---|
| `Super+Return` | terminal (alacritty, `$HOME`) |
| `Super+T` | float terminal at active window's CWD — toggle |
| `Super+Space` | app launcher (rofi drun) |
| `Super+W` | browser (`$browser`) |
| `Super+Shift+W` | window switcher (rofi) |
| `Super+D` | show desktop (go to next empty workspace) |

### Scratchpads

| Key | Action |
|---|---|
| `Super+\`` | general scratchpad terminal |
| `Super+Y` | Thunar file manager |
| `Super+M` | btop system monitor |

### Windows

| Key | Action |
|---|---|
| `Super+Q` | close window |
| `Super+F` | fullscreen |
| `Super+Shift+V` | toggle floating |
| `Super+H/J/K/L` | move focus |
| `Super+Shift+H/J/K/L` | move window |
| `Super+Alt+H/J/K/L` | resize (repeatable) |
| `Super+Tab` / `Super+Shift+Tab` | cycle windows |

### Workspaces

| Key | Action |
|---|---|
| `Super+1–0` | switch to workspace 1–10 |
| `Super+Shift+1–0` | move window to workspace 1–10 |
| `Super+Scroll` | workspace ±1 |

### System

| Key | Action |
|---|---|
| `Super+Escape` | lock screen (hyprlock) |
| `Super+Shift+M` | power menu (rofi) |
| `Super+Shift+A` | screenshot area → copy/save picker |
| `Super+Shift+F` | screenshot fullscreen → copy/save picker |
| `Super+V` | clipboard history picker |
| `Super+C` | copy PRIMARY selection to clipboard |
| `Super+B` | toggle waybar |
| `Super+Shift+B` | bluetui (Bluetooth TUI) |
| `Super+Shift+P` | color picker (hyprpicker) |
| `Super+Shift+/` | keybind cheatsheet |

### Media

| Key | Action |
|---|---|
| `XF86AudioRaiseVolume/LowerVolume` | volume ±5% |
| `XF86AudioMute` | mute toggle |
| `XF86MonBrightnessUp/Down` | brightness ±5% |
| `XF86AudioPlay/Next/Prev` | playerctl |

## Idle behavior

```
5 min   → dim screen to 20%
10 min  → hyprlock
15 min  → suspend
sleep   → lock before suspend, restore DPMS on wake
```

## Customization

**Monitors** — edit `hypr/monitors.conf` to match your hardware.

**Wallpaper** — set at install time (prompted) or anytime:
```bash
wallpaper /path/to/image.png
```

**Fonts** — BerkeleyMono Nerd Font is commercial. Place the patched variant in
`~/.local/share/fonts/` before running install.sh.

## Stack

| Role | Tool |
|---|---|
| WM | Hyprland |
| Bar | Waybar |
| Launcher | rofi-wayland |
| Notifications | swaync |
| Wallpaper | hyprpaper |
| Lock | hyprlock |
| Idle | hypridle |
| Screenshot | grimblast (grim+slurp fallback) |
| Clipboard | wl-clipboard + cliphist |
| File manager | Thunar (Super+Y) |
| Bluetooth | bluetui |
| System monitor | btop |
| Greeter | greetd + tuigreet |

## Related

- [`term-configs`](../term-configs) — Alacritty, Tmux, Zsh, Starship
- [`neovim-configs`](../neovim-configs) — Neovim
