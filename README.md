# hyprland-configs

Desktop Hyprland setup for Arch Linux — Gruvbox, Mononoki Nerd Font, keyboard-driven.
Pairs with [`term-configs`](../term-configs) and [`neovim-configs`](../neovim-configs).

## Install

```bash
git clone https://github.com/cxrlos/hyprland-configs.git
cd hyprland-configs
bash scripts/install.sh
```

Installs pacman + AUR dependencies (plus the CPU's microcode), symlinks configs into `~/.config/`,
writes GTK font/cursor settings, copies the root-owned udev rules and `logid.cfg` into `/etc`,
merges the Claude Code busy hooks into `~/.claude/settings.json`, and optionally configures
greetd as the boot greeter.

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
| Browser | Zen |
| Notes | Obsidian |
| File manager | Thunar |
| Bluetooth | bluetui |
| System monitor | btop |
| Greeter | greetd + ReGreet |

## Layout

```
hypr/       hyprland.lua sources monitors / animations / keybinds / rules (all Lua);
            plus hyprlock.conf, hypridle.conf, hyprpaper.conf (classic hyprlang format)
waybar/     bar config + style
rofi/       gruvbox.rasi — launcher theme, shared by every rofi call
swaync/     notification center config + style
thunar/     file manager defaults
waypaper/   wallpaper picker config
logiops/    MX Master config, copied to /etc/logid.cfg
udev/       Logi Bolt + 8BitDo rules, copied to /etc/udev/rules.d
fontconfig/ Apple emoji fallback
gamemode.ini  GameMode profile (GPU section lives in /etc/gamemode.ini)
scripts/    install.sh + keybind/menu helpers
```

`hyprland.lua` is the only Hyprland WM config now — the old `.conf` files were removed
since Hyprland only loads one config format exclusively. `hyprlock.conf`, `hypridle.conf`,
and `hyprpaper.conf` stay on the classic hyprlang format permanently, since those satellite
tools don't support Lua config.

**If `hyprland.lua` breaks the session:** drop to a TTY (`Ctrl+Alt+F3`), then either fix
`hyprland.lua` directly with a TTY-available editor, run `Hyprland --config /path/to/a/known-good/backup`
if one exists, or `git checkout HEAD~1 -- hypr/` to restore the last working version (if this
checkout is a git working copy).

## Keys

`Super` is the modifier; vim `hjkl` drives focus / move / resize.
Full reference in-session: **Super+Shift+/** (cheatsheet), or read `hypr/keybinds.lua`.

| Key | Action |
|---|---|
| `Super+Return` | terminal |
| `Super+W` / `Super+Shift+W` | Zen / private window |
| `Super+N` / `Super+Shift+N` | Obsidian / quick-capture |
| `Super+Shift+C` | caffeine toggle (bar click: mode menu incl. *while Claude works*) |
| `Super+Y` | Thunar |
| `Super+Space` | app launcher |
| `Super+\`` | terminal scratchpad |
| `Super+M` / `Super+Shift+B` | btop / bluetui scratchpads |
| `Super+H/J/K/L` | focus (Shift = move; `Super+R` then hjkl = resize) |
| `Super+1–0` | workspaces (Shift = move window) |
| `Super+Escape` | lock |
| `Super+S` then `L/U/R/P` | lock / suspend / reboot / power off |

## Idle

```
10 min → lock (hyprlock)
15 min → monitor off (DPMS)
30 min → suspend
on sleep → lock first, restore DPMS on wake
caffeine (any mode) pauses all three
```

## Customize

- **Monitors** — `hypr/monitors.lua`
- **Browser** — Zen (`zen-browser`); `Super+W` launches it (`Super+Shift+W` = private window)
- **Wallpaper** — `Super+Shift+I` (waypaper)
