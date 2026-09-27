import QtQuick
import QtQuick.Layouts
import qs

// One clickable dropdown row: optional round badge, title + subtitle, and a trailing
// check, hint text or custom item.
Item {
    id: root

    property string glyph
    property bool badge: true
    property bool badgeOn: false
    property string title
    property string subtitle
    property bool checked: false
    property string hint
    property bool danger: false
    default property alias trailing: end.data

    signal clicked

    Layout.fillWidth: true
    implicitHeight: Math.max(30, content.implicitHeight + 10)

    readonly property bool hot: area.containsMouse && enabled
    readonly property color ink: hot && danger ? "#ffb3ae" : Theme.text

    Rectangle {
        anchors.fill: parent
        radius: 8
        color: !root.hot ? "transparent" : root.danger ? Qt.rgba(1, 0.41, 0.38, 0.18) : Qt.rgba(1, 1, 1, 0.08)
    }

    RowLayout {
        id: content

        anchors {
            left: parent.left
            right: parent.right
            verticalCenter: parent.verticalCenter
            leftMargin: 10
            rightMargin: 10
        }
        spacing: 10

        Rectangle {
            visible: root.glyph !== "" && root.badge
            implicitWidth: 26
            implicitHeight: 26
            radius: 13
            color: root.badgeOn ? Theme.accent : Qt.rgba(1, 1, 1, 0.1)

            Glyph {
                anchors.centerIn: parent
                glyph: root.glyph
                size: 16
                color: root.badgeOn ? Theme.accentInk : root.ink
            }
        }

        Glyph {
            visible: root.glyph !== "" && !root.badge
            glyph: root.glyph
            color: root.ink
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 1

            Text {
                Layout.fillWidth: true
                text: root.title
                color: root.enabled ? root.ink : Theme.text3
                elide: Text.ElideRight
                font.family: Theme.font
                font.pixelSize: Theme.fontSize
            }

            Text {
                Layout.fillWidth: true
                visible: root.subtitle !== ""
                text: root.subtitle
                color: Theme.text2
                elide: Text.ElideRight
                font.family: Theme.font
                font.pixelSize: 12
            }
        }

        Row {
            id: end

            spacing: 6

            Text {
                visible: root.hint !== ""
                anchors.verticalCenter: parent.verticalCenter
                text: root.hint
                color: Theme.text3
                font.family: Theme.font
                font.pixelSize: 12
            }

            Glyph {
                visible: root.checked
                glyph: ""
                color: Theme.accent
            }
        }
    }

    MouseArea {
        id: area

        anchors.fill: parent
        hoverEnabled: true
        onClicked: root.clicked()
    }
}
