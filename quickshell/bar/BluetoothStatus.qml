import QtQuick
import Quickshell.Bluetooth
import qs.dropdowns
import qs.widgets

BarIcon {
    id: root

    readonly property BluetoothAdapter adapter: Bluetooth.defaultAdapter
    readonly property bool powered: adapter?.enabled ?? false
    readonly property bool connected: adapter?.devices.values.some(d => d.connected) ?? false

    glyph: !powered ? "" : connected ? "" : ""
    dimmed: !powered
    highlighted: menu.shown

    onClicked: DropdownState.toggle("bluetooth")

    BluetoothDropdown {
        id: menu

        anchorItem: root
    }
}
