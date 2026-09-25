# hyprland-configs

Desktop-only Hyprland setup for Arch Linux. Keyboard-driven, tuned to a tmux + Neovim workflow.
`hypr/`, `waybar/`, etc. symlink into `~/.config/` via `scripts/install.sh` — edits are live after a reload.
Sibling repos: `../term-configs` (Alacritty, tmux, Zsh, Starship), `../neovim-configs` (Neovim).

## Stack

| Role | Tool |
|---|---|
| WM | Hyprland (Lua config) |
| Bar | Waybar (transparent bar, translucent chips) |
| Launcher | rofi-wayland |
| Notifications | swaync |
| Wallpaper | waypaper + hyprpaper |
| Lock / Idle | hyprlock / hypridle |
| Screenshot / Recording | grimblast (grim+slurp fallback) / wf-recorder |
| Clipboard | wl-clipboard + cliphist |
| Browser | Zen (`zen-browser`, AUR `zen-browser-bin`) |
| Notes | Obsidian |
| File manager | Thunar (Super+Y) |
| Bluetooth | bluetui |
| System monitor | btop |
| Greeter | greetd + ReGreet (Gruvbox CSS written by `install.sh`) |
| Terminal / Shell / Editor | Alacritty / Zsh+Starship / Neovim (in sibling repos) |
| Colorscheme | Gruvbox dark, accent aqua `#8ec07c` (cursor is Catppuccin, see quirks) |
| Font | Mononoki Nerd Font (waybar uses `Mononoki Nerd Font Mono`) |

## Key files

| File | Purpose |
|---|---|
| `hypr/hyprland.lua` | entry point — `require`s theme, monitors, animations, keybinds, rules; autostart via `hl.on("hyprland.start", …)`, env, `hl.config` |
| `hypr/theme.lua` | returns border colours, gaps, rounding and `size_sm/md/lg` scratchpad sizes; `require("theme")` in `hyprland.lua` + `rules.lua` |
| `hypr/keybinds.lua` | all binds + resize/system submaps; `browser` launches `zen-browser`; reserved-prefix header |
| `hypr/rules.lua` | `hl.window_rule{ name=…, match={class=…} }` — scratchpad floats, Obsidian → workspace 2, PiP, game tearing/no-anim |
| `hypr/monitors.lua` | single 2560x1080 ultrawide on HDMI-A-1; edit for your hardware |
| `hypr/animations.lua` | quick fades + 95% popin for windows open/close; move, workspace and border animations off |
| `hypr/hyprlock.conf` / `hypridle.conf` | lock screen / idle (10 min lock → 15 min DPMS off → 30 min suspend; caffeine stops hypridle, so it blocks all three) |
| `hypr/hyprpaper.conf` | splash off + IPC on only; the wallpaper is set by `wallpaper.sh` |
| `waybar/` | workspaces + window title left; clock, CPU/RAM/GPU, updates, audio (→ wiremix scratchpad), mpris, network (→ nmtui), caffeine, swaync, tray, power right |
| `rofi/gruvbox.rasi` | launcher theme — the one file using named colour vars; shared by every rofi call |
| `swaync/` | `config.json` + `style.css`; D-Bus-activated, not autostarted |
| `thunar/` | → `~/.config/Thunar` (details view, "Open Terminal Here" action, accels) |
| `fontconfig/fonts.conf` | Apple Color Emoji fallback (see quirks) |
| `waypaper/config.ini` | picked wallpaper; `post_command` runs `wallpaper.sh` |
| `gamemode.ini` | performance governor + renice/ioprio; renice needs `gamemode` group membership and `[gpu]` only applies from a root-owned `/etc/gamemode.ini` (see file header) |
| `udev/` | 8BitDo HID/xpad rules; `install.sh` copies them to `/etc/udev/rules.d/` (root-owned, not linked) and reloads udev |
| `scripts/scratch.sh` | parametrized create-or-toggle special-workspace scratchpad |
| `scripts/focus-or-spawn.sh` | focus a window by class or spawn it (Obsidian, Super+N) |
| `scripts/screenshot.sh` | area/screen capture → rofi Copy/Save menu (`~/Pictures/screenshots`); linked as `~/.local/bin/screenshot` |
| `scripts/record.sh` | wf-recorder region toggle → `~/Videos` |
| `scripts/clipboard.sh` | cliphist picker in rofi |
| `scripts/power.sh` | rofi lock/suspend/reboot/shutdown menu (Super+Shift+M, bar power button) |
| `scripts/wallpaper.sh` | applies waypaper's pick via hyprpaper IPC (autostart + waypaper `post_command`) |
| `scripts/cheatsheet.sh` | hand-maintained rofi keybind list (Super+Shift+/) |
| `scripts/steam.sh` | Steam with `SDL_VIDEODRIVER=x11` so games detect the real resolution; linked as `~/.local/bin/steam` |
| `scripts/gpu-metrics.sh` / `mpris-status.sh` / `updates-count.sh` | waybar JSON: AMD GPU %/VRAM (sysfs), now playing (playerctl), official-repo update count (`checkupdates`; click runs `yay`) |
| `scripts/caffeine.sh` | idle inhibitor (pauses hypridle): off/on/`claude` modes (caffeine while any Claude session is mid-turn); bar click opens a rofi mode menu with Claude session counts; keybind toggles off/on; + waybar status JSON |
| `scripts/claude-busy.sh` | Claude Code hook (in `~/.claude/settings.json`) recording per-session busy state under `$XDG_RUNTIME_DIR/claude-busy/`; `count` answers for caffeine |
| `scripts/gamemode-start.sh` / `end.sh` | GameMode `[custom]` hooks; only send a notification |
| `scripts/obsidian-capture.sh` | rofi prompt → new Obsidian note via `obsidian://` URI |
| `scripts/install.sh` | Arch installer + symlink setup; merges the Claude Code busy hooks into `~/.claude/settings.json` |
| `.tmux-sessionizer` | tmux layout for this repo (nvim, claude, shell, Hyprland log tail) |

## Conventions

- Hyprland config is **Lua**: `hyprland.lua` `require`s the sub-modules. The `hl` API (config keys, dispatchers, rule fields, events) is typed in `/usr/share/hypr/stubs/hl.meta.lua` — check it instead of guessing. `hypridle`, `hyprlock` and `hyprpaper` are separate programs and stay hyprlang `.conf`.
- **Layout tokens live in `theme.lua`** (`gap_in/gap_out`, `rounding`, `size_*`, `border_active/inactive`). Reference `theme.*` instead of literals in `hyprland.lua` / `rules.lua`.
- waybar, rofi, swaync, hyprlock and regreet are **separate processes** — each keeps its own copy of the Gruvbox palette (raw hex; rofi uses named vars). Keep them in sync by hand on a theme change.
- Scripts are Bash, `set -euo pipefail`, ShellCheck-clean. New scripts need a manual `chmod +x` until the next `install.sh` run.
- The `hyprland.start` autostart does **not** re-run on `hyprctl reload` — scratchpads use create-or-toggle (`scratch.sh`) so they survive a reload without re-login.
- No GTK configs in the repo — `install.sh` writes `gtk-{3,4}.0/settings.ini` (Papirus-Dark icons, font, cursor, prefer-dark; no GTK theme) at deploy time.

## Workflow

**Theme / font swap**
1. `hypr/theme.lua` — border colours only (Hyprland side).
2. Raw hex in `waybar/style.css`, `swaync/style.css`, `hypr/hyprlock.conf`, the `regreet.css` heredoc in `install.sh`, and the rofi `-theme-str` in `scripts/caffeine.sh`. **Watch for** decimal-RGB forms (`rgba(60, 56, 54, 0.6)`) and hyprlang `rgb(ebdbb2)` that a `#hex` find/replace will miss.
3. `rofi/gruvbox.rasi` — named-var block. Renaming the file means updating every `gruvbox.rasi` path (`keybinds.lua` + scripts).
4. Fonts: `Mononoki Nerd Font` in swaync/rofi/hyprlock + GTK settings and `regreet.toml` (`install.sh`); waybar uses the `Mono` variant. `install.sh` also names the font package (`ttf-mononoki-nerd`) and its `fc-list` check. The terminal font lives in `term-configs`.

**Add a scratchpad**
1. Keybind in `keybinds.lua` → `scratch.sh <name> <class> <cmd>`.
2. `hl.window_rule` in `rules.lua`: `match = { class = … }`, `float = true`, `size = theme.size_*`, `center = true`.
3. No autostart needed — `scratch.sh` create-or-toggles.

**Add a keybind**
1. Respect the reserved prefixes below.
2. Add to `keybinds.lua`, then mirror it in `scripts/cheatsheet.sh`.

**Claude Code busy hooks** (caffeine's *Caffeine while Claude works* mode + menu session counts)
1. `install.sh` merges six hooks into `~/.claude/settings.json` via `jq`: idempotent, replaces any older `claude-busy.sh` entries, keeps every other setting/hook, backs the file up when it changes. The commands call `~/.config/scripts/claude-busy.sh`, so the `scripts/` symlink must exist.
2. Contract — `SessionStart` → `start` (idle); `UserPromptSubmit` + `PostToolUse` → `busy`; `Stop` → `stop`; `Notification` (matcher `permission_prompt|elicitation_dialog`, i.e. blocked on the user) → `idle`; `SessionEnd` → `end`. Each writes `$XDG_RUNTIME_DIR/claude-busy/<session_id>` as `<claude PID> <busy|idle>` (PID found by walking up the hook's parents); `end` deletes it.
3. **Background work** — `Stop` fires when the main turn ends even if background subagents, `run_in_background` shells or workflows are still going. Its payload lists them in `background_tasks` (`[{id, type: "subagent"|"shell"|…, status: "running"}]`), so `stop` stays `busy` while any is running. Each completion re-enters the session through `UserPromptSubmit`, and the next `Stop` re-evaluates. (Verified for subagents + shells; workflows are assumed to appear in `background_tasks` the same way.) Subagent tool calls fire `PostToolUse` with the parent's `session_id`. Don't count `SubagentStart`/`SubagentStop` — internal helpers emit `SubagentStop` with no matching start.
4. `claude-busy.sh count` prints `<busy> <open>` over files whose PID is still `claude`, pruning the rest (crashed sessions can't pin caffeine on). Open includes `--bg` background sessions; a session started before the hooks existed shows up at its first event.
5. Verify: `ls $XDG_RUNTIME_DIR/claude-busy` / `cat` a file mid-turn, or `~/.config/scripts/claude-busy.sh count`. Running sessions pick up new hooks on their own; if one doesn't, open `/hooks` in it once or restart it.

## Reserved keys

Never bind these at the WM level — they belong to the terminal stack:

| Chord | Owner |
|---|---|
| `` ` `` + any | tmux prefix |
| `Space` + any | nvim leader |
| `C-h/j/k/l` | vim ↔ tmux navigation |
| `SUPER` (`mod`) | the WM modifier — everything in `keybinds.lua` |

Full keybind map: `hypr/keybinds.lua` or **Super+Shift+/** (cheatsheet).

## Known quirks (Hyprland 0.56, Lua config)

- **Auto-leaving submaps** — `hl.define_submap(name, "reset", fn)` leaves the submap after any bind in it fires. The system submap (Super+S → L/R/P/U) uses it so a stray key after unlock or resume can't reboot; the resize submap (Super+R) stays until Esc/Return.
- **Suspend** — idle policy is hypridle-owned (`loginctl lock-session` → DPMS off → `systemctl suspend`; `inhibit_sleep = 3` holds sleep until the lock is confirmed); logind `IdleAction` stays `ignore`. Manual suspend (Super+S → U, `power.sh`) runs `sleep 1 && systemctl suspend` because the key release otherwise wakes the PC via the USB keyboard's wake.
- **Opaque, no blur** — windows are opaque, `decoration.blur` and shadows are off. Translucency is only per-app CSS alpha (waybar chips, hyprlock chip).
- **Borders** — active border is solid `#ebdbb2`, inactive `#504945`; no gradient, border animations off.
- **Cursor** — the one intentional Catppuccin item: the Catppuccin Mocha Dark cursor (name set in `hyprland.lua` `XCURSOR_THEME`, also in the GTK settings and `regreet.toml`) from AUR `catppuccin-cursors-mocha`. `install.sh` also installs `bibata-cursor-theme-bin` and writes `~/.local/share/icons/default/index.theme` with `Inherits=Bibata-Modern-Classic`, so XCursor falls back to Bibata if the Catppuccin theme is missing.
- **hyprpaper IPC** — preload is broken in 0.8.x; `wallpaper.sh` drives the `wallpaper` IPC verb directly.
- **Zen class** — reports WM class `zen`; no window rule targets it. Prefs, theme and extensions live in Zen's own profile/sync, not this repo.
- **Mouse** — no mouse tuning anywhere (no logiops, udev, `hl.device` or `input` sensitivity/accel/scroll overrides): libinput defaults, and the kernel `hid-logitech-hidpp` driver owns hi-res scroll. logid re-applying hires on every mouse wake raced the kernel and flipped scroll speed ~8x.
- **Microcode** — `install.sh` installs `intel-ucode` or `amd-ucode` from `/proc/cpuinfo`'s vendor and warns if no systemd-boot entry loads it; it never edits the boot entries. (This box once booted AMD microcode on an Intel i5-12400F.)
- **Apple emoji fontconfig** — `fontconfig/fonts.conf` adds Apple Color Emoji as a `<default>` (append) fallback, **not** `<prefer>` / `binding="strong"`: the emoji font also covers the ASCII digits 0-9 and will hijack them otherwise (mismatched glyph heights).
- **iwd vs NetworkManager** — never run an iwd tool (e.g. impala) alongside NetworkManager; both grab the wifi device and break auto-connect. `install.sh` masks iwd; the waybar wifi click uses `nmtui`.
- **Claude busy gap** — after a permission prompt is approved, that session reads idle until the tool (or its next tool call) finishes; no hook fires in between. If every session is idle at a 10s watcher tick, *Caffeine while Claude works* ends and hypridle restarts with a fresh timeout.
- **Greeter session list** — `install.sh` removes `hyprland-uwsm.desktop` so only plain Hyprland shows in ReGreet; it returns on a `hyprland` package update (re-run install). The greeter has no background image (`regreet.toml` `path = ""`), just the `regreet.css` base colour.

## Debugging

1. **Reload** — `hyprctl reload` (config) and `killall waybar && waybar &` (bar). The `hyprland.start` autostart won't re-run.
2. **Config errors** — surface in the `hyprctl reload` output and as on-screen notifications.
3. **Window rules** — `hyprctl clients -j | grep -i class` to get the real class/title to match on.
4. **Layers** — `hyprctl layers` lists layer-shell namespaces (waybar, rofi, swaync…).
5. **Logs** — `hyprctl rollinglog`, or `$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/hyprland.log`.
6. **Waybar** — run `waybar` in a terminal to see CSS/JSON parse errors live.

## Related repos

- `term-configs/` — Alacritty, tmux, Zsh, Starship
- `neovim-configs/` — Neovim
