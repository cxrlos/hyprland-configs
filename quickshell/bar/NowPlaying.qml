import QtQuick
import Quickshell.Services.Mpris
import qs
import qs.dropdowns
import qs.widgets

// "Artist · Title" of the playing (or first) player, hidden while the screen is shared;
// click opens the player panel.
Item {
    id: root

    readonly property MprisPlayer player: Mpris.players.values.find(p => p.isPlaying)
        ?? Mpris.players.values[0] ?? null
    readonly property string track: player
        ? [player.trackArtist, player.trackTitle].filter(Boolean).join(" · ")
        : ""

    visible: track !== "" && !ScreenShare.active
    implicitWidth: label.width + 16
    implicitHeight: 24

    Rectangle {
        anchors.fill: parent
        radius: Theme.radiusSmall
        color: menu.shown ? Qt.rgba(1, 1, 1, 0.14) : area.containsMouse ? Theme.hover : "transparent"
    }

    Text {
        id: label

        anchors.centerIn: parent
        width: Math.min(implicitWidth, 280)
        text: root.track
        color: Theme.text2
        elide: Text.ElideRight
        font.family: Theme.font
        font.pixelSize: Theme.fontSize
    }

    MouseArea {
        id: area

        anchors.fill: parent
        hoverEnabled: true
        onClicked: DropdownState.toggle("media")
    }

    MediaDropdown {
        id: menu

        anchorItem: root
        player: root.player
    }
}
