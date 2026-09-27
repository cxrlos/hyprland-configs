pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.widgets

// Which centred panel (clipboard, cheatsheet) is open; keybinds reach it over IPC.
Singleton {
    id: root

    property string open: ""

    function toggle(name: string): void {
        DropdownState.open = "";
        open = open === name ? "" : name;
    }

    function close(name: string): void {
        if (open === name)
            open = "";
    }

    IpcHandler {
        target: "panel"

        function toggle(name: string): void {
            root.toggle(name);
        }
    }
}
