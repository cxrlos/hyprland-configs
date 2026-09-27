# hyprland-configs

Desktop Hyprland setup for Arch Linux: a frosted, macOS-like shell around a Gruvbox terminal workflow.
Pairs with [`term-configs`](../term-configs) and [`neovim-configs`](../neovim-configs).

## Install

```bash
git clone https://github.com/cxrlos/hyprland-configs.git
cd hyprland-configs
bash scripts/install.sh
```

Installs pacman + AUR dependencies (plus the CPU's microcode), symlinks configs into `~/.config/`,
writes GTK font/cursor/accent settings, copies the udev rules into `/etc`, merges the Claude Code
busy hooks into `~/.claude/settings.json`, and optionally configures greetd + ReGreet.

## What you get

- **Menu bar** (Quickshell): workspace dots, app name, clock, and icons that open dropdowns:
  Sound (volume, outputs, inputs), Wi-Fi (networks, inline password), Bluetooth (devices, pairing),
  Idle (caffeine modes), Power, Calendar, Now playing, System (metrics, updates).
- **Panels**: clipboard history with image previews (`Super+V`) and a keybind cheatsheet (`Super+Shift+/`).
- **Launcher**: rofi, frosted to match (`Super+Space`).
- **Lock and greeter**: the current wallpaper, blurred, with a large clock and a rounded card.
- **Screenshots**: copied instantly; the notification offers Save / Open.

## Layout

```
hypr/        Hyprland (Lua) + hyprlock / hypridle / hyprpaper (.conf)
quickshell/  bar, dropdowns, panels, shared widgets, Theme.qml
rofi/        chrome.rasi launcher theme
swaync/      notification center config + style
thunar/      file manager defaults
waypaper/    wallpaper picker config
udev/        8BitDo rules, copied to /etc/udev/rules.d
fontconfig/  Apple emoji fallback
scripts/     install.sh and the helpers the shell calls
```

**If `hyprland.lua` breaks the session:** switch to a TTY (`Ctrl+Alt+F3`) and fix it there, or
`git checkout HEAD~1 -- hypr/` to restore the last working version.

## Keys

`Super` is the modifier; vim `hjkl` drives focus / move / resize. Full reference in-session:
**Super+Shift+/**.

| Key | Action |
|---|---|
| `Super+Return` / `Super+Space` | terminal / launcher |
| `Super+W` / `Super+Shift+W` | Zen / private window |
| `Super+N` / `Super+Y` | Obsidian / Thunar |
| `Super+V` | clipboard history |
| `Super+H/J/K/L` | focus (Shift = move; `Super+R` then hjkl = resize) |
| `Super+1–0` | workspaces (Shift = move window) |
| `Super+Shift+A` / `Super+Shift+F` | screenshot area / screen |
| `Super+Escape` / `Super+Shift+M` | lock / power menu |
| `Super+B` | hide / show the bar |

## Idle

```
10 min → lock (hyprlock)
15 min → monitor off
30 min → suspend
the Idle dropdown's Caffeine modes pause all three
```

## Customize

- **Monitors** — `hypr/monitors.lua`
- **Wallpaper** — `Super+Shift+I` (waypaper); lock and greeter follow it
- **Colours, radius, fonts** — `quickshell/Theme.qml` + `hypr/theme.lua` (see `AGENTS.md` for the other copies)
