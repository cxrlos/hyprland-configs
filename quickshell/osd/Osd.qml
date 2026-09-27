import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Services.Pipewire
import Quickshell.Wayland
import qs
import qs.widgets

// Frosted level pill near the bottom of the focused screen when volume, a mute or the
// backlight changes from the keyboard. Click-through; hidden while the matching dropdown
// is open, since its own slider already shows the level.
PanelWindow {
    id: root

    readonly property PwNode sink: Pipewire.defaultAudioSink
    readonly property PwNode source: Pipewire.defaultAudioSource

    // "volume", "mic" or "brightness"
    property string kind: "volume"
    property bool ready: false

    readonly property bool muted: kind === "mic" ? (source?.audio?.muted ?? false)
                                : kind === "volume" ? (sink?.audio?.muted ?? false) : false
    readonly property real level: kind === "brightness" ? Brightness.value : (sink?.audio?.volume ?? 0)

    function reveal(next: string): void {
        const dropdown = next === "brightness" ? "brightness" : "sound";
        if (!ready || DropdownState.open === dropdown)
            return;
        kind = next;
        visible = true;
        hide.restart();
    }

    visible: false
    screen: Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name) ?? Quickshell.screens[0]
    anchors.bottom: true
    margins.bottom: 140
    exclusionMode: ExclusionMode.Ignore
    implicitWidth: 300
    implicitHeight: 52
    color: "transparent"
    mask: Region {}

    WlrLayershell.namespace: "quickshell-panel"
    WlrLayershell.layer: WlrLayer.Overlay

    PwObjectTracker {
        objects: [root.sink, root.source]
    }

    Connections {
        target: root.sink?.audio ?? null

        function onVolumeChanged(): void {
            root.reveal("volume");
        }
        function onMutedChanged(): void {
            root.reveal("volume");
        }
    }

    Connections {
        target: root.source?.audio ?? null

        function onMutedChanged(): void {
            root.reveal("mic");
        }
    }

    Connections {
        target: Brightness

        function onStepped(): void {
            root.reveal("brightness");
        }
    }

    // PipeWire reports every node's initial state at startup; ignore that burst.
    Timer {
        running: true
        interval: 2000
        onTriggered: root.ready = true
    }

    Timer {
        id: hide

        interval: 1400
        onTriggered: root.visible = false
    }

    Rectangle {
        anchors.fill: parent
        radius: height / 2
        color: Theme.elevated
        border.width: 1
        border.color: Theme.rim

        RowLayout {
            anchors {
                fill: parent
                leftMargin: 18
                rightMargin: 20
            }
            spacing: 14

            Glyph {
                glyph: root.kind === "mic" ? (root.muted ? "" : "")
                     : root.kind === "brightness" ? ""
                     : root.muted ? "" : root.level < 0.34 ? "" : root.level < 0.67 ? "" : ""
                size: 22
                color: root.muted ? Theme.text2 : Theme.text
            }

            Rectangle {
                visible: root.kind !== "mic"
                Layout.fillWidth: true
                implicitHeight: 6
                radius: 3
                color: Qt.rgba(1, 1, 1, 0.12)

                Rectangle {
                    width: parent.width * Math.min(1, root.muted ? 0 : root.level)
                    height: parent.height
                    radius: 3
                    color: Theme.accent

                    Behavior on width {
                        NumberAnimation {
                            duration: 120
                            easing.type: Easing.OutCubic
                        }
                    }
                }
            }

            Text {
                Layout.fillWidth: root.kind === "mic"
                text: root.kind === "mic" ? (root.muted ? "Microphone off" : "Microphone on")
                    : root.muted ? "Muted" : Math.round(root.level * 100) + "%"
                color: Theme.text2
                horizontalAlignment: root.kind === "mic" ? Text.AlignLeft : Text.AlignRight
                font.family: Theme.font
                font.pixelSize: Theme.fontSize
                font.features: { "tnum": 1 }
            }
        }
    }
}
