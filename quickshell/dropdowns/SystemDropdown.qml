import QtQuick
import QtQuick.Layouts
import Quickshell
import qs
import qs.widgets

Dropdown {
    id: root

    required property var status

    readonly property var meters: [
        { name: "CPU", fraction: (status.cpu ?? 0) / 100, value: `${status.cpu ?? 0}%` },
        { name: "Memory", fraction: (status.memory?.used ?? 0) / (status.memory?.total || 1),
          value: `${status.memory?.used ?? 0} / ${status.memory?.total ?? 0} GB` },
        { name: "GPU", fraction: (status.gpu?.busy ?? 0) / 100,
          value: status.gpu ? `${status.gpu.busy}% · ${status.gpu.vramUsed} / ${status.gpu.vramTotal} GB` : "Unavailable" },
    ]

    function launch(command: list<string>): void {
        DropdownState.open = "";
        Quickshell.execDetached(command);
    }

    name: "system"
    panelWidth: 340

    PanelHeader {
        title: "System"
    }

    Repeater {
        model: root.meters

        RowLayout {
            required property var modelData

            Layout.fillWidth: true
            Layout.leftMargin: 10
            Layout.rightMargin: 10
            Layout.topMargin: 3
            Layout.bottomMargin: 3
            spacing: 10

            Text {
                Layout.preferredWidth: 58
                text: parent.modelData.name
                color: Theme.text2
                font.family: Theme.font
                font.pixelSize: Theme.fontSize
            }

            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 5
                radius: 3
                color: Qt.rgba(1, 1, 1, 0.1)

                Rectangle {
                    width: parent.width * Math.min(1, parent.parent.modelData.fraction)
                    height: parent.height
                    radius: 3
                    color: Theme.accent

                    Behavior on width {
                        NumberAnimation {
                            duration: 300
                            easing.type: Easing.OutCubic
                        }
                    }
                }
            }

            Text {
                Layout.preferredWidth: 118
                horizontalAlignment: Text.AlignRight
                text: parent.modelData.value
                color: Theme.text
                font.family: Theme.font
                font.pixelSize: 13
                font.features: { "tnum": 1 }
            }
        }
    }

    Separator {}

    MenuRow {
        glyph: ""
        title: root.status.updates > 0 ? `${root.status.updates} updates available` : "Up to date"
        badgeOn: root.status.updates > 0

        PillButton {
            visible: root.status.updates > 0
            text: "Update…"
            primary: true
            onClicked: root.launch(["alacritty", "-e", "yay"])
        }
    }

    MenuRow {
        glyph: ""
        title: "Open btop"
        onClicked: root.launch(["bash", "-c", "~/.config/scripts/scratch.sh btop btop-scratch btop"])
    }
}
