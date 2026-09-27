import QtQuick
import Quickshell.Hyprland
import qs

// App name of the focused window. Titles are mapped to short names so page and file
// titles never show in the bar during a screen share.
Text {
    readonly property var names: [
        [/[Nn]vim/, "Neovim"],
        [/[Cc]laude/, "Claude"],
        [/[Cc]ursor/, "Cursor"],
        [/^Alacritty$/, "Terminal"],
        [/Obsidian/, "Obsidian"],
        [/File Manager$/, "Files"],
        [/Spotify/, "Spotify"],
        [/ - Discord$/, "Discord"],
        [/ - Slack$/, "Slack"],
        [/^Steam$/, "Steam"],
        [/Zen Browser$/, "Zen"],
        [/Mozilla Firefox$/, "Firefox"],
        [/Google Chrome$/, "Chrome"],
        [/Chromium$/, "Chromium"],
        [/VLC media player$/, "VLC"],
        [/OBS \d/, "OBS"],
        [/Visual Studio Code$/, "Code"],
        [/GIMP/, "GIMP"],
        [/Telegram/, "Telegram"],
        [/KeePassXC$/, "KeePassXC"],
        [/Mozilla Thunderbird$/, "Mail"],
    ]

    readonly property string title: Hyprland.activeToplevel?.title ?? ""

    text: names.find(([pattern]) => pattern.test(title))?.[1] ?? title
    color: Theme.text
    elide: Text.ElideRight
    width: Math.min(implicitWidth, 420)
    font.family: Theme.font
    font.pixelSize: Theme.fontSize
    font.weight: Font.DemiBold
}
