import QtQuick
import QtQuick.Layouts
import Quickshell
import qs
import qs.widgets

// Reboot and Shut down ask for a second click within three seconds.
Dropdown {
    id: root

    property string confirming: ""

    function run(command: string): void {
        DropdownState.open = "";
        Quickshell.execDetached(["bash", "-c", command]);
    }

    function confirm(action: string, command: string): void {
        if (confirming === action) {
            run(command);
        } else {
            confirming = action;
            reset.restart();
        }
    }

    name: "power"
    panelWidth: 240
    onShownChanged: confirming = ""

    Timer {
        id: reset

        interval: 3000
        onTriggered: root.confirming = ""
    }

    MenuRow {
        glyph: ""
        badge: false
        title: "Lock"
        onClicked: root.run("hyprlock")
    }

    // The delay lets the click release land before sleep, or it wakes the PC right away.
    MenuRow {
        glyph: ""
        badge: false
        title: "Suspend"
        onClicked: root.run("sleep 1 && systemctl suspend")
    }

    Separator {}

    MenuRow {
        glyph: ""
        badge: false
        danger: true
        title: root.confirming === "reboot" ? "Click again to reboot" : "Reboot…"
        onClicked: root.confirm("reboot", "systemctl reboot")
    }

    MenuRow {
        glyph: ""
        badge: false
        danger: true
        title: root.confirming === "poweroff" ? "Click again to shut down" : "Shut down…"
        onClicked: root.confirm("poweroff", "systemctl poweroff")
    }
}
