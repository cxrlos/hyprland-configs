# hyprland-configs

Desktop Hyprland setup for Arch Linux — Rose Pine, Monaspace Nerd Font, keyboard-driven.
Pairs with [`term-configs`](../term-configs) and [`neovim-configs`](../neovim-configs).

## Install

```bash
git clone https://github.com/cxrlos/hyprland-configs.git
cd hyprland-configs
bash scripts/install.sh
```

Installs pacman + AUR dependencies, symlinks configs into `~/.config/`, writes GTK theme/font
settings, and optionally configures greetd as the boot greeter.

## Stack

| Role | Tool |
|---|---|
| WM | Hyprland |
| Bar | Waybar |
| Launcher | rofi-wayland |
| Notifications | swaync |
| Wallpaper | waypaper + hyprpaper |
| Lock / Idle | hyprlock / hypridle |
| Screenshot | grimblast (grim+slurp fallback) |
| Clipboard | wl-clipboard + cliphist |
| Browser | Firefox |
| Notes | Obsidian |
| File manager | Thunar |
| Bluetooth | bluetui |
| System monitor | btop |
| Greeter | greetd + ReGreet |

## Layout

```
hypr/       hyprland.conf sources monitors / animations / keybinds / rules; plus hyprlock, hypridle
waybar/     bar config + style
rofi/       rose-pine.rasi — launcher theme, shared by every rofi call
swaync/     notification center config + style
thunar/     file manager defaults
waypaper/   wallpaper picker config
scripts/    install.sh + keybind/menu helpers
```

## Keys

`Super` is the modifier; vim `hjkl` drives focus / move / resize.
Full reference in-session: **Super+Shift+/** (cheatsheet), or read `hypr/keybinds.conf`.

| Key | Action |
|---|---|
| `Super+Return` | terminal |
| `Super+W` / `Super+Shift+W` | Firefox / private window |
| `Super+N` / `Super+Shift+N` | Obsidian / quick-capture |
| `Super+Shift+C` | caffeine — pause idle & lock |
| `Super+Y` | Thunar |
| `Super+Space` | app launcher |
| `Super+\`` | terminal scratchpad |
| `Super+M` / `Super+Shift+B` | btop / bluetui scratchpads |
| `Super+H/J/K/L` | focus (Shift = move, Alt = resize) |
| `Super+1–0` | workspaces (Shift = move window) |
| `Super+Escape` | lock |

## Idle

```
10 min → lock (hyprlock)
15 min → monitor off (DPMS)
on sleep → lock first, restore DPMS on wake
```

## Customize

- **Monitors** — `hypr/monitors.conf`
- **Browser** — Firefox; `Super+W` launches it (`Super+Shift+W` = private window)
- **Wallpaper** — `Super+Shift+I` (waypaper)
