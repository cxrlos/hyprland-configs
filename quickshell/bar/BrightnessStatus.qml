import QtQuick
import qs.dropdowns
import qs.widgets

// Laptop only: hidden when there is no backlight.
BarIcon {
    id: root

    visible: Brightness.available
    glyph: Brightness.value < 0.34 ? "" : Brightness.value < 0.67 ? "" : ""
    highlighted: menu.shown

    onClicked: DropdownState.toggle("brightness")

    BrightnessDropdown {
        id: menu

        anchorItem: root
    }
}
