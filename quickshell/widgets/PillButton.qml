import QtQuick
import qs

Rectangle {
    id: root

    property alias text: label.text
    property bool primary: false

    signal clicked

    implicitWidth: label.implicitWidth + 24
    implicitHeight: 26
    radius: 8
    color: primary ? (area.containsMouse ? "#93b3a6" : Theme.accent)
                   : (area.containsMouse ? Qt.rgba(1, 1, 1, 0.16) : Qt.rgba(1, 1, 1, 0.1))

    Text {
        id: label

        anchors.centerIn: parent
        color: root.primary ? Theme.accentInk : Theme.text
        font.family: Theme.font
        font.pixelSize: 13
        font.weight: root.primary ? Font.DemiBold : Font.Normal
    }

    MouseArea {
        id: area

        anchors.fill: parent
        hoverEnabled: true
        onClicked: root.clicked()
    }
}
