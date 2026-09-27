import QtQuick
import QtQuick.Layouts
import qs
import qs.widgets

// The panel's top row: search glyph, borderless input and a hairline underneath.
ColumnLayout {
    id: root

    property alias text: input.text
    property alias placeholder: hint.text
    property string glyph: ""
    readonly property alias input: input

    signal submitted
    signal movedUp
    signal movedDown
    signal cancelled

    Layout.fillWidth: true
    spacing: 0

    RowLayout {
        Layout.fillWidth: true
        Layout.leftMargin: 11
        Layout.rightMargin: 11
        Layout.topMargin: 8
        Layout.bottomMargin: 10
        spacing: 12

        Glyph {
            visible: root.glyph !== ""
            glyph: root.glyph
            size: 22
            color: Theme.text2
        }

        TextInput {
            id: input

            Layout.fillWidth: true
            focus: true
            color: Theme.text
            selectionColor: Theme.accent
            selectedTextColor: Theme.accentInk
            font.family: Theme.font
            font.pixelSize: 18
            clip: true

            Keys.onReturnPressed: root.submitted()
            Keys.onEnterPressed: root.submitted()
            Keys.onUpPressed: root.movedUp()
            Keys.onDownPressed: root.movedDown()
            Keys.onEscapePressed: root.cancelled()

            Text {
                id: hint

                visible: input.text === ""
                color: Theme.text3
                font: input.font
            }
        }
    }

    Rectangle {
        Layout.fillWidth: true
        Layout.leftMargin: -7
        Layout.rightMargin: -7
        implicitHeight: 1
        color: Theme.hair
    }
}
