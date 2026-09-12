-- TODO verify against wiki.hypr.land/Configuring/ for Hyprland 0.56 -- exact field name for per-monitor vrr on hl.monitor
hl.monitor({ output = "HDMI-A-1", mode = "2560x1080@60", position = "0x0", scale = 1, vrr = 0 })

-- If a second monitor is added, pin workspace 1 to this output with:
--   hl.workspace({ id = 1, monitor = "HDMI-A-1" })
