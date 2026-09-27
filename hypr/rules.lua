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
    name = "pavucontrol-float",
    match = { class = "^(pavucontrol)$" },
    float = true,
})

hl.window_rule({
    name = "pip",
    match = { title = "^(Picture-in-Picture)$" },
    float = true,
    pin = true,
    size = "30% 30%",
    move = "68% 68%",
})

-- Frosted chrome: blur behind the translucent layers; ignore_alpha skips their fully
-- transparent margins so the blur keeps the rounded shape.
hl.layer_rule({
    name = "frosted-bar",
    match = { namespace = "^(quickshell-bar)$" },
    blur = true,
    blur_popups = true,
    ignore_alpha = 0.2,
})

hl.layer_rule({
    name = "frosted-overlays",
    match = { namespace = "^(quickshell-panel|swaync-control-center|swaync-notification-window)$" },
    blur = true,
    ignore_alpha = 0.2,
})
