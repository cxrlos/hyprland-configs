-- Reserved -- do not bind at WM level: backtick+any -> tmux prefix, Space+any -> nvim leader, C-h/j/k/l -> vim<->tmux nav, C-d/u/Space -> nvim scroll/which-key

local mod         = "SUPER"
local terminal    = "alacritty --working-directory " .. os.getenv("HOME")
local rofi_theme  = "-theme ~/.config/rofi/gruvbox.rasi"
local launcher    = "rofi -show drun " .. rofi_theme
local winswitcher = "rofi -show window " .. rofi_theme
local browser     = "zen-browser"

-- Applications
hl.bind(mod .. " + RETURN", hl.dsp.exec_cmd(terminal))
hl.bind(mod .. " + SPACE", hl.dsp.exec_cmd(launcher))
hl.bind(mod .. " + w", hl.dsp.exec_cmd(browser))
hl.bind(mod .. " + SHIFT + W", hl.dsp.exec_cmd(browser .. " --private-window"))
hl.bind(mod .. " + N", hl.dsp.exec_cmd("~/.config/scripts/focus-or-spawn.sh obsidian obsidian"))
hl.bind(mod .. " + SHIFT + N", hl.dsp.exec_cmd("~/.config/scripts/obsidian-capture.sh"))
hl.bind(mod .. " + SHIFT + O", hl.dsp.exec_cmd(winswitcher))

-- Scratchpads
hl.bind(mod .. " + grave", hl.dsp.workspace.toggle_special("scratch"))
hl.bind(mod .. " + Y", hl.dsp.exec_cmd("thunar"))
hl.bind(mod .. " + M", hl.dsp.exec_cmd("~/.config/scripts/scratch.sh btop btop-scratch btop"))

-- Window cycling
hl.bind(mod .. " + TAB", hl.dsp.window.cycle_next({ next = true }), { repeating = true })
hl.bind(mod .. " + SHIFT + TAB", hl.dsp.window.cycle_next({ next = false }), { repeating = true })

-- Window management
hl.bind(mod .. " + Q", hl.dsp.window.close())
hl.bind(mod .. " + F", hl.dsp.window.fullscreen({ mode = "fullscreen" }))
hl.bind(mod .. " + SHIFT + V", hl.dsp.window.float({ action = "toggle" }))
hl.bind(mod .. " + B", hl.dsp.exec_cmd("killall -SIGUSR1 waybar"))
hl.bind(mod .. " + D", hl.dsp.focus({ workspace = "empty" }))
hl.bind(mod .. " + ESCAPE", hl.dsp.exec_cmd("hyprlock"))

-- Clipboard
hl.bind(mod .. " + C", hl.dsp.exec_cmd("wl-copy \"$(wl-paste --primary 2>/dev/null)\""))
hl.bind(mod .. " + V", hl.dsp.exec_cmd("~/.config/scripts/clipboard.sh"))

-- Focus (vim hjkl)
hl.bind(mod .. " + H", hl.dsp.focus({ direction = "left" }))
hl.bind(mod .. " + J", hl.dsp.focus({ direction = "down" }))
hl.bind(mod .. " + K", hl.dsp.focus({ direction = "up" }))
hl.bind(mod .. " + L", hl.dsp.focus({ direction = "right" }))

-- Move windows
hl.bind(mod .. " + SHIFT + H", hl.dsp.window.move({ direction = "left" }))
hl.bind(mod .. " + SHIFT + J", hl.dsp.window.move({ direction = "down" }))
hl.bind(mod .. " + SHIFT + K", hl.dsp.window.move({ direction = "up" }))
hl.bind(mod .. " + SHIFT + L", hl.dsp.window.move({ direction = "right" }))

-- Resize submap: enter with mod+R, hjkl resizes (no ALT needed), Escape/Return exits
hl.define_submap("resize", function()
    hl.bind("H", hl.dsp.window.resize({ x = -30, y = 0, relative = true }), { repeating = true })
    hl.bind("J", hl.dsp.window.resize({ x = 0, y = 30, relative = true }), { repeating = true })
    hl.bind("K", hl.dsp.window.resize({ x = 0, y = -30, relative = true }), { repeating = true })
    hl.bind("L", hl.dsp.window.resize({ x = 30, y = 0, relative = true }), { repeating = true })
    hl.bind("ESCAPE", hl.dsp.submap("reset"))
    hl.bind("RETURN", hl.dsp.submap("reset"))
end)
hl.bind(mod .. " + R", hl.dsp.submap("resize"))

-- System submap: fast path for power actions (rofi power.sh below still works too)
hl.define_submap("system", function()
    hl.bind("L", hl.dsp.exec_cmd("hyprlock"))
    hl.bind("R", hl.dsp.exec_cmd("systemctl reboot"))
    hl.bind("P", hl.dsp.exec_cmd("systemctl poweroff"))
    hl.bind("U", hl.dsp.exec_cmd("systemctl suspend"))
    hl.bind("ESCAPE", hl.dsp.submap("reset"))
    hl.bind("RETURN", hl.dsp.submap("reset"))
end)
hl.bind(mod .. " + S", hl.dsp.submap("system"))

-- Workspaces 1-10
for i = 1, 9 do
    hl.bind(mod .. " + " .. i, hl.dsp.focus({ workspace = tostring(i) }))
    hl.bind(mod .. " + SHIFT + " .. i, hl.dsp.window.move({ workspace = tostring(i), follow = true }))
end
hl.bind(mod .. " + 0", hl.dsp.focus({ workspace = "10" }))
hl.bind(mod .. " + SHIFT + 0", hl.dsp.window.move({ workspace = "10", follow = true }))

-- Screenshots (no Print key)
hl.bind(mod .. " + SHIFT + A", hl.dsp.exec_cmd("~/.local/bin/screenshot area"))
hl.bind(mod .. " + SHIFT + F", hl.dsp.exec_cmd("~/.local/bin/screenshot screen"))

-- Screen recording (toggle: start on region select, stop on second press)
hl.bind(mod .. " + SHIFT + R", hl.dsp.exec_cmd("~/.config/scripts/record.sh"))

-- System utilities
hl.bind(mod .. " + SHIFT + I", hl.dsp.exec_cmd("waypaper"))
hl.bind(mod .. " + SHIFT + P", hl.dsp.exec_cmd("hyprpicker -a"))
hl.bind(mod .. " + SHIFT + M", hl.dsp.exec_cmd("~/.config/scripts/power.sh"))
hl.bind(mod .. " + SHIFT + C", hl.dsp.exec_cmd("~/.config/scripts/caffeine.sh toggle"))
hl.bind(mod .. " + SHIFT + slash", hl.dsp.exec_cmd("~/.config/scripts/cheatsheet.sh"))
hl.bind(mod .. " + SHIFT + B", hl.dsp.exec_cmd("~/.config/scripts/scratch.sh bluetui bluetui-float bluetui"))
hl.bind(mod .. " + SHIFT + D", hl.dsp.exec_cmd("swaync-client -d"))

-- Mouse window actions
hl.bind(mod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind(mod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

-- Media / hardware keys
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("wpctl set-volume -l 1.0 @DEFAULT_AUDIO_SINK@ 5%+"), { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"), { locked = true, repeating = true })
hl.bind("XF86AudioMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"), { locked = true })
hl.bind("XF86AudioMicMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"), { locked = true })
hl.bind("XF86AudioPlay", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioNext", hl.dsp.exec_cmd("playerctl next"), { locked = true })
hl.bind("XF86AudioPrev", hl.dsp.exec_cmd("playerctl previous"), { locked = true })
