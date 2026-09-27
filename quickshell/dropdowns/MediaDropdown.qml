import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Mpris
import Quickshell.Widgets
import qs
import qs.widgets

Dropdown {
    id: root

    required property MprisPlayer player

    function time(seconds: real): string {
        const s = Math.max(0, Math.floor(seconds));
        return `${Math.floor(s / 60)}:${String(s % 60).padStart(2, "0")}`;
    }

    name: "media"
    panelWidth: 320

    // Mpris only reports position on change events, so poll it while visible.
    Timer {
        running: root.shown && (root.player?.isPlaying ?? false)
        interval: 1000
        repeat: true
        onTriggered: root.player.positionChanged()
    }

    RowLayout {
        Layout.fillWidth: true
        Layout.margins: 4
        spacing: 12

        ClippingRectangle {
            implicitWidth: 64
            implicitHeight: 64
            radius: 8
            color: Qt.rgba(1, 1, 1, 0.08)

            Image {
                anchors.fill: parent
                source: root.player?.trackArtUrl ?? ""
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
            }

            Glyph {
                visible: !root.player?.trackArtUrl
                anchors.centerIn: parent
                glyph: ""
                size: 26
                color: Theme.text3
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2

            Text {
                Layout.fillWidth: true
                text: root.player?.trackTitle ?? ""
                color: Theme.text
                elide: Text.ElideRight
                font.family: Theme.font
                font.pixelSize: Theme.fontSize
                font.weight: Font.DemiBold
            }

            Text {
                Layout.fillWidth: true
                text: root.player?.trackArtist ?? ""
                color: Theme.text2
                elide: Text.ElideRight
                font.family: Theme.font
                font.pixelSize: 12
            }
        }
    }

    ColumnLayout {
        visible: root.player?.lengthSupported ?? false
        Layout.fillWidth: true
        Layout.leftMargin: 8
        Layout.rightMargin: 8
        Layout.topMargin: 4
        spacing: 4

        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 4
            radius: 2
            color: Qt.rgba(1, 1, 1, 0.12)

            Rectangle {
                width: parent.width * Math.min(1, (root.player?.position ?? 0) / Math.max(1, root.player?.length ?? 1))
                height: parent.height
                radius: 2
                color: Theme.text2
            }
        }

        RowLayout {
            Layout.fillWidth: true

            Text {
                Layout.fillWidth: true
                text: root.time(root.player?.position ?? 0)
                color: Theme.text3
                font.family: Theme.font
                font.pixelSize: 11
                font.features: { "tnum": 1 }
            }
            Text {
                text: root.time(root.player?.length ?? 0)
                color: Theme.text3
                font.family: Theme.font
                font.pixelSize: 11
                font.features: { "tnum": 1 }
            }
        }
    }

    Row {
        Layout.alignment: Qt.AlignHCenter
        Layout.topMargin: 2
        Layout.bottomMargin: 4
        spacing: 18

        BarIconButton {
            anchors.verticalCenter: parent.verticalCenter
            glyph: ""
            glyphSize: 24
            onClicked: root.player?.previous()
        }

        Rectangle {
            width: 40
            height: 40
            radius: 20
            color: playArea.containsMouse ? "#f2f2f4" : Qt.rgba(1, 1, 1, 0.9)

            Glyph {
                anchors.centerIn: parent
                glyph: root.player?.isPlaying ? "" : ""
                size: 24
                color: Theme.accentInk
            }

            MouseArea {
                id: playArea

                anchors.fill: parent
                hoverEnabled: true
                onClicked: root.player?.togglePlaying()
            }
        }

        BarIconButton {
            anchors.verticalCenter: parent.verticalCenter
            glyph: ""
            glyphSize: 24
            onClicked: root.player?.next()
        }
    }

    Separator {}

    Text {
        Layout.fillWidth: true
        Layout.leftMargin: 12
        Layout.bottomMargin: 6
        text: root.player?.identity ?? ""
        color: Theme.text2
        font.family: Theme.font
        font.pixelSize: 12
    }
}
