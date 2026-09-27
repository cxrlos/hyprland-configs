import QtQuick
import Quickshell
import Quickshell.Services.UPower
import qs
import qs.dropdowns
import qs.widgets

// Laptop only: icon + percentage, hidden without a laptop battery. Warns once at 10%
// and again at 5% while discharging.
Item {
    id: root

    readonly property UPowerDevice battery: UPower.displayDevice
    readonly property real percent: (battery?.percentage ?? 0) * 100
    readonly property bool charging: battery?.state === UPowerDeviceState.Charging
                                  || battery?.state === UPowerDeviceState.FullyCharged
    readonly property bool low: !charging && percent <= 10

    property int warnedAt: 100

    visible: battery?.isLaptopBattery ?? false
    implicitWidth: row.implicitWidth + 14
    implicitHeight: 24

    onPercentChanged: {
        if (charging) {
            warnedAt = 100;
            return;
        }
        for (const threshold of [5, 10]) {
            if (percent <= threshold && warnedAt > threshold) {
                warnedAt = threshold;
                Quickshell.execDetached(["notify-send", "-a", "Battery", "-u", "critical", "-i", "battery-caution",
                    `Battery at ${Math.round(percent)}%`, "Plug in soon"]);
                return;
            }
        }
    }

    Rectangle {
        anchors.fill: parent
        radius: Theme.radiusSmall
        color: DropdownState.open === "battery" ? Qt.rgba(1, 1, 1, 0.14) : area.containsMouse ? Theme.hover : "transparent"
    }

    Row {
        id: row

        anchors.centerIn: parent
        spacing: 4

        Glyph {
            anchors.verticalCenter: parent.verticalCenter
            glyph: root.charging ? ""
                 : root.percent > 90 ? "" : root.percent > 60 ? "" : root.percent > 30 ? "" : root.percent > 10 ? "" : ""
            color: root.low ? Theme.critical : Theme.text
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: Math.round(root.percent) + "%"
            color: root.low ? Theme.critical : Theme.text2
            font.family: Theme.font
            font.pixelSize: 12
            font.features: { "tnum": 1 }
        }
    }

    MouseArea {
        id: area

        anchors.fill: parent
        hoverEnabled: true
        onClicked: DropdownState.toggle("battery")
    }

    // Created only on laptops, so the desktop never starts the power-profiles client.
    LazyLoader {
        active: root.visible

        BatteryDropdown {
            anchorItem: root
        }
    }
}
