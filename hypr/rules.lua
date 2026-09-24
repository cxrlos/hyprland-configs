local theme = require("theme")

hl.window_rule({
    name = "gaming-performance",
    match = { class = "^(steam_app_.*|gamescope|.*\\.exe|.*\\.EXE)$" },
    immediate = true,
    no_anim = true,
})

hl.window_rule({
    name = "scratchpad",
    match = { class = "^(scratchpad)$" },
    float = true,
    size = theme.size_md,
    center = true,
})

hl.window_rule({
    name = "btop-scratch",
    match = { class = "^(btop-scratch)$" },
    float = true,
    size = theme.size_lg,
    center = true,
})

hl.window_rule({
    name = "wiremix-scratch",
    match = { class = "^(wiremix-scratch)$" },
    float = true,
    size = theme.size_md,
    center = true,
})

hl.window_rule({
    name = "bluetui-float",
    match = { class = "^(bluetui-float)$" },
    float = true,
    size = theme.size_sm,
    center = true,
})

hl.window_rule({
    name = "nmtui-float",
    match = { class = "^(nmtui-float)$" },
    float = true,
    size = theme.size_md,
    center = true,
})

hl.window_rule({
    name = "pavucontrol-float",
    match = { class = "^(pavucontrol)$" },
    float = true,
})

hl.window_rule({
    name = "obsidian-workspace",
    match = { class = "^(obsidian)$" },
    workspace = "2",
})

hl.window_rule({
    name = "pip",
    match = { title = "^(Picture-in-Picture)$" },
    float = true,
    pin = true,
    size = "30% 30%",
    move = "68% 68%",
})
