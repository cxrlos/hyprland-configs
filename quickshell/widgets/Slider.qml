import QtQuick
import qs

// Pill slider (0..1) with a sage fill; drag or click anywhere on the track.
Rectangle {
    id: root

    property real value
    property string glyph

    signal moved(real value)

    implicitHeight: 22
    radius: 11
    color: Qt.rgba(1, 1, 1, 0.1)
    clip: true

    readonly property real knobX: (width - knob.width) * Math.max(0, Math.min(1, value))

    Rectangle {
        width: root.knobX + knob.width
        height: parent.height
        radius: root.radius
        color: Theme.accent
    }

    Glyph {
        anchors.left: parent.left
        anchors.leftMargin: 6
        anchors.verticalCenter: parent.verticalCenter
        glyph: root.glyph
        size: 15
        color: Theme.accentInk
    }

    Rectangle {
        id: knob

        x: root.knobX
        y: 1
        width: 20
        height: 20
        radius: 10
        color: "#f2f2f4"
    }

    MouseArea {
        anchors.fill: parent
        preventStealing: true

        function emit(mouseX: real): void {
            root.moved(Math.max(0, Math.min(1, (mouseX - knob.width / 2) / (root.width - knob.width))));
        }

        onPressed: mouse => emit(mouse.x)
        onPositionChanged: mouse => emit(mouse.x)
    }
}
