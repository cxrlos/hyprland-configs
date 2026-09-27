import QtQuick
import qs

// Small round icon button used inside panels (mute, media controls, calendar paging).
Rectangle {
    id: root

    property string glyph
    property int glyphSize: 18

    signal clicked

    implicitWidth: 28
    implicitHeight: 28
    radius: width / 2
    color: area.containsMouse ? Qt.rgba(1, 1, 1, 0.1) : "transparent"

    Glyph {
        anchors.centerIn: parent
        glyph: root.glyph
        size: root.glyphSize
    }

    MouseArea {
        id: area

        anchors.fill: parent
        hoverEnabled: true
        onClicked: root.clicked()
    }
}
