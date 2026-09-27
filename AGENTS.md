# hyprland-configs

Hyprland setup for Arch Linux on a desktop and a laptop, used for client presentations as well as daily work.
Two visual layers: the **terminal** (Alacritty/tmux/Neovim, in the sibling repos) keeps Gruvbox + Mononoki;
the **chrome** (bar, dropdowns, panels, launcher, overview, notifications, lock, greeter, window frames) is a
neutral macOS-like frosted dark with a sage accent. Keyboard-driven, tuned to a tmux + Neovim workflow.
Config dirs symlink into `~/.config/` via `scripts/install.sh`, so edits are live after a reload.
Sibling repos: `../term-configs` (Alacritty, tmux, Zsh, Starship), `../neovim-configs` (Neovim).

## Stack

| Role | Tool |
|---|---|
| WM | Hyprland 0.56 (Lua config) |
| Bar, dropdowns, panels | Quickshell 0.3 (QML) — replaced waybar |
| Launcher / window switcher / overview | Quickshell panels (rofi retired) |
| Calendar | secret iCal feeds or gcalcli (Calendar API, when Workspace disables secret addresses) → `scripts/calendar-feed.py` (Python: icalendar, recurring-ical-events) |
| Notifications | swaync (its own default theme, retuned) |
| Wallpaper | waypaper + hyprpaper |
| Lock / Idle | hyprlock / hypridle |
| Greeter | greetd + ReGreet |
| Screenshot / Recording | grimblast (grim+slurp fallback) / wf-recorder |
| Clipboard | wl-clipboard + cliphist |
| Browser / Notes / Files | Zen (`zen-browser`) / Obsidian / Thunar |
| UI font / icons / cursor | Inter / Material Symbols Rounded / Bibata Modern Classic |

## Desktop and laptop

One config for both machines; laptop pieces detect their hardware and stay inert on the desktop:

- Bar: `BrightnessStatus` shows only when `brightnessctl` finds a backlight; `Battery` only for a UPower laptop battery (its dropdown, with power modes, is created only then).
- Keys: `XF86MonBrightness*` → `qs ipc call brightness up|down` (+ OSD).
- Input: `input.touchpad` (natural scroll, tap, disable-while-typing) and a 3-finger workspace swipe; mice keep libinput defaults.
- Idle: extra hypridle listeners gated by `scripts/on-battery.sh` (dim 4 min, lock 5, screen off 7, suspend 15). Lid close is logind's default suspend, locked first by hypridle's `before_sleep_cmd`.
- Monitors: `HDMI-A-1` is pinned for the desktop; every other output (laptop panel, projector) takes its preferred mode.
- Install: `install.sh` sets `IS_LAPTOP` from `/sys/class/power_supply/BAT*` and adds `brightnessctl upower power-profiles-daemon` (enabled).

## Chrome palette

Every chrome surface shares these values (the terminal palette lives in `term-configs`):

| Token | Value |
|---|---|
| surface (bar) | `rgba(30,30,33,0.58)` + Hyprland layer blur |
| elevated (dropdowns, panels, swaync) | `rgba(36,36,40,0.72)` + blur |
| rim / hairline | `white/12%` / `white/8%` |
| text / secondary / tertiary | `white/90%` / `rgba(235,235,245,.6)` / `rgba(235,235,245,.32)` |
| accent / text on accent | sage `#83a598` (the wallpaper's circle, also Gruvbox blue) / `#1d2021` |
| critical | `#ff6961` |

Radius: 10 windows, 6 bar pills, 8 rows/fields, 14 panels, full for pills. Blur never applies to
windows except translucent Alacritty; windows stay opaque, inactive ones dimmed 12%.

## Design principles

The choices every surface follows; a new one earns its place by fitting all of them.

- **Calm by default.** The bar shows what needs attention now and nothing else: metrics live in the
  System dropdown, and the meeting chip appears only in the hour before a meeting.
- **Sage means act.** The accent marks the selected row, the thing about to happen (a meeting 5
  minutes out) and primary buttons. Everything else is neutral text on frosted surfaces.
- **One surface language.** Elevated frosted panel, hairline rim, the radii above, Inter, Material
  Symbols Rounded. Other apps come to the chrome (swaync, the greeter, Zen), never the reverse.
- **Presentation-safe.** Anything private (track titles, meeting titles) hides while
  `ScreenShare.active`; the screen is shown to clients.
- **Keyboard first.** Every surface has a `SUPER` bind, an IPC target, and closes on Esc or an
  outside click.
- **Present only when the data is.** Laptop items, calendars and vault notes appear when their
  hardware or data exists, so one config serves every machine.
- **Credentials stay local.** Secrets live in `~/.config` files that `install.sh` writes once from a
  tracked template (chmod 600); the repo holds only the template.

## Layout

| Path | Purpose |
|---|---|
| `hypr/hyprland.lua` | entry point: `require`s theme, monitors, animations, keybinds, rules; autostart (`qs`, wallpaper, cliphist, polkit, hypridle); env; `hl.config` |
| `hypr/theme.lua` | Hyprland-side tokens: borders, shadow, dim, gaps, rounding, `size_*` scratchpad sizes |
| `hypr/rules.lua` | window rules + the **layer blur rules** (`quickshell-bar`, `quickshell-panel`, `swaync-*`) |
| `hypr/hyprlock.conf` / `hypridle.conf` | lock screen / idle (10 min lock → 15 min DPMS off → 30 min suspend) |
| `quickshell/Theme.qml` | chrome tokens for every QML surface (single source inside Quickshell) |
| `quickshell/bar/` | the menu-bar strip; one file per item, each owning its dropdown |
| `quickshell/dropdowns/` | Sound, Wi-Fi, Bluetooth, Idle, Power, Calendar, Media, System |
| `quickshell/panels/` | centred Spotlight-style panels: Launcher, Clipboard, Cheatsheet; full-screen Overview |
| `quickshell/osd/` | volume / mic / brightness level pill for the keys (click-through) |
| `quickshell/widgets/` | shared parts: `Dropdown`, `DropdownState`, `MenuRow`, `Slider`, `Switch`, `PillButton`…; `ScreenShare` (screen-share guard); `Agenda` (today's calendar events, live) |
| `swaync/style.css` | `@import`s swaync's default theme and overrides its CSS variables |
| `zen/userChrome.css` / `userContent.css` / `user.js` | Zen's UI / its `about:` pages (new tab, settings, add-ons; never `about:blank`, which sites use) in the chrome tokens, + the prefs they need; `install.sh` links all three into Zen's default profile |
| `scripts/install.sh` | Arch installer: packages, symlinks, Zen profile links, `calendars.yaml` template, GTK settings + `gtk.css`, gsettings, greetd/ReGreet (config + CSS heredocs), udev, Claude hooks |
| `scripts/wallpaper.sh` | applies waypaper's pick via hyprpaper IPC; publishes it for the lock (`~/.cache/wallpaper/current`) and a pre-blurred copy for the greeter (`/usr/local/share/greeter/background.jpg`) |
| `scripts/calendar-feed.py` | `[--offline] [START [DAYS]]` → events from `~/.config/calendars.yaml` (iCal or gcalcli sources) as JSON (default today; cached per calendar, declined/cancelled dropped, failures named on stderr) |
| `scripts/notes.sh` | note titles from every Obsidian vault (`~/.config/obsidian/obsidian.json`) as JSON for the launcher |
| `scripts/calendars.example.yaml` | template `install.sh` copies to `~/.config/calendars.yaml` (chmod 600) |
| `scripts/system-status.sh` | CPU/RAM/GPU/update-count JSON for the System item |
| `scripts/caffeine.sh` | idle modes `off|on|claude` + `status`; refreshes the bar via `qs ipc call caffeine refresh` |
| `scripts/claude-busy.sh` | Claude Code hook recording per-session busy state; `count` feeds the Idle dropdown |
| `scripts/clipboard.sh` | `list` (JSON, image previews cached) / `copy <id>` for the Clipboard panel |
| `scripts/on-battery.sh` | exits 0 only on a laptop running on battery (gates the battery idle listeners) |
| `scripts/screenshot.sh` | capture → copy → notification with Save / Edit (satty) / Open |
| `scripts/compact-workspaces.sh` | renumbers occupied workspaces to 1..N (no gaps); run by `bar/WorkspaceCompactor.qml` |
| `scripts/scratch.sh` / `focus-or-spawn.sh` | create-or-toggle scratchpad / focus-or-launch (Obsidian) |

## Conventions

- Hyprland config is **Lua**. The `hl` API is typed in `/usr/share/hypr/stubs/hl.meta.lua`; check it instead of guessing. hypridle, hyprlock and hyprpaper stay hyprlang `.conf`.
- **`hyprctl dispatch` takes Lua** (`hyprctl dispatch 'hl.dsp.focus({ workspace = "2" })'`), so every script and `.conf` that dispatches uses that form. `scratch.sh`/`focus-or-spawn.sh` show the quoting helper. Hyprland's own `/usr/share/hypr/hypridle.conf` is a reference for syntax.
- Chrome tokens: Hyprland reads `theme.lua`, Quickshell reads `Theme.qml`; swaync, hyprlock, the greeter and Zen (`--hc-*` in `zen/userChrome.css` and `userContent.css`) are separate processes with their own copies. Change a token in all of them together.
- Quickshell hot-reloads on save; a half-written file pops its error overlay. It misses in-place rewrites (`sed -i`), branch switches and new files in a module dir: restart it (`pkill -x qs; setsid -f qs`) and check `qs log`. Singletons use `pragma Singleton`; modules import as `qs.bar`, `qs.widgets`, etc.
- Keyboard entry points into Quickshell go through IPC (`qs ipc call dropdown toggle power`, `qs ipc call panel toggle launcher|overview|clipboard|cheatsheet`, `qs ipc call bar toggle`); `qs ipc show` lists targets.
- Scripts are Bash, `set -euo pipefail`, ShellCheck-clean (`uvx --from shellcheck-py shellcheck -x scripts/*.sh`), except `calendar-feed.py` (Python, Black) because ICS recurrence needs a real parser; a Python script's name must not shadow a stdlib module (`calendar.py` broke `dateutil`). New scripts need `chmod +x` until the next `install.sh` run.
- Every config must be reproducible from `install.sh`: a new package, a file outside the symlinked dirs or an app pref ships with its install step in the same change.
- The `hyprland.start` autostart does not re-run on `hyprctl reload`; restart Quickshell with `pkill -x qs; setsid -f qs`.
- GTK settings, `gtk.css` and the greeter config are written by `install.sh`, not symlinked.

## Workflow

**New chrome idea** (prototype, test-and-pick, promote): follow `docs/agents/iterating.md`.

**Change a chrome token (colour, font, radius)**
1. `quickshell/Theme.qml` and `hypr/theme.lua`.
2. `swaync/style.css` variables, `zen/userChrome.css` + `userContent.css` `--hc-*` (restart Zen), `hypr/hyprlock.conf` (hyprlang `rgba(rrggbbaa)`), and the `regreet.css`/`regreet.toml` heredocs in `install.sh`.
3. Fonts also live in the GTK settings + gsettings block of `install.sh` and its package list.

**Add a bar item with a dropdown**
1. `quickshell/dropdowns/XDropdown.qml`: root `Dropdown { name: "x" }`, content built from `widgets/`.
2. `quickshell/bar/X.qml`: a `BarIcon` with `highlighted: menu.shown`, `onClicked: DropdownState.toggle("x")`, and the dropdown as a child with `anchorItem: root`.
3. Add it to the right-side `RowLayout` in `bar/Bar.qml`.

**Add a keybind**
1. Respect the reserved prefixes below.
2. Add to `hypr/keybinds.lua`, then mirror it in `quickshell/panels/Cheatsheet.qml`.

**Add a scratchpad**
1. Keybind → `scratch.sh <name> <class> <cmd>`.
2. `hl.window_rule` in `rules.lua` with `float`, `size = theme.size_*`, `center`.

**Add or change a calendar**
1. Edit `~/.config/calendars.yaml` (not in the repo: secret iCal URLs are credentials). Each calendar has a `name`, a `style` and one source: `url:` (Google's "Secret address in iCal format", or any `.ics`) or `gcalcli: <calendar id>` (one-time `gcalcli init` with the user's own Desktop OAuth client; the template's header has the steps). Share (`?cid=`) and embed links need a signed-in browser, so the feed reports them.
2. Styles map to a colour and `bar: true|false` (whether its timed events count as meetings for the chip beside the clock). Built-ins live in `DEFAULT_STYLES` in `calendar-feed.py`: work (sage, bar), personal, events, sports, family, other; the YAML's `styles:` overrides or adds.
3. `Agenda` reruns the feed every 5 minutes (network), or now with `qs ipc call agenda refresh`; the Calendar dropdown reads other days with `--offline` from that cache. Check it with `~/.config/scripts/calendar-feed.py | jq` (stderr names any calendar that returned no iCal, e.g. a share link).

**Claude Code busy hooks** (the Idle dropdown's *Caffeine while Claude works* + session counts)
1. `install.sh` merges six hooks into `~/.claude/settings.json` via `jq`: idempotent, replaces older `claude-busy.sh` entries, keeps every other setting, backs the file up when it changes. They call `~/.config/scripts/claude-busy.sh`, so the `scripts/` symlink must exist.
2. Contract — `SessionStart` → `start` (idle); `UserPromptSubmit` + `PostToolUse` → `busy`; `Stop` → `stop`; `Notification` (matcher `permission_prompt|elicitation_dialog`) → `idle`; `SessionEnd` → `end`. Each writes `$XDG_RUNTIME_DIR/claude-busy/<session_id>` as `<claude PID> <busy|idle>`; `end` deletes it.
3. **Background work** — `Stop` fires when the main turn ends even if background subagents, shells or workflows still run; its payload lists them in `background_tasks`, so `stop` stays `busy` while any is running. Each completion re-enters through `UserPromptSubmit`. Subagent tool calls fire `PostToolUse` with the parent's `session_id`. `SubagentStart`/`SubagentStop` are unreliable (unmatched stops) and unused.
4. `claude-busy.sh count` prints `<busy> <open>` over files whose PID is still `claude`, pruning the rest.
5. Verify: `ls $XDG_RUNTIME_DIR/claude-busy`, or `~/.config/scripts/claude-busy.sh count`.

## Reserved keys

These belong to the terminal stack; WM binds live only under `SUPER`:

| Chord | Owner |
|---|---|
| `` ` `` + any | tmux prefix |
| `Space` + any | nvim leader |
| `C-h/j/k/l` | vim ↔ tmux navigation |

Full map: `hypr/keybinds.lua`, or **Super+Shift+/** in-session.

## Known quirks

- **Dropdown dismissal** — dropdowns are `PopupWindow`s with `grabFocus`; an outside click closes them and then lands on the bar, so `DropdownState` ignores a reopen of the same dropdown within 300 ms. Switching dropdowns closes the old one before mapping the next (two grabs at once confuse Wayland).
- **Screen-share guard** — Hyprland's `screencast` event fires for screenshots too (grim, for a split second), so `ScreenShare` engages only after 1.5 s of continuous capture; it turns Do Not Disturb on (and back off only if it was the one to turn it on) and hides the bar's now-playing text.
- **Workspace compaction** — the bar shows unnumbered dots, so gaps are closed: on `destroyworkspacev2` (an empty workspace you just left) later workspaces shift left. Super+1–0 address slots, not fixed contents, and no window rule pins an app to a workspace number. The focused workspace counts as occupied, so nothing slides onto the current screen.
- **Tray clicks** — tray item ids are matched to windows by their leading word (`Slack_status_icon_1` → app id `slack`); no window means the app is opened on an empty workspace.
- **Tray menus** — native right-click menus need `//@ pragma UseQApplication` at the top of `shell.qml`.
- **Panels take the keyboard** — Clipboard/Cheatsheet are overlay layers with exclusive keyboard focus while open; opening one from a script steals whatever you were typing.
- **QML naming** — a property named `on` + capital (e.g. `onAccent`) is parsed as a signal handler, `escape` is not a valid signal name, and `font.pixelSize` must be an integer.
- **ReGreet styling** — GTK 4.22's built-in theme paints buttons with a `background-image` gradient, so the greeter CSS sets `background-image: none` before any button colour. Preview it without logging out: `regreet --demo -l /tmp/regreet.log -c <toml> -s <css>`.
- **Greeter background** — ReGreet can't blur and runs as the `greeter` user, so `wallpaper.sh` renders a blurred, dimmed copy into `/usr/local/share/greeter/` (owned by the user, created by `install.sh`).
- **Suspend** — idle policy is hypridle-owned (`inhibit_sleep = 3` holds sleep until the lock is confirmed); logind `IdleAction` stays `ignore`. Manual suspend runs `sleep 1 && systemctl suspend` so the click/key release can't wake the PC via USB.
- **hyprpaper IPC** — preload is broken in 0.8.x; `wallpaper.sh` drives the `wallpaper` IPC verb directly.
- **Mouse** — libinput defaults only; the kernel `hid-logitech-hidpp` driver owns hi-res scroll (logid raced it and flipped scroll speed ~8x).
- **Microcode** — `install.sh` installs `intel-ucode`/`amd-ucode` from `/proc/cpuinfo` and warns if no systemd-boot entry loads it; it never edits boot entries.
- **Apple emoji fontconfig** — Apple Color Emoji is a `<default>` (append) fallback only; as `<prefer>` it hijacks ASCII digits.
- **iwd vs NetworkManager** — NetworkManager owns wifi; `install.sh` masks iwd, and iwd tools (impala) break auto-connect.
- **Claude busy gap** — after a permission prompt is approved, that session reads idle until the tool finishes; if every session is idle at a 10 s watcher tick, the Claude caffeine mode ends.
- **Greeter session list** — `install.sh` removes `hyprland-uwsm.desktop`; it returns on a `hyprland` package update (re-run install).
- **Next meeting chip** — shows only within the hour before a `bar: true` meeting, turns sage 5 minutes out (a click then joins the Meet/Zoom/Teams link) and hides while the screen-share guard is on.
- **Overview thumbnails** — `ScreencopyView` captures only while the overview is open; window positions come from `lastIpcObject`, refreshed on open.
- **Zen theme** — Zen reads `userChrome.css` only at startup (restart it after edits). `userContent.css` reaches `about:` pages only through design tokens, so a Firefox token rename breaks it quietly; Zen's settings buttons keep its own grey, and private windows share the normal colours. Zen's own accent pref is blended toward black, so the CSS sets colours directly; a Zen update that renames its `--zen-*` variables is the likely breakage.
- **Zen class** — reports WM class `zen`; the bar shows only "Zen", never page titles.

## Debugging

1. **Reload** — `hyprctl reload`; Quickshell reloads itself on save (`pkill -x qs; setsid -f qs` for a clean start).
2. **Config errors** — `hyprctl configerrors`; Quickshell: `qs log` (filter out `INFO`).
3. **Window rules** — `hyprctl clients -j` for the real class/title.
4. **Layers** — `hyprctl layers` lists namespaces (`quickshell-bar`, `quickshell-panel`, `swaync-*`).
5. **Hyprland logs** — `hyprctl rollinglog`.
