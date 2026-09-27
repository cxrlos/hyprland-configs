import QtQuick
import qs

// A Material Symbols glyph with the bar's hover pill; the unit every right-side item is built from.
Item {
    id: root

    property string glyph
    property color tint: Theme.text
    property bool dimmed: false
    property bool highlighted: false

    signal clicked(var mouse)

    implicitWidth: 32
    implicitHeight: 24

    Rectangle {
        anchors.fill: parent
        radius: Theme.radiusSmall
        color: root.highlighted ? Qt.rgba(1, 1, 1, 0.14) : area.containsMouse ? Theme.hover : "transparent"

        Behavior on color {
            ColorAnimation {
                duration: Theme.animFast
            }
        }
    }

    Text {
        anchors.centerIn: parent
        text: root.glyph
        color: root.tint
        opacity: root.dimmed ? 0.38 : 0.9
        font.family: Theme.iconFont
        font.pixelSize: Theme.iconSize
    }

    MouseArea {
        id: area

        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: mouse => root.clicked(mouse)
    }
}
