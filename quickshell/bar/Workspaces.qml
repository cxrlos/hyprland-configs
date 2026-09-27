import QtQuick
import Quickshell
import Quickshell.Hyprland
import qs

// Existing workspaces on this monitor as dots; the active one stretches into a sage pill.
Row {
    id: root

    required property ShellScreen monitor

    readonly property var workspaces: Hyprland.workspaces.values
        .filter(ws => ws.id > 0 && ws.monitor?.name === monitor.name)
        .sort((a, b) => a.id - b.id)

    spacing: 6

    Repeater {
        model: root.workspaces

        Rectangle {
            required property HyprlandWorkspace modelData

            anchors.verticalCenter: parent.verticalCenter
            width: modelData.active ? 20 : 8
            height: 8
            radius: 4
            color: modelData.active ? Theme.accent
                 : modelData.urgent ? Theme.critical
                 : area.containsMouse ? Theme.text2 : Theme.text3

            Behavior on width {
                NumberAnimation {
                    duration: Theme.animFast
                    easing.type: Easing.OutCubic
                }
            }
            Behavior on color {
                ColorAnimation {
                    duration: Theme.animFast
                }
            }

            MouseArea {
                id: area

                anchors.fill: parent
                anchors.margins: -4
                hoverEnabled: true
                onClicked: parent.modelData.activate()
            }
        }
    }
}
