import QtQuick
import Quickshell.Services.Pipewire
import qs
import qs.dropdowns
import qs.widgets

BarIcon {
    id: root

    readonly property PwNode sink: Pipewire.defaultAudioSink
    readonly property bool muted: sink?.audio?.muted ?? false
    readonly property real volume: sink?.audio?.volume ?? 0

    glyph: muted ? "" : volume < 0.34 ? "" : volume < 0.67 ? "" : ""
    dimmed: muted
    highlighted: menu.shown

    onClicked: DropdownState.toggle("sound")

    SoundDropdown {
        id: menu

        anchorItem: root
    }

    PwObjectTracker {
        objects: [root.sink]
    }
}
