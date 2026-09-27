hl.monitor({ output = "HDMI-A-1", mode = "2560x1080@60", position = "0x0", scale = 1, vrr = 0 })

-- Any other output (the laptop panel, a projector at a client) uses its preferred mode.
hl.monitor({ output = "", mode = "preferred", position = "auto", scale = "auto" })

-- If a second monitor is added, pin workspace 1 to this output with:
--   hl.workspace({ id = 1, monitor = "HDMI-A-1" })
