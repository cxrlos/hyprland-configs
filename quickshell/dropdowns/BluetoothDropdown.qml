import QtQuick
import QtQuick.Layouts
import Quickshell.Bluetooth
import qs
import qs.widgets

Dropdown {
    id: root

    readonly property BluetoothAdapter adapter: Bluetooth.defaultAdapter
    readonly property var devices: adapter?.devices.values ?? []
    readonly property var paired: devices.filter(d => d.paired).sort((a, b) => b.connected - a.connected)
    // Unnamed LE beacons fall back to their address as a name; only list real devices.
    readonly property var nearby: devices.filter(d => !d.paired && d.deviceName !== "")

    // Maps BlueZ's freedesktop icon names to Material Symbols.
    function glyph(device): string {
        const icon = device.icon;
        if (icon.includes("headset") || icon.includes("headphones"))
            return "";
        if (icon.includes("gaming"))
            return "";
        if (icon.includes("keyboard"))
            return "";
        if (icon.includes("mouse"))
            return "";
        if (icon.includes("phone"))
            return "";
        if (icon.includes("speaker") || icon.includes("audio"))
            return "";
        return "";
    }

    function status(device): string {
        switch (device.state) {
        case BluetoothDeviceState.Connecting:
            return "Connecting…";
        case BluetoothDeviceState.Disconnecting:
            return "Disconnecting…";
        case BluetoothDeviceState.Connected:
            return device.batteryAvailable ? `Connected · ${Math.round(device.battery * 100)}%` : "Connected";
        default:
            return "";
        }
    }

    name: "bluetooth"

    Binding {
        when: root.adapter !== null
        target: root.adapter
        property: "discovering"
        value: root.shown && (root.adapter?.enabled ?? false)
    }

    PanelHeader {
        title: "Bluetooth"

        Switch {
            checked: root.adapter?.enabled ?? false
            onToggled: if (root.adapter) root.adapter.enabled = !root.adapter.enabled
        }
    }

    SectionLabel {
        visible: (root.adapter?.enabled ?? false) && root.paired.length > 0
        text: "My devices"
    }

    Repeater {
        model: root.adapter?.enabled ? root.paired : []

        MenuRow {
            required property var modelData

            glyph: root.glyph(modelData)
            title: modelData.name
            subtitle: root.status(modelData)
            badgeOn: modelData.connected
            onClicked: modelData.connected ? modelData.disconnect() : modelData.connect()
        }
    }

    SectionLabel {
        visible: root.adapter?.enabled ?? false
        text: root.nearby.length > 0 ? "Nearby devices" : "Searching for nearby devices…"
    }

    Repeater {
        model: root.adapter?.enabled ? root.nearby.slice(0, 6) : []

        MenuRow {
            required property var modelData

            glyph: root.glyph(modelData)
            title: modelData.name
            subtitle: modelData.pairing ? "Pairing…" : ""
            hint: modelData.pairing ? "" : "Pair"
            onClicked: modelData.pairing ? modelData.cancelPair() : modelData.pair()
        }
    }

    Item {
        implicitHeight: 4
    }
}
