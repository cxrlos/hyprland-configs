pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Which dropdown is open; at most one at a time.
Singleton {
    id: root

    property string open: ""

    // A click on the anchor icon first dismisses the popup (focus grab), then lands as a
    // toggle; ignoring a reopen right after a dismissal keeps that click a plain close.
    property string lastClosed: ""
    property real lastClosedAt: 0

    function toggle(name: string): void {
        if (open === name)
            open = "";
        else if (open !== "" || !(lastClosed === name && Date.now() - lastClosedAt < 300))
            show(name);
    }

    // Opens a dropdown unless it already is (a Bluetooth pairing request opens its own).
    function show(name: string): void {
        if (open === name)
            return;
        if (open !== "") {
            // Unmap the current popup before mapping the next, or Wayland sees two grabs.
            open = "";
            Qt.callLater(() => open = name);
        } else {
            open = name;
        }
    }

    function dismissed(name: string): void {
        if (open !== name)
            return;
        open = "";
        lastClosed = name;
        lastClosedAt = Date.now();
    }

    IpcHandler {
        target: "dropdown"

        function toggle(name: string): void {
            root.toggle(name);
        }
    }
}
