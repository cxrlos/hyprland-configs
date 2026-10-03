# Laptop pass (temporary handoff — delete and purge after use)

Prompt for the agent session on the laptop. Paste "Do the laptop pass in LAPTOP-PASS.md" to start.
When every item below is done, run **Cleanup** at the end; this file must not stay in the repo or its history.

## Context

PR #4 shipped the overview (`Super+O`), the Quickshell launcher (`Super+Space`, rofi retired), the
calendar feed with the next-meeting chip, Obsidian notes search, and the Zen theme. PR #5 fixed the
Quickshell restart command. All of it was built and verified on the desktop (`bastion`, no battery,
scale 1). The laptop pieces were only verified to stay inert there; this pass checks them on real
laptop hardware. `AGENTS.md` is the reference; `docs/agents/iterating.md` is the working style.

## 1. Install

1. `git pull` on `main`, then `scripts/install.sh` (the user runs it; it needs sudo).
2. Confirm it detected the laptop (`IS_LAPTOP`), installed `brightnessctl upower power-profiles-daemon`,
   and enabled `power-profiles-daemon`.
3. Zen: if Zen had never run, the installer creates a profile headlessly. Confirm
   `userChrome.css`, `userContent.css` and `user.js` are linked into the default profile
   (`~/.config/zen/installs.ini` → `Default=`), then restart Zen and check the theme.

## 2. Laptop hardware

Done when each item is checked by the user or by a screenshot, and every failure has a cause.

- Bar shows the brightness (sun) and battery icons; the Battery dropdown's power modes switch.
- Brightness keys change the level and show the level pill.
- 3-finger swipe changes workspace.
- On battery: dims at 4 min, locks at 5 (shorten the timers temporarily to test, then restore).
- The built-in panel uses its preferred mode; a projector does too.
- Overview (`Super+O`) at the laptop's scale: thumbnails cover their cards at the right size and
  position (the review fixed a scale bug that only the laptop can confirm).

## 3. Calendar

1. The user copies `~/.config/calendars.yaml` from the desktop (it is never in the repo).
2. `gcalcli init` in a terminal with the user's own Desktop OAuth client (steps in the template's
   header, `scripts/calendars.example.yaml`); the token is per machine.
3. `~/.config/scripts/calendar-feed.py | jq -c '.[] | {title, calendar}'` lists today's events and
   stderr names no failing calendar; then `qs ipc call agenda refresh`.

## 4. Report

Summarise what passed, what failed and what was fixed (fixes go on a branch + PR, per `AGENTS.md`).

## Cleanup

After the pass, remove this file from the repo **and its history** (it is a one-off handoff):

```
sudo pacman -S --needed git-filter-repo
git switch main && git pull
git filter-repo --force --invert-paths --path LAPTOP-PASS.md   # rewrites every commit that touched it
git remote add origin https://github.com/cxrlos/hyprland-configs.git   # filter-repo drops origin
git push --force origin main
```

The history rewrite and force push are the user's to run, after confirming no open branch or PR
still needs the old commits. Every other clone (the desktop included) then runs
`git fetch origin && git reset --hard origin/main`. PR #5's page on GitHub keeps its diff; that
copy goes away only by deleting the PR via GitHub support.
