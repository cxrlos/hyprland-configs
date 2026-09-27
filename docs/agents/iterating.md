# Iterating on the chrome

The loop for any new chrome idea, from "what if…" to shipped. The user decides keep or drop from a
live prototype, never from a description, so the prototype comes first and the polish comes last.

## 1. Prototype

1. Branch `proto/<topic>` from `main`. Every idea in the round shares it.
2. Build each idea as the real surface, live in the running shell: panels in `quickshell/panels/`, bar
   items in `quickshell/bar/`, mounted in `shell.qml`. Name files `Prototype*.qml` and open each with a
   `// PROTOTYPE (proto/<topic>):` line, so nothing reads as finished.
3. Stub the data so every state can be seen now: generated around the current time, plus a preview
   IPC hook for states that are otherwise hours away (the meetings prototype had
   `qs ipc call meetings preview <minutes>` to show "soon" and "live").
4. Give each prototype a temporary keybind under a `-- PROTOTYPE` comment in `keybinds.lua`, so it
   feels like the real thing to try.
5. Work that needs research into another app's internals (Zen's CSS variables, file formats) goes to a
   background agent, briefed to read the installed files (e.g. unpack `omni.ja`) and to write
   `PROTOTYPE-*` files without touching the live app. Review its output before handing it over.

Done when every idea can be opened and every one of its states seen, and you have checked each by
screenshot yourself (see Verify).

## 2. Verify

- Open with IPC and capture: `qs ipc call panel toggle <name>; sleep 1; grim -g "x,y wxh" out.png`,
  then read the image. Check a region for panels and the whole output (`grim -o <monitor>`) for
  overlays.
- `qs log | grep -iE 'error|not a type'` after every change, and `hyprctl configerrors` after a
  Hyprland reload.
- A dropdown opened by IPC right after a Quickshell restart fails (Wayland wants the bar to have had
  input first), so leave that check to the user and say so.

## 3. Test-and-pick

Hand over one message per round:
- **What to test / What to expect** per idea: the key or command, what should appear, and every
  caveat or unverified part stated plainly.
- One keep / keep-with-changes / drop question per idea in the question pane, with "not tested yet"
  as an option when trying it needs the user to do something (quit an app, run sudo).

## 4. Promote the winners

1. The user commits the prototype on `proto/<topic>`; that branch stays as the record.
2. Branch `feat/<topic>` from `main`, then `git checkout proto/<topic> -- .` and unstage.
3. For each kept idea:
   - Give it its real name, a real header comment, and real data.
   - Add its install step: packages, links into other apps' profiles, templates for local files.
   - Mirror its keybind in the cheatsheet.
   - Update `AGENTS.md` and `README.md`.
4. Delete the dropped ideas and the temporary binds. Commits and pushes are the user's.

Done when a fresh `install.sh` run would reproduce everything, and ShellCheck and Black are clean.

## 5. Propose

Once the agreed path is done, offer three or four additions of your own that fit the same design
principles, as a multi-select pick list. The user picks; the chosen ones go through this loop
again.
