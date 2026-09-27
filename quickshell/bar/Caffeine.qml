import QtQuick
import Quickshell.Io
import qs
import qs.dropdowns
import qs.widgets

// Mode comes from `caffeine.sh status`; caffeine.sh calls `qs ipc call caffeine refresh`
// after every change, and the timer catches the Claude watcher ending on its own.
BarIcon {
    id: root

    property var status: ({})

    glyph: status.text ?? ""
    tint: status.class === "inactive" ? Theme.text : Theme.accent
    dimmed: status.class === "inactive"
    highlighted: menu.shown

    onClicked: DropdownState.toggle("caffeine")

    CaffeineDropdown {
        id: menu

        anchorItem: root
        mode: root.status.mode ?? "off"
    }

    Process {
        id: poll

        command: ["bash", "-c", "~/.config/scripts/caffeine.sh status"]
        stdout: StdioCollector {
            onStreamFinished: root.status = JSON.parse(text)
        }
    }

    Timer {
        interval: 10000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: poll.running = true
    }

    IpcHandler {
        target: "caffeine"

        function refresh(): void {
            poll.running = true;
        }
    }
}
