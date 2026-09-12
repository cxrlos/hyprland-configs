-- Reserved -- do not bind at WM level: backtick+any -> tmux prefix, Space+any -> nvim leader, C-h/j/k/l -> vim<->tmux nav, C-d/u/Space -> nvim scroll/which-key

local mod         = "SUPER"
local terminal    = "alacritty --working-directory " .. os.getenv("HOME")
local rofi_theme  = "-theme ~/.config/rofi/gruvbox.rasi"
local launcher    = "rofi -show drun " .. rofi_theme
local winswitcher = "rofi -show window " .. rofi_theme
local browser     = "firefox"

-- Applications
hl.bind(mod .. " + RETURN", hl.dsp.exec_cmd(terminal))
hl.bind(mod .. " + SPACE", hl.dsp.exec_cmd(launcher))
hl.bind(mod .. " + w", hl.dsp.exec_cmd("~/.config/scripts/focus-or-spawn.sh firefox " .. browser))
hl.bind(mod .. " SHIFT + W", hl.dsp.exec_cmd(browser .. " --private-window"))
hl.bind(mod .. " + N", hl.dsp.exec_cmd("~/.config/scripts/focus-or-spawn.sh obsidian obsidian"))
hl.bind(mod .. " SHIFT + N", hl.dsp.exec_cmd("~/.config/scripts/obsidian-capture.sh"))
hl.bind(mod .. " SHIFT + O", hl.dsp.exec_cmd(winswitcher))

-- Scratchpads
hl.bind(mod .. " + grave", hl.dsp.workspace.toggle_special("scratch"))
hl.bind(mod .. " + Y", hl.dsp.exec_cmd("thunar"))
hl.bind(mod .. " + M", hl.dsp.exec_cmd("~/.config/scripts/scratch.sh btop btop-scratch btop"))

-- Window cycling
hl.bind(mod .. " + TAB", hl.dsp.cycle_next({ prev = false }), { repeating = true })
hl.bind(mod .. " SHIFT + TAB", hl.dsp.cycle_next({ prev = true }), { repeating = true })

-- Window management
hl.bind(mod .. " + Q", hl.dsp.window.close())
hl.bind(mod .. " + F", hl.dsp.window.fullscreen({ mode = 0 }))
hl.bind(mod .. " SHIFT + V", hl.dsp.window.float({ action = "toggle" }))
hl.bind(mod .. " + B", hl.dsp.exec_cmd("killall -SIGUSR1 waybar"))
hl.bind(mod .. " + D", hl.dsp.workspace.go("empty"))
hl.bind(mod .. " + ESCAPE", hl.dsp.exec_cmd("hyprlock"))

-- Clipboard
hl.bind(mod .. " + C", hl.dsp.exec_cmd("wl-copy \"$(wl-paste --primary 2>/dev/null)\""))
hl.bind(mod .. " + V", hl.dsp.exec_cmd("~/.config/scripts/clipboard.sh"))

-- Focus (vim hjkl)
hl.bind(mod .. " + H", hl.dsp.focus("l"))
hl.bind(mod .. " + J", hl.dsp.focus("d"))
hl.bind(mod .. " + K", hl.dsp.focus("u"))
hl.bind(mod .. " + L", hl.dsp.focus("r"))

-- Move windows
hl.bind(mod .. " SHIFT + H", hl.dsp.window.move("l"))
hl.bind(mod .. " SHIFT + J", hl.dsp.window.move("d"))
hl.bind(mod .. " SHIFT + K", hl.dsp.window.move("u"))
hl.bind(mod .. " SHIFT + L", hl.dsp.window.move("r"))

-- Resize submap: enter with mod+R, hjkl resizes (no ALT needed), Escape/Return exits
-- TODO verify against wiki.hypr.land/Configuring/ for Hyprland 0.56 -- exact hl submap API (definition + enter/exit dispatchers)
hl.submap("resize", function()
    hl.bind("H", hl.dsp.window.resize({ x = -30, y = 0, relative = true }), { repeating = true })
    hl.bind("J", hl.dsp.window.resize({ x = 0, y = 30, relative = true }), { repeating = true })
    hl.bind("K", hl.dsp.window.resize({ x = 0, y = -30, relative = true }), { repeating = true })
    hl.bind("L", hl.dsp.window.resize({ x = 30, y = 0, relative = true }), { repeating = true })
    hl.bind("ESCAPE", hl.dsp.submap_exit())
    hl.bind("RETURN", hl.dsp.submap_exit())
end)
hl.bind(mod .. " + R", hl.dsp.submap_enter("resize"))

-- System submap: fast path for power actions (rofi power.sh below still works too)
-- TODO verify against wiki.hypr.land/Configuring/ for Hyprland 0.56 -- exact hl submap API (definition + enter/exit dispatchers)
hl.submap("system", function()
    hl.bind("L", hl.dsp.exec_cmd("hyprlock"))
    hl.bind("R", hl.dsp.exec_cmd("systemctl reboot"))
    hl.bind("P", hl.dsp.exec_cmd("systemctl poweroff"))
    hl.bind("U", hl.dsp.exec_cmd("systemctl suspend"))
    hl.bind("ESCAPE", hl.dsp.submap_exit())
    hl.bind("RETURN", hl.dsp.submap_exit())
end)
hl.bind(mod .. " + S", hl.dsp.submap_enter("system"))

-- Workspaces 1-10
for i = 1, 9 do
    hl.bind(mod .. " + " .. i, hl.dsp.workspace.go(i))
    hl.bind(mod .. " SHIFT + " .. i, hl.dsp.window.move_to_workspace(i))
end
hl.bind(mod .. " + 0", hl.dsp.workspace.go(10))
hl.bind(mod .. " SHIFT + 0", hl.dsp.window.move_to_workspace(10))

-- Screenshots (no Print key)
hl.bind(mod .. " SHIFT + A", hl.dsp.exec_cmd("~/.local/bin/screenshot area"))
hl.bind(mod .. " SHIFT + F", hl.dsp.exec_cmd("~/.local/bin/screenshot screen"))

-- Screen recording (toggle: start on region select, stop on second press)
hl.bind(mod .. " SHIFT + R", hl.dsp.exec_cmd("~/.config/scripts/record.sh"))

-- System utilities
hl.bind(mod .. " SHIFT + I", hl.dsp.exec_cmd("waypaper"))
hl.bind(mod .. " SHIFT + P", hl.dsp.exec_cmd("hyprpicker -a"))
hl.bind(mod .. " SHIFT + M", hl.dsp.exec_cmd("~/.config/scripts/power.sh"))
hl.bind(mod .. " SHIFT + C", hl.dsp.exec_cmd("~/.config/scripts/caffeine.sh toggle"))
hl.bind(mod .. " SHIFT + slash", hl.dsp.exec_cmd("~/.config/scripts/cheatsheet.sh"))
hl.bind(mod .. " SHIFT + B", hl.dsp.exec_cmd("~/.config/scripts/scratch.sh bluetui bluetui-float bluetui"))
hl.bind(mod .. " SHIFT + D", hl.dsp.exec_cmd("swaync-client -d"))

-- Mouse window actions
hl.bind(mod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true })
-- TODO verify against wiki.hypr.land/Configuring/Basics/Binds/ for Hyprland 0.56 -- dispatcher name for mouse-driven resize (old resizewindow)
hl.bind(mod .. " + mouse:273", hl.dsp.window.resize_drag(), { mouse = true })

-- Media / hardware keys
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("wpctl set-volume -l 1.0 @DEFAULT_AUDIO_SINK@ 5%+"), { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"), { locked = true, repeating = true })
hl.bind("XF86AudioMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"), { locked = true })
hl.bind("XF86AudioMicMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"), { locked = true })
hl.bind("XF86AudioPlay", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioNext", hl.dsp.exec_cmd("playerctl next"), { locked = true })
hl.bind("XF86AudioPrev", hl.dsp.exec_cmd("playerctl previous"), { locked = true })
