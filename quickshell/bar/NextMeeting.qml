import QtQuick
import qs
import qs.widgets

// The running or next meeting beside the clock, shown only within the hour before it so the bar
// stays calm. Sage from 5 minutes out, when a click joins the call; otherwise a click opens the
// calendar. Hidden while sharing the screen, since titles can be private.
Item {
    id: root

    readonly property bool soon: Agenda.minutesToNext >= 0 && Agenda.minutesToNext <= 5
    readonly property var meeting: soon ? Agenda.next : Agenda.current ?? Agenda.next
    readonly property bool live: meeting !== null && meeting === Agenda.current
    readonly property bool imminent: live || soon
    readonly property string when: live ? "now" : `in ${Agenda.minutesToNext} min`

    visible: meeting !== null && !ScreenShare.active && (live || Agenda.minutesToNext <= 60)
    implicitWidth: row.implicitWidth + 16
    implicitHeight: 24

    Rectangle {
        anchors.fill: parent
        radius: height / 2
        color: root.imminent ? Theme.accent : area.containsMouse ? Theme.hover : "transparent"
    }

    Row {
        id: row

        anchors.centerIn: parent
        spacing: 6

        Glyph {
            anchors.verticalCenter: parent.verticalCenter
            glyph: "videocam"
            size: 15
            color: root.imminent ? Theme.accentInk : Theme.text2
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            width: Math.min(implicitWidth, 320)
            elide: Text.ElideMiddle
            text: `${root.meeting?.title ?? ""}  ·  ${root.when}`
            color: root.imminent ? Theme.accentInk : Theme.text2
            font.family: Theme.font
            font.pixelSize: Theme.fontSize
            font.weight: root.imminent ? Font.DemiBold : Font.Normal
            font.features: { "tnum": 1 }
        }
    }

    MouseArea {
        id: area

        anchors.fill: parent
        hoverEnabled: true
        onClicked: root.imminent && root.meeting.call ? Agenda.join(root.meeting) : DropdownState.toggle("calendar")
    }
}
