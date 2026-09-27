import QtQuick
import QtQuick.Layouts
import qs
import qs.widgets

// Month grid, Monday first, paged with the chevrons; reopening returns to this month.
Dropdown {
    id: root

    required property date today

    property int offset: 0

    readonly property date first: new Date(today.getFullYear(), today.getMonth() + offset, 1)
    readonly property int lead: (first.getDay() + 6) % 7
    readonly property var days: Array.from({ length: 42 }, (_, i) => new Date(first.getFullYear(), first.getMonth(), i - lead + 1))

    function isoWeek(d: date): int {
        const t = new Date(Date.UTC(d.getFullYear(), d.getMonth(), d.getDate()));
        t.setUTCDate(t.getUTCDate() + 4 - (t.getUTCDay() || 7));
        return Math.ceil(((t - new Date(Date.UTC(t.getUTCFullYear(), 0, 1))) / 86400000 + 1) / 7);
    }

    name: "calendar"
    panelWidth: 300
    onShownChanged: offset = 0

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
                required property date modelData
                readonly property bool isToday: modelData.toDateString() === root.today.toDateString()

                Layout.fillWidth: true
                implicitHeight: 30
                radius: 15
                color: isToday ? Theme.accent : "transparent"

                Text {
                    anchors.centerIn: parent
                    text: parent.modelData.getDate()
                    color: parent.isToday ? Theme.accentInk
                         : parent.modelData.getMonth() === root.first.getMonth() ? Theme.text : Theme.text3
                    font.family: Theme.font
                    font.pixelSize: 13
                    font.weight: parent.isToday ? Font.DemiBold : Font.Normal
                    font.features: { "tnum": 1 }
                }
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
