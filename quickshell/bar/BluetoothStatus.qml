import QtQuick
import Quickshell.Bluetooth
import qs
import qs.dropdowns
import qs.widgets

BarIcon {
    id: root

    readonly property BluetoothAdapter adapter: Bluetooth.defaultAdapter
    readonly property bool powered: adapter?.enabled ?? false
    readonly property bool connected: adapter?.devices.values.some(d => d.connected) ?? false

    glyph: !powered ? "" : connected ? "" : ""
    // A pairing request waiting on the user (the dropdown stays shut while sharing the screen).
    tint: BluetoothAgent.request ? Theme.accent : Theme.text
    dimmed: !powered
    highlighted: menu.shown

    onClicked: DropdownState.toggle("bluetooth")

    BluetoothDropdown {
        id: menu

        anchorItem: root
    }
}
