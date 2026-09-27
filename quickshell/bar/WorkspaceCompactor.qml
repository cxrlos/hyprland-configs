import QtQuick
import Quickshell
import Quickshell.Hyprland

// Closes workspace gaps. Hyprland destroys a workspace once it is empty and unfocused,
// i.e. when you leave it, which is the moment to shift the later ones left.
Scope {
    Connections {
        target: Hyprland

        function onRawEvent(event) {
            if (event.name === "destroyworkspacev2" && Number(event.parse(2)[0]) > 0)
                settle.restart();
        }
    }

    // Moving windows destroys more workspaces; wait for the burst to finish.
    Timer {
        id: settle

        interval: 150
        onTriggered: Quickshell.execDetached(["bash", "-c", "~/.config/scripts/compact-workspaces.sh"])
    }
}
