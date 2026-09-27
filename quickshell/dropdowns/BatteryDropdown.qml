import QtQuick
import QtQuick.Layouts
import Quickshell.Services.UPower
import qs
import qs.widgets

Dropdown {
    id: root

    readonly property UPowerDevice battery: UPower.displayDevice

    function duration(seconds: real): string {
        const minutes = Math.round(seconds / 60);
        const h = Math.floor(minutes / 60);
        return h > 0 ? `${h} h ${minutes % 60} min` : `${minutes} min`;
    }

    readonly property string status: {
        switch (battery?.state) {
        case UPowerDeviceState.Charging:
            return battery.timeToFull > 0 ? `Charging · ${duration(battery.timeToFull)} until full` : "Charging";
        case UPowerDeviceState.Discharging:
            return battery.timeToEmpty > 0 ? `On battery · ${duration(battery.timeToEmpty)} left` : "On battery";
        case UPowerDeviceState.FullyCharged:
            return "Fully charged";
        case UPowerDeviceState.PendingCharge:
            return "Plugged in, not charging";
        default:
            return "";
        }
    }

    name: "battery"
    panelWidth: 300

    PanelHeader {
        title: "Battery"

        Text {
            text: Math.round((root.battery?.percentage ?? 0) * 100) + "%"
            color: Theme.text2
            font.family: Theme.font
            font.pixelSize: Theme.fontSize
            font.features: { "tnum": 1 }
        }
    }

    Text {
        Layout.fillWidth: true
        Layout.leftMargin: 10
        Layout.bottomMargin: 4
        text: root.status
        color: Theme.text2
        font.family: Theme.font
        font.pixelSize: 12
    }

    Separator {}

    SectionLabel {
        text: "Power mode"
    }

    MenuRow {
        glyph: ""
        title: "Power saver"
        badgeOn: PowerProfiles.profile === PowerProfile.PowerSaver
        checked: badgeOn
        onClicked: PowerProfiles.profile = PowerProfile.PowerSaver
    }

    MenuRow {
        glyph: ""
        title: "Balanced"
        badgeOn: PowerProfiles.profile === PowerProfile.Balanced
        checked: badgeOn
        onClicked: PowerProfiles.profile = PowerProfile.Balanced
    }

    MenuRow {
        visible: PowerProfiles.hasPerformanceProfile
        glyph: ""
        title: "Performance"
        badgeOn: PowerProfiles.profile === PowerProfile.Performance
        checked: badgeOn
        onClicked: PowerProfiles.profile = PowerProfile.Performance
    }

    Item {
        implicitHeight: 4
    }
}
