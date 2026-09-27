import QtQuick
import Quickshell.Networking
import qs
import qs.dropdowns
import qs.widgets

BarIcon {
    id: root

    readonly property var device: Networking.devices.values.find(d => d.connected) ?? null
    readonly property var wifi: device?.type === DeviceType.Wifi
        ? device.networks.values.find(n => n.connected) ?? null
        : null
    readonly property real signal: wifi?.signalStrength ?? 0

    glyph: !device ? ""
         : device.type === DeviceType.Wired ? ""
         : signal < 0.25 ? "" : signal < 0.5 ? "" : signal < 0.75 ? "" : ""
    tint: device ? Theme.text : Theme.critical
    highlighted: menu.shown

    onClicked: DropdownState.toggle("wifi")

    WifiDropdown {
        id: menu

        anchorItem: root
    }
}
