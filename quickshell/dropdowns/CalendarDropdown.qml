import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import qs
import qs.widgets

// Month grid, Monday first, paged with the chevrons; reopening returns to this month. Dots mark
// days with events (from the feed's cache); click a day to list it. Today's list is Agenda's live one.
Dropdown {
    id: root

    required property date today

    property int offset: 0
    property date selected: today
    property var gridEvents: []

    readonly property date first: new Date(today.getFullYear(), today.getMonth() + offset, 1)
    readonly property int lead: (first.getDay() + 6) % 7
    readonly property var days: Array.from({ length: 42 }, (_, i) => new Date(first.getFullYear(), first.getMonth(), i - lead + 1))

    readonly property bool selectedIsToday: selected.toDateString() === today.toDateString()
    readonly property var dayEvents: selectedIsToday ? Agenda.events : eventsOn(selected)

    function eventsOn(day: date): var {
        const start = new Date(day.getFullYear(), day.getMonth(), day.getDate()).getTime();
        const end = new Date(day.getFullYear(), day.getMonth(), day.getDate() + 1).getTime();
        return gridEvents.filter(e => e.start < end && e.end > start);
    }

    function isoWeek(d: date): int {
        const t = new Date(Date.UTC(d.getFullYear(), d.getMonth(), d.getDate()));
        t.setUTCDate(t.getUTCDate() + 4 - (t.getUTCDay() || 7));
        return Math.ceil(((t - new Date(Date.UTC(t.getUTCFullYear(), 0, 1))) / 86400000 + 1) / 7);
    }

    name: "calendar"
    panelWidth: 300
    onShownChanged: {
        offset = 0;
        selected = today;
        if (shown)
            grid.running = true;
    }

    Process {
        id: grid

        // One load of the feed's whole paging window, so paging only filters.
        command: ["bash", "-c", "~/.config/scripts/calendar-feed.py --offline --window"]
        stdout: StdioCollector {
            onStreamFinished: root.gridEvents = JSON.parse(text || "[]")
        }
    }

    Connections {
        target: Agenda

        function onEventsChanged(): void {
            if (root.shown)
                grid.running = true;
        }
    }

    RowLayout {
        Layout.fillWidth: true
        Layout.leftMargin: 10
        Layout.rightMargin: 4
        Layout.topMargin: 2

        Text {
            Layout.fillWidth: true
            text: Qt.formatDate(root.first, "MMMM yyyy")
            color: Theme.text
            font.family: Theme.font
            font.pixelSize: Theme.fontSize
            font.weight: Font.DemiBold
        }

        BarIconButton {
            glyph: ""
            onClicked: root.offset--
        }
        BarIconButton {
            glyph: ""
            onClicked: root.offset++
        }
    }

    GridLayout {
        Layout.fillWidth: true
        Layout.margins: 4
        columns: 7
        rowSpacing: 2
        columnSpacing: 2

        Repeater {
            model: ["Mo", "Tu", "We", "Th", "Fr", "Sa", "Su"]

            Text {
                required property string modelData

                Layout.fillWidth: true
                Layout.bottomMargin: 4
                horizontalAlignment: Text.AlignHCenter
                text: modelData
                color: Theme.text3
                font.family: Theme.font
                font.pixelSize: 11
                font.weight: Font.DemiBold
            }
        }

        Repeater {
            model: root.days

            Rectangle {
                id: day

                required property date modelData
                readonly property bool isToday: modelData.toDateString() === root.today.toDateString()
                readonly property bool isSelected: modelData.toDateString() === root.selected.toDateString()
                readonly property var colors: [...new Set(root.eventsOn(modelData).map(e => e.color))].slice(0, 3)

                Layout.fillWidth: true
                implicitHeight: 32
                radius: 16
                color: isToday ? Theme.accent : isSelected ? Qt.rgba(1, 1, 1, 0.14) : dayArea.containsMouse ? Theme.hover : "transparent"

                Text {
                    anchors.centerIn: parent
                    anchors.verticalCenterOffset: -2
                    text: day.modelData.getDate()
                    color: day.isToday ? Theme.accentInk
                         : day.modelData.getMonth() === root.first.getMonth() ? Theme.text : Theme.text3
                    font.family: Theme.font
                    font.pixelSize: 13
                    font.weight: day.isToday || day.isSelected ? Font.DemiBold : Font.Normal
                    font.features: { "tnum": 1 }
                }

                Row {
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: 4
                    spacing: 2

                    Repeater {
                        model: day.colors

                        Rectangle {
                            required property string modelData

                            width: 4
                            height: 4
                            radius: 2
                            color: day.isToday ? Theme.accentInk : modelData
                        }
                    }
                }

                MouseArea {
                    id: dayArea

                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: root.selected = day.modelData
                }
            }
        }
    }

    Separator {
        visible: root.dayEvents.length > 0 || !root.selectedIsToday
    }

    SectionLabel {
        visible: root.dayEvents.length > 0 || !root.selectedIsToday
        text: root.selectedIsToday ? "Today" : Qt.formatDate(root.selected, "dddd d MMMM")
    }

    Text {
        visible: root.dayEvents.length === 0 && !root.selectedIsToday
        Layout.leftMargin: 12
        Layout.bottomMargin: 4
        text: "No events"
        color: Theme.text3
        font.family: Theme.font
        font.pixelSize: Theme.fontSize
    }

    Repeater {
        model: root.dayEvents

        RowLayout {
            id: event

            required property var modelData
            readonly property bool past: modelData.end <= Agenda.now.getTime()
            readonly property bool live: modelData.start <= Agenda.now.getTime() && !past

            Layout.fillWidth: true
            Layout.leftMargin: 10
            Layout.rightMargin: 6
            implicitHeight: 34
            spacing: 10
            opacity: past ? 0.45 : 1

            Rectangle {
                implicitWidth: 3
                implicitHeight: 18
                radius: 2
                color: event.modelData.color
            }

            Text {
                Layout.preferredWidth: 42
                text: event.modelData.allDay ? "All day" : Qt.formatTime(new Date(event.modelData.start), "HH:mm")
                color: Theme.text2
                font.family: Theme.font
                font.pixelSize: 12
                font.features: { "tnum": 1 }
            }

            Text {
                Layout.fillWidth: true
                text: event.modelData.title
                color: Theme.text
                elide: Text.ElideRight
                font.family: Theme.font
                font.pixelSize: Theme.fontSize
            }

            PillButton {
                visible: !event.past && !event.modelData.allDay && event.modelData.link !== ""
                primary: event.live && event.modelData.call
                text: event.modelData.call ? "Join" : "Open"
                onClicked: Agenda.join(event.modelData)
            }
        }
    }

    Separator {}

    Text {
        Layout.fillWidth: true
        Layout.leftMargin: 12
        Layout.bottomMargin: 6
        text: `${Qt.formatDate(root.today, "dddd, d MMMM yyyy")} · Week ${root.isoWeek(root.today)}`
        color: Theme.text2
        font.family: Theme.font
        font.pixelSize: 12
    }
}
