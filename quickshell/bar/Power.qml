import QtQuick
import qs.dropdowns
import qs.widgets

BarIcon {
    id: root

    glyph: ""
    highlighted: menu.shown

    onClicked: DropdownState.toggle("power")

    PowerDropdown {
        id: menu

        anchorItem: root
    }
}
