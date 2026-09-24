local theme = require("theme")
require("monitors")
require("animations")
require("keybinds")
require("rules")

-- Autostart
hl.on("hyprland.start", function()
    hl.exec_cmd("waybar")
    hl.exec_cmd("~/.config/scripts/wallpaper.sh")
    hl.exec_cmd("swaync")
    hl.exec_cmd("wl-paste --watch cliphist store")
    hl.exec_cmd("/usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1")
    hl.exec_cmd("hypridle")

    -- Scratchpads (pre-started, toggled with Super+GRAVE)
    hl.exec_cmd("[workspace special:scratch silent] alacritty --class scratchpad")
end)

-- Environment
hl.env("XCURSOR_SIZE", "24")
hl.env("XCURSOR_THEME", "Catppuccin-Mocha-Dark-Cursors")
hl.env("QT_QPA_PLATFORM", "wayland;xcb")
hl.env("QT_AUTO_SCREEN_SCALE_FACTOR", "1")
hl.env("QT_WAYLAND_DISABLE_WINDOWDECORATION", "1")
hl.env("GDK_BACKEND", "wayland,x11,*")
hl.env("SDL_VIDEODRIVER", "wayland,x11")
hl.env("SDL_HAPTIC_DISABLED", "1")
hl.env("DXVK_FRAME_RATE", "60")
hl.env("CLUTTER_BACKEND", "wayland")
hl.env("XDG_CURRENT_DESKTOP", "Hyprland")
hl.env("XDG_SESSION_TYPE", "wayland")
hl.env("XDG_SESSION_DESKTOP", "Hyprland")
hl.env("ELECTRON_OZONE_PLATFORM_HINT", "auto")
hl.env("COLORTERM", "truecolor")
hl.env("BROWSER", "zen-browser")

hl.config({
    general = {
        gaps_in = theme.gap_in,
        gaps_out = theme.gap_out,
        border_size = 2,
        col = {
            active_border = theme.border_active,
            inactive_border = theme.border_inactive,
        },
        layout = "dwindle",
        allow_tearing = false,
        resize_on_border = true,
    },

    decoration = {
        rounding = theme.rounding,
        active_opacity = 1.0,
        inactive_opacity = 1.0,
        fullscreen_opacity = 1.0,
        blur = { enabled = false },
        shadow = { enabled = false },
    },

    input = {
        kb_layout = "us",
        follow_mouse = 2,
        repeat_delay = 250,
        repeat_rate = 40,
        sensitivity = 0.0,
        accel_profile = "flat",
    },

    cursor = {
        no_hardware_cursors = true,
        enable_hyprcursor = true,
        sync_gsettings_theme = true,
    },

    misc = {
        force_default_wallpaper = 0,
        disable_hyprland_logo = true,
        disable_splash_rendering = true,
        focus_on_activate = false,
        mouse_move_enables_dpms = true,
        key_press_enables_dpms = true,
        enable_swallow = true,
        swallow_regex = "^(Alacritty)$",
        vrr = 0, -- 0 = off, 1 = always on, 2 = fullscreen only
    },

    dwindle = {
        preserve_split = true,
        force_split = 2,
    },
})

-- MX Master 3S (Logi Bolt Receiver)
hl.device({
    name = "logitech-usb-receiver-mouse",
    sensitivity = 0.0,
    accel_profile = "adaptive",
    scroll_factor = 0.1,
})
