import QtQuick
import qs

// A Material Symbols Rounded icon.
Text {
    property string glyph
    property int size: Theme.iconSize

    text: glyph
    color: Theme.text
    font.family: Theme.iconFont
    font.pixelSize: size
}
