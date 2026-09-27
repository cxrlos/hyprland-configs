import QtQuick
import QtQuick.Layouts
import qs

// Panel title with an optional control on the right (e.g. the Wi-Fi switch).
RowLayout {
    property alias title: label.text
    default property alias trailing: end.data

    Layout.fillWidth: true
    Layout.leftMargin: 10
    Layout.rightMargin: 10
    Layout.topMargin: 5
    Layout.bottomMargin: 4

    Text {
        id: label

        Layout.fillWidth: true
        color: Theme.text
        font.family: Theme.font
        font.pixelSize: Theme.fontSize
        font.weight: Font.DemiBold
    }

    Row {
        id: end
    }
}
