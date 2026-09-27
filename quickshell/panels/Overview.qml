import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import Quickshell.Widgets
import qs
import qs.widgets

// Mission Control: every workspace on the focused monitor as a live miniature over the blurred
// desktop. Click a window to focus it, a card to switch, "+" for an empty workspace;
// ←/→ and Return, or 1–9, from the keyboard.
PanelWindow {
    id: root

    readonly property string name: "overview"
    readonly property bool shown: PanelState.open === name
    readonly property HyprlandMonitor monitor: Hyprland.focusedMonitor
    readonly property var workspaces: Hyprland.workspaces.values
        .filter(ws => ws.id > 0 && ws.monitor?.name === monitor?.name)
        .sort((a, b) => a.id - b.id)
    readonly property int tiles: workspaces.length + 1
    readonly property int columns: Math.min(tiles, aspect > 2 ? 4 : 3)
    readonly property int rows: Math.ceil(tiles / columns)
    readonly property real aspect: (monitor?.width ?? 16) / (monitor?.height ?? 9)
    readonly property real cardWidth: Math.min(720,
        (width - 160 - (columns - 1) * 28) / columns,
        ((height - 200 - (rows - 1) * 56) / rows) * aspect)
    // Window geometry is in logical pixels; the monitor's width is physical.
    readonly property real zoom: cardWidth / ((monitor?.width ?? 1) / (monitor?.scale ?? 1))

    property int selected: 0

    function close(): void {
        PanelState.close(name);
    }

    function goTo(ws): void {
        close();
        if (ws)
            ws.activate();
        else
            Hyprland.dispatch('hl.dsp.focus({ workspace = "empty" })');
    }

    function focusWindow(toplevel): void {
        close();
        Hyprland.dispatch(`hl.dsp.focus({ window = "address:0x${toplevel.address}" })`);
    }

    visible: shown
    screen: Quickshell.screens.find(s => s.name === monitor?.name) ?? Quickshell.screens[0]
    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"

    WlrLayershell.namespace: "quickshell-panel"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: shown ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    onShownChanged: {
        if (!shown)
            return;
        Hyprland.refreshToplevels();
        selected = Math.max(0, workspaces.findIndex(ws => ws.active));
        keys.forceActiveFocus();
    }

    HyprlandFocusGrab {
        windows: [root]
        active: root.shown
        onCleared: root.close()
    }

    Rectangle {
        id: backdrop

        anchors.fill: parent
        color: Qt.rgba(0, 0, 0, 0.38)
        opacity: root.shown ? 1 : 0

        Behavior on opacity {
            NumberAnimation {
                duration: 180
                easing.type: Easing.OutCubic
            }
        }

        MouseArea {
            anchors.fill: parent
            onClicked: root.close()
        }
    }

    Item {
        id: keys

        focus: true
        Keys.onEscapePressed: root.close()
        Keys.onLeftPressed: root.selected = (root.selected - 1 + root.tiles) % root.tiles
        Keys.onRightPressed: root.selected = (root.selected + 1) % root.tiles
        Keys.onReturnPressed: root.goTo(root.workspaces[root.selected])
        Keys.onPressed: event => {
            const n = parseInt(event.text);
            if (n >= 1 && n <= root.workspaces.length)
                root.goTo(root.workspaces[n - 1]);
        }
    }

    GridLayout {
        anchors.centerIn: parent
        columns: root.columns
        columnSpacing: 28
        rowSpacing: 56
        scale: root.shown ? 1 : 0.94

        Behavior on scale {
            NumberAnimation {
                duration: 220
                easing.type: Easing.OutCubic
            }
        }

        Repeater {
            model: root.workspaces

            ColumnLayout {
                id: tile

                required property HyprlandWorkspace modelData
                required property int index
                readonly property bool current: index === root.selected

                spacing: 10

                ClippingRectangle {
                    Layout.preferredWidth: root.cardWidth
                    Layout.preferredHeight: root.cardWidth / root.aspect
                    radius: 10
                    color: Theme.elevated

                    Image {
                        anchors.fill: parent
                        source: "file://" + Quickshell.env("HOME") + "/.cache/wallpaper/current"
                        sourceSize.width: 800
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                        opacity: 0.85
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        onEntered: root.selected = tile.index
                        onClicked: root.goTo(tile.modelData)
                    }

                    Repeater {
                        model: tile.modelData.toplevels.values

                        ClippingRectangle {
                            id: win

                            required property HyprlandToplevel modelData
                            readonly property var ipc: modelData.lastIpcObject

                            visible: ipc?.at !== undefined
                            x: ((ipc?.at?.[0] ?? 0) - (root.monitor?.x ?? 0)) * root.zoom
                            y: ((ipc?.at?.[1] ?? 0) - (root.monitor?.y ?? 0)) * root.zoom
                            width: (ipc?.size?.[0] ?? 0) * root.zoom
                            height: (ipc?.size?.[1] ?? 0) * root.zoom
                            radius: 4
                            color: Theme.surface
                            border.width: 1
                            border.color: winArea.containsMouse ? Theme.accent : Theme.rim

                            ScreencopyView {
                                anchors.fill: parent
                                captureSource: root.shown ? win.modelData.wayland : null
                                live: true
                                constraintSize: Qt.size(win.width * 2, win.height * 2)
                            }

                            MouseArea {
                                id: winArea

                                anchors.fill: parent
                                hoverEnabled: true
                                onEntered: root.selected = tile.index
                                onClicked: root.focusWindow(win.modelData)
                            }
                        }
                    }

                    Rectangle {
                        anchors.fill: parent
                        radius: 10
                        color: "transparent"
                        border.width: tile.current ? 2 : 1
                        border.color: tile.current ? Theme.accent : Theme.rim
                    }
                }

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: {
                        const apps = [...new Set(tile.modelData.toplevels.values
                            .map(t => t.wayland?.appId ?? "").filter(a => a !== "")
                            .map(a => a.charAt(0).toUpperCase() + a.slice(1)))];
                        return `${tile.index + 1}   ${apps.join(", ") || "Empty"}`;
                    }
                    color: tile.current ? Theme.text : Theme.text2
                    font.family: Theme.font
                    font.pixelSize: Theme.fontSize
                    font.weight: tile.current ? Font.DemiBold : Font.Normal
                }
            }
        }

        ColumnLayout {
            readonly property bool current: root.selected === root.workspaces.length

            spacing: 10

            Rectangle {
                Layout.preferredWidth: root.cardWidth
                Layout.preferredHeight: root.cardWidth / root.aspect
                radius: 10
                color: newArea.containsMouse || parent.current ? Theme.hover : Qt.rgba(1, 1, 1, 0.04)
                border.width: parent.current ? 2 : 1
                border.color: parent.current ? Theme.accent : Theme.rim

                Glyph {
                    anchors.centerIn: parent
                    glyph: "add"
                    size: 40
                    color: Theme.text2
                }

                MouseArea {
                    id: newArea

                    anchors.fill: parent
                    hoverEnabled: true
                    onEntered: root.selected = root.workspaces.length
                    onClicked: root.goTo(null)
                }
            }

            Text {
                Layout.alignment: Qt.AlignHCenter
                text: "New workspace"
                color: parent.current ? Theme.text : Theme.text2
                font.family: Theme.font
                font.pixelSize: Theme.fontSize
            }
        }
    }
}
