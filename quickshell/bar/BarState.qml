pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Bar visibility, shared by every screen's bar and toggled with Super+B.
Singleton {
    id: root

    property bool visible: true

    IpcHandler {
        target: "bar"

        function toggle(): void {
            root.visible = !root.visible;
        }
    }
}
