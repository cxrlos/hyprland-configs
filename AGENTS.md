# hyprland-configs

Desktop-only Hyprland setup for Arch Linux. Keyboard-driven, tuned to a tmux + Neovim workflow.
`hypr/`, `waybar/`, etc. symlink into `~/.config/` via `scripts/install.sh` — edits are live after a reload.
Sibling repos: `../term-configs` (Alacritty, tmux, Zsh, Starship), `../neovim-configs` (Neovim).

## Stack

| Role | Tool |
|---|---|
| WM | Hyprland |
| Bar | Waybar (floating islands) |
| Launcher | rofi-wayland |
| Notifications | swaync |
| Wallpaper | waypaper + hyprpaper |
| Lock / Idle | hyprlock / hypridle |
| Screenshot | grimblast (grim+slurp fallback) |
| Clipboard | wl-clipboard + cliphist |
| Browser | Zen |
| Notes | Obsidian |
| File manager | Thunar (Super+Y) |
| Bluetooth | bluetui |
| System monitor | btop |
| Greeter | greetd + ReGreet (Catppuccin GTK) |
| Terminal / Shell / Editor | Alacritty / Zsh+Starship / Neovim (in sibling repos) |
| Colorscheme | Catppuccin Mocha |
| Font | Monaspace Nerd Font — Neon (`MonaspiceNe`) for UI and terminal |

## Key files

| File | Purpose |
|---|---|
| `hypr/hyprland.conf` | entry point — sources sub-configs (theme first), autostart, env, general/decoration/input/misc |
| `hypr/theme.conf` | **single source** of the Catppuccin palette + design tokens for the Hyprland side |
| `hypr/keybinds.conf` | all keybinds; `$browser` launches Zen (synced per account); reserved-prefix header |
| `hypr/rules.conf` | window rules (float/size/opacity tokens) + layer blur rules |
| `hypr/monitors.conf` | single ultrawide; edit for your hardware |
| `hypr/animations.conf` | Instant Pro profile (0ms) — zero compositor latency, instant window dispatch |
| `hypr/hyprlock.conf` / `hypridle.conf` | lock screen / idle (lock → DPMS off, no laptop dim/suspend) |
| `waybar/` | `config.jsonc` + `style.css` (unified edge-to-edge flat dark bar with CPU/RAM/GPU metrics) |
| `rofi/catppuccin.rasi` | launcher theme — the one file using named color vars; shared by every rofi call |
| `swaync/` | `config.json` + `style.css` |
| `gamemode.ini` | GameMode daemon profile (CPU performance governor, AMD high DPM, compositor blur bypass) |
| `scripts/scratch.sh` | parametrized create-or-toggle special-workspace scratchpad |
| `scripts/caffeine.sh` | idle inhibitor (pauses hypridle): off/on/`claude` modes (caffeine while any Claude session is mid-turn); bar click opens a rofi mode menu with Claude session counts; keybind toggles off/on; + waybar status JSON |
| `scripts/claude-busy.sh` | Claude Code hook (in `~/.claude/settings.json`) recording per-session busy state under `$XDG_RUNTIME_DIR/claude-busy/`; `count` answers for caffeine |
| `scripts/gpu-metrics.sh` | lightweight sysfs reader for AMD GPU core % and VRAM usage |
| `scripts/gamemode-start.sh` / `end.sh` | GameMode start/end hooks stripping/restoring compositor blur |
| `scripts/obsidian-capture.sh` | rofi prompt → new Obsidian note via `obsidian://` URI |
| `scripts/install.sh` | Arch installer + symlink setup; merges the Claude Code busy hooks into `~/.claude/settings.json` |
| `zen/` | tracked Zen layer — `user.js` (prefs) + `chrome/userChrome.css` (UI font); `install.sh` symlinks both into the launched profile resolved from `profiles.ini` |

## Conventions

- Hyprland config is split into sub-files sourced from `hyprland.conf`. **`theme.conf` is sourced first** so its `$vars` resolve in every later block and in `rules.conf`.
- **Design tokens live in `theme.conf`**: `$rounding`, `$gap_in/$gap_out`, `$glass`/`$glass_term` (window opacity), `$size_sm/md/lg` (scratchpad dimensions), the palette, and `$border_active/$border_inactive`. Reference these instead of literals in `hyprland.conf` / `rules.conf`.
- Layer-shell apps (waybar/rofi/swaync) and hyprlock are **separate processes** — they can't read `theme.conf`, so each keeps its own copy of the palette (raw hex; rofi uses named vars). Keep them in sync by hand on a theme change.
- Scripts are Bash, `set -euo pipefail`, ShellCheck-clean. New scripts need a manual `chmod +x` until the next `install.sh` run.
- `exec-once` does **not** re-run on `hyprctl reload` — scratchpads use create-or-toggle (`scratch.sh`) so they survive a reload without re-login.
- No GTK theme/font/cursor configs in the repo — `install.sh` writes them at deploy time.

## Workflow

**Theme / font swap**
1. `hypr/theme.conf` — palette + border vars (Hyprland side).
2. Raw hex in `waybar/style.css`, `swaync/style.css`, `thunar/gtk.css`, `hypr/hyprlock.conf`, and pango spans in `waybar/config.jsonc` + `scripts/cheatsheet.sh`. **Watch for** decimal-RGB forms (`rgba(30, 30, 46, …)`) and glass alphas (`…eb`, `0.92`) a hex find/replace will miss.
3. `rofi/catppuccin.rasi` — named-var block.
4. Fonts: `MonaspiceNe Nerd Font` in waybar/swaync/rofi/hyprlock + GTK (`install.sh`) + Zen (`zen/chrome/userChrome.css` for the UI, `zen/user.js` for monospace web content). The terminal font lives in `term-configs`.
5. `install.sh` — GTK theme name, cursor, font package.

**Add a scratchpad**
1. Keybind in `keybinds.conf` → `scratch.sh <name> <class> <cmd>`.
2. `windowrule` in `rules.conf`: `match:class`, `float = yes`, `size = $size_*`, `opacity = $glass_term`.
3. No `exec-once` needed — `scratch.sh` create-or-toggles.

**Add a keybind**
1. Respect the reserved prefixes below.
2. Add to `keybinds.conf`, then mirror it in `scripts/cheatsheet.sh`.

**Claude Code busy hooks** (caffeine's *Caffeine while Claude works* mode + menu session counts)
1. `install.sh` merges six hooks into `~/.claude/settings.json` via `jq`: idempotent, replaces any older `claude-busy.sh` entries, keeps every other setting/hook, backs the file up when it changes. The commands call `~/.config/scripts/claude-busy.sh`, so the `scripts/` symlink must exist.
2. Contract — `SessionStart` → `start` (idle); `UserPromptSubmit` + `PostToolUse` → `busy`; `Stop` → `stop`; `Notification` (matcher `permission_prompt|elicitation_dialog`, i.e. blocked on the user) → `idle`; `SessionEnd` → `end`. Each writes `$XDG_RUNTIME_DIR/claude-busy/<session_id>` as `<claude PID> <busy|idle>` (PID found by walking up the hook's parents); `end` deletes it.
3. **Background work** — `Stop` fires when the main turn ends even if background subagents, `run_in_background` shells or workflows are still going. Its payload lists them in `background_tasks` (`[{id, type: "subagent"|"shell"|…, status: "running"}]`), so `stop` stays `busy` while any is running. Each completion re-enters the session through `UserPromptSubmit`, and the next `Stop` re-evaluates. (Verified for subagents + shells; workflows are assumed to appear in `background_tasks` the same way.) Subagent tool calls fire `PostToolUse` with the parent's `session_id`. Don't count `SubagentStart`/`SubagentStop` — internal helpers emit `SubagentStop` with no matching start.
4. `claude-busy.sh count` prints `<busy> <open>` over files whose PID is still `claude`, pruning the rest (crashed sessions can't pin caffeine on). Open includes `--bg` background sessions; a session started before the hooks existed shows up at its first event.
5. Verify: `ls $XDG_RUNTIME_DIR/claude-busy` / `cat` a file mid-turn, or `~/.config/scripts/claude-busy.sh count`. Running sessions pick up new hooks on their own; if one doesn't, open `/hooks` in it once or restart it.

**Change Zen config**
1. Prefs → `zen/user.js` (verified `zen.*` keys live in `/opt/zen-browser-bin/browser/omni.ja`; restart Zen to apply).
2. UI font/CSS → `zen/chrome/userChrome.css` (needs `toolkit.legacyUserProfileCustomizations.stylesheets = true`, set in `user.js`).
3. Colours/theme → Zen **Mod** (UI/account-synced), not the repo. Accent is pinned to sky by `user.js`.

## Reserved keys

Never bind these at the WM level — they belong to the terminal stack:

| Chord | Owner |
|---|---|
| `` ` `` + any | tmux prefix |
| `Space` + any | nvim leader |
| `C-h/j/k/l` | vim ↔ tmux navigation |
| `SUPER` (`$mod`) | the WM modifier — everything in `keybinds.conf` |

Full keybind map: `hypr/keybinds.conf` or **Super+Shift+/** (cheatsheet).

## Known quirks (Hyprland 0.5x)

- **windowrule block syntax** — `name` must be first key; use `match:class` / `match:title`. Old inline `windowrule = …` syntax is gone.
- **layerrule block syntax** — `name` first, `match:namespace`, `blur = 1`. Layer blur needs `decoration { blur { enabled = true } }` **and** the layerrule.
- **Glass model** — tiled windows are opaque (`active/inactive_opacity = 1.0`). Translucency comes from per-app CSS/rasi alpha (waybar islands, rofi, swaync) + float opacity tokens (`$glass`/`$glass_term`). Blur only shows through translucent surfaces, so enabling it globally is free for tiled windows.
- **theme.conf ordering** — it must be sourced before `rules.conf` (it is) so `$size_*` / `$glass*` resolve there.
- **exec-once + reload** — not re-run on `hyprctl reload`; scratchpads use `scratch.sh`.
- **hyprpaper IPC** — preload is broken in 0.8.x; `wallpaper.sh` drives the `wallpaper` IPC verb directly.
- **Zen class** — Zen is Firefox-based and reports WM class `zen` (some builds `zen-alpha`/`zen-browser`); launched directly and routed to workspace 2 by the `zen-workspace` rule. Verify with `hyprctl clients | grep -i class` and adjust the rule if needed. The **declarative** layer (`zen/user.js` prefs + `chrome/userChrome.css` UI font) is tracked and symlinked into the launched profile — resolved from `~/.config/zen/profiles.ini` (`[Install*] Default=`), whose dir name is randomly hashed and may contain a space. The Catppuccin **Mod**, accent picker, extensions, bookmarks and passwords stay in Zen's per-account sync. Only `user.js` + `userChrome.css` are symlinked (single files) so the Mod-managed `chrome/zen-themes.css` is left intact. `user.js` is authoritative — it re-applies on every launch and overrides UI-set prefs.
- **GTK theme name** — `catppuccin-mocha-sky-standard+default`; the exact name varies by package version. `install.sh` warns and lists installed Catppuccin themes if it's missing.
- **Accent is sky** (`#89dceb`), unified across waybar/rofi/swaync/hyprlock/tmux/nvim. The active border is a sky→sapphire gradient animated by `borderangle`.
- **Waybar digit height** — at 11px MonaspiceNe's `1` hints a pixel taller than `0`; the bar uses **13px** where it grid-fits clean.
- **Apple emoji fontconfig** — `fontconfig/fonts.conf` adds Apple Color Emoji as a `<default>` (append) fallback, **not** `<prefer>` / `binding="strong"`: the emoji font also covers the ASCII digits 0-9 and will hijack them otherwise (mismatched glyph heights).
- **iwd vs NetworkManager** — never run an iwd tool (e.g. impala) alongside NetworkManager; both grab the wifi device and break auto-connect. `install.sh` masks iwd; the waybar wifi click uses `nmtui`.
- **Claude busy gap** — after a permission prompt is approved, that session reads idle until the tool (or its next tool call) finishes; no hook fires in between. If every session is idle at a 10s watcher tick, *Caffeine while Claude works* ends and hypridle restarts with a fresh timeout.
- **Greeter session list** — `install.sh` removes `hyprland-uwsm.desktop` so only plain Hyprland shows in ReGreet; it returns on a `hyprland` package update (re-run install). The greeter background is the tracked `assets/greeter-bg.jpg`, independent of the waypaper desktop wallpaper.

## Debugging

1. **Reload** — `hyprctl reload` (config) and `killall waybar && waybar &` (bar). `exec-once` won't re-run.
2. **Config errors** — surface in the `hyprctl reload` output and as on-screen notifications.
3. **Window rules** — `hyprctl clients -j | grep -i class` to get the real class/title to match on.
4. **Layers / blur** — `hyprctl layers` lists layer-shell namespaces (waybar, rofi, swaync…).
5. **Logs** — `hyprctl rollinglog`, or `$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/hyprland.log`.
6. **Waybar** — run `waybar` in a terminal to see CSS/JSON parse errors live.

## Related repos

- `term-configs/` — Alacritty, tmux, Zsh, Starship
- `neovim-configs/` — Neovim
