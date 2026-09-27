import QtQuick
import Quickshell.Io
import qs
import qs.dropdowns
import qs.widgets

// Metrics come from system-status.sh (faster while the dropdown is open); the icon
// turns sage while updates are pending.
BarIcon {
    id: root

    property var status: ({})

    glyph: ""
    tint: status.updates > 0 ? Theme.accent : Theme.text
    highlighted: menu.shown

    onClicked: DropdownState.toggle("system")

    SystemDropdown {
        id: menu

        anchorItem: root
        status: root.status
    }

    Process {
        id: poll

        command: ["bash", "-c", "~/.config/scripts/system-status.sh"]
        stdout: StdioCollector {
            onStreamFinished: root.status = JSON.parse(text)
        }
    }

    Timer {
        interval: menu.shown ? 2000 : 5000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: poll.running = true
    }
}
