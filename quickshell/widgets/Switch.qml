import QtQuick
import qs

Rectangle {
    id: root

    property bool checked

    signal toggled

    implicitWidth: 34
    implicitHeight: 20
    radius: 10
    color: checked ? Theme.accent : Qt.rgba(1, 1, 1, 0.16)

    Behavior on color {
        ColorAnimation {
            duration: Theme.animFast
        }
    }

    Rectangle {
        x: root.checked ? root.width - width - 2 : 2
        anchors.verticalCenter: parent.verticalCenter
        width: 16
        height: 16
        radius: 8
        color: "#f2f2f4"

        Behavior on x {
            NumberAnimation {
                duration: Theme.animFast
                easing.type: Easing.OutCubic
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        onClicked: root.toggled()
    }
}
