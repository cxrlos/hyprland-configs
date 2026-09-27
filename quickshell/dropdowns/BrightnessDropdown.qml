import QtQuick
import QtQuick.Layouts
import qs
import qs.widgets

Dropdown {
    id: root

    name: "brightness"
    panelWidth: 300
    onShownChanged: if (shown) Brightness.refresh()

    PanelHeader {
        title: "Display"
    }

    RowLayout {
        Layout.fillWidth: true
        Layout.leftMargin: 10
        Layout.rightMargin: 10
        Layout.bottomMargin: 8
        spacing: 10

        Slider {
            Layout.fillWidth: true
            glyph: ""
            value: Brightness.value
            onMoved: value => Brightness.set(value)
        }

        Text {
            Layout.preferredWidth: 34
            horizontalAlignment: Text.AlignRight
            text: Math.round(Brightness.value * 100) + "%"
            color: Theme.text2
            font.family: Theme.font
            font.pixelSize: 12
            font.features: { "tnum": 1 }
        }
    }
}
