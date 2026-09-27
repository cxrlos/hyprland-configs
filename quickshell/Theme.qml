pragma Singleton

import QtQuick
import Quickshell

// Neutral chrome tokens. Every Quickshell surface reads colours, type and sizes from here;
// rofi, swaync, hyprlock and the greeter keep their own copies (separate processes).
Singleton {
    readonly property color surface: Qt.rgba(30 / 255, 30 / 255, 33 / 255, 0.58)
    readonly property color elevated: Qt.rgba(36 / 255, 36 / 255, 40 / 255, 0.72)
    readonly property color rim: Qt.rgba(1, 1, 1, 0.12)
    readonly property color hair: Qt.rgba(1, 1, 1, 0.08)
    readonly property color hover: Qt.rgba(1, 1, 1, 0.10)

    readonly property color text: Qt.rgba(1, 1, 1, 0.90)
    readonly property color text2: Qt.rgba(235 / 255, 235 / 255, 245 / 255, 0.60)
    readonly property color text3: Qt.rgba(235 / 255, 235 / 255, 245 / 255, 0.32)

    readonly property color accent: "#83a598"
    readonly property color accentInk: "#1d2021"
    readonly property color critical: "#ff6961"

    readonly property string font: "Inter"
    readonly property string iconFont: "Material Symbols Rounded"
    readonly property int fontSize: 13
    readonly property int iconSize: 18

    readonly property int barHeight: 32
    readonly property int radiusSmall: 6
    readonly property int radiusPanel: 14

    readonly property int animFast: 150
}
