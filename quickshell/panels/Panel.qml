import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import qs

// Frosted panel centred near the top of the focused screen, Spotlight-style. It takes the
// keyboard while open and closes on Esc or a click anywhere else.
PanelWindow {
    id: root

    required property string name
    property int panelWidth: 640
    default property alias content: body.data

    readonly property bool shown: PanelState.open === name

    visible: shown
    screen: Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name) ?? Quickshell.screens[0]
    anchors.top: true
    margins.top: Math.round((screen?.height ?? 1080) * 0.2)
    exclusionMode: ExclusionMode.Ignore
    implicitWidth: panelWidth
    implicitHeight: body.implicitHeight + 14
    color: "transparent"

    WlrLayershell.namespace: "quickshell-panel"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: shown ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    HyprlandFocusGrab {
        windows: [root]
        active: root.shown
        onCleared: PanelState.close(root.name)
    }

    Rectangle {
        anchors.fill: parent
        radius: Theme.radiusPanel
        color: Theme.elevated
        border.width: 1
        border.color: Theme.rim

        ColumnLayout {
            id: body

            anchors {
                left: parent.left
                right: parent.right
                top: parent.top
                margins: 7
            }
            spacing: 2
        }
    }
}
