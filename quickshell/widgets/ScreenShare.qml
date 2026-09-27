pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io

// Screen-share guard: while a screen or window is being shared, Do Not Disturb is on
// and the bar hides the playing track. A screenshot also reports a screencast for a
// split second, so sharing has to last a moment before the guard engages.
Singleton {
    id: root

    property int captures: 0
    property bool active: false
    // True when the guard, not the user, turned Do Not Disturb on.
    property bool ownsDnd: false

    onActiveChanged: {
        if (active) {
            dndQuery.running = true;
        } else if (ownsDnd) {
            Quickshell.execDetached(["swaync-client", "-df"]);
            ownsDnd = false;
        }
    }

    Connections {
        target: Hyprland

        function onRawEvent(event) {
            if (event.name !== "screencast")
                return;
            root.captures = Math.max(0, root.captures + (event.parse(2)[0] === "1" ? 1 : -1));
            if (root.captures === 0)
                root.active = false;
            else
                settle.restart();
        }
    }

    Timer {
        id: settle

        interval: 1500
        onTriggered: root.active = root.captures > 0
    }

    Process {
        id: dndQuery

        command: ["swaync-client", "-D"]
        stdout: StdioCollector {
            onStreamFinished: {
                if (!root.active || text.trim() !== "false")
                    return;
                Quickshell.execDetached(["swaync-client", "-dn"]);
                root.ownsDnd = true;
            }
        }
    }
}
