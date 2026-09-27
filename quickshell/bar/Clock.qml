import QtQuick
import Quickshell
import qs
import qs.dropdowns
import qs.widgets

Item {
    id: root

    implicitWidth: row.implicitWidth + 16
    implicitHeight: 24

    SystemClock {
        id: clock

        precision: SystemClock.Minutes
    }

    Rectangle {
        anchors.fill: parent
        radius: Theme.radiusSmall
        color: menu.shown ? Qt.rgba(1, 1, 1, 0.14) : area.containsMouse ? Theme.hover : "transparent"
    }

    Row {
        id: row

        anchors.centerIn: parent
        spacing: 8

        Text {
            text: Qt.formatDateTime(clock.date, "ddd d MMM")
            color: Theme.text2
            font.family: Theme.font
            font.pixelSize: Theme.fontSize
            font.features: { "tnum": 1 }
        }

        Text {
            text: Qt.formatDateTime(clock.date, "HH:mm")
            color: Theme.text
            font.family: Theme.font
            font.pixelSize: Theme.fontSize
            font.weight: Font.Medium
            font.features: { "tnum": 1 }
        }
    }

    MouseArea {
        id: area

        anchors.fill: parent
        hoverEnabled: true
        onClicked: DropdownState.toggle("calendar")
    }

    CalendarDropdown {
        id: menu

        anchorItem: root
        today: clock.date
    }
}
