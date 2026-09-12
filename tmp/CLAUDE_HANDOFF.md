# DELETE ME WHEN DONE

This file is scratch, not meant to live in history. When you're done with this
debugging session: `git rm tmp/CLAUDE_HANDOFF.md` (or `rm -rf tmp/`), commit,
then scrub it from git history entirely — it was pushed to
github.com/cxrlos/hyprland-configs so a plain delete-commit isn't enough:

```bash
git filter-repo --path tmp/CLAUDE_HANDOFF.md --invert-paths --force
git push origin --force --all
```

(Requires `git-filter-repo`; `brew install git-filter-repo` / `pacman -S git-filter-repo`.)
Force-pushing rewrites remote history — fine for a personal dotfiles repo, but
don't do this if anyone else has cloned it without knowing.

---

## Prompt to paste into Claude on this machine

> This repo just migrated its Hyprland config from classic hyprlang
> (`.conf`) to the new Lua config API (`hl.*` functions, see
> `hypr/*.lua`). Read `tmp/CLAUDE_HANDOFF.md` in full for context on what
> was already fixed and what's still broken, then help me debug the
> waybar issue described below. Ground-truth the Lua API against the
> actual Hyprland C++ source (`hyprwm/Hyprland` on GitHub, especially
> `src/config/lua/bindings/*.cpp`) or the upstream
> `example/hyprland.lua`, not the wiki — the wiki has been wrong before.
> Don't commit anything without asking first.

## Open bug: waybar not loading custom style

**Symptom:** waybar renders with default GTK coloring instead of the
Rose Pine theme in `waybar/style.css`. Waybar's own startup log showed it
resolving config from `/etc/xdg/waybar/config.jsonc` (the system
fallback) instead of `~/.config/waybar/config.jsonc`.

**What's already confirmed on this session:**
- `~/.config/waybar` was NOT a symlink at all (a real/stale directory) —
  fixed manually with:
  ```bash
  rm -rf ~/.config/waybar
  ln -sf "$(pwd)/waybar" ~/.config/waybar   # run from repo root
  ```
- `scripts/install.sh`'s `_link()` helper (~line 146) symlinks the whole
  `waybar/` directory in one shot (`ln -sf "$src" "$dst"`), backing up
  any existing real dir first via `_backup()`. Re-running `install.sh`
  did NOT fix the broken symlink on its own — worth figuring out why
  (maybe the script bails early before reaching the waybar `_link` call,
  or something recreates `~/.config/waybar` as a real dir afterward).
- `$mod+B` only sends `killall -SIGUSR1 waybar` (a config *reload*
  signal) — it does NOT relaunch the process or re-resolve which config
  file to use. If waybar was already running when the symlink got fixed,
  it's still holding the config path it resolved at its *original*
  startup. Needs a full `killall waybar && waybar &` (or logout/login)
  to re-resolve the path, not just SIGUSR1.

**Next steps to try:**
1. `killall waybar && waybar 2>&1 | head -20` — confirm the resolved
   config path in the startup log. Should now point at
   `~/.config/waybar/config.jsonc` via the repo symlink.
2. If still falling back to `/etc/xdg`, check `echo $XDG_CONFIG_HOME` in
   the same shell/session Hyprland launches waybar from — it may differ
   from `$HOME/.config` depending on how the session starts (greeter vs
   TTY autologin vs systemd user session).
3. Once the correct config loads, re-check for any remaining GTK
   "invalid pseudo-class" warning in `waybar/style.css` — a prior
   inspection didn't find the culprit; the live log's exact file:line
   from a foreground `waybar 2>&1` run is what's needed to pin it down.
4. Re-run `scripts/install.sh` and check why it didn't fix the symlink
   itself — the `_link()` function (see `scripts/install.sh` around
   line 146-160) is a directory-level `ln -sf`; if it's not actually
   being reached or something after it recreates a real directory, that
   install.sh flow itself may need a fix.

## New feature usage: Lua config

The whole `hypr/` config is now Lua, loaded via `hyprland.lua`
(`require()` order: `theme` → `monitors` → `animations` → `keybinds` →
`rules`). Key API differences from classic hyprlang, learned the hard
way this session:

- Binds: `hl.bind("SUPER + Q", hl.dsp.window.close())` — modifiers MUST
  be joined with a literal `+` on both sides, e.g. `"SUPER + SHIFT + W"`.
  `"SUPER SHIFT + W"` (missing the middle `+`) parses as one invalid
  keysym token and throws `Unknown keysym "Super Shift"`.
- Most dispatchers take a **table**, not a bare string:
  `hl.dsp.focus({ direction = "left" })`,
  `hl.dsp.window.move({ direction = "left" })`,
  `hl.dsp.window.cycle_next({ next = true })`.
- Submaps: `hl.define_submap("resize", function() ... end)` to define,
  `hl.dsp.submap("resize")` to enter, `hl.dsp.submap("reset")` to exit —
  there's no separate enter/exit dispatcher pair.
- Animations use `bezier = "curveName"` or `spring = "..."` fields, not
  `curve = "..."`.
- Window rules (`hl.window_rule({...})`) take the same field names as
  classic `windowrulev2` (`float`, `pin`, `workspace`, `no_blur`, etc.) —
  see `hypr/rules.lua` for examples already in place.

Syntax-check any `.lua` edit before testing live:
`luac5.4 -p hypr/keybinds.lua` (or whichever file changed).
