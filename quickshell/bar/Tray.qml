import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Services.SystemTray
import Quickshell.Widgets
import qs

// Left click focuses the app's first window (switching workspace), or opens the app on an
// empty workspace when it only lives in the tray; right click shows its menu.
Row {
    id: root

    required property QsWindow window

    function focusOrOpen(item: SystemTrayItem): void {
        // Tray ids carry suffixes ("Slack_status_icon_1"); the leading word matches the app id.
        const key = ((item.id || item.title).toLowerCase().match(/^[a-z]+/) ?? [""])[0];
        const open = key !== "" && Hyprland.toplevels.values.find(t => (t.wayland?.appId ?? "").toLowerCase().startsWith(key));
        if (open) {
            Hyprland.dispatch(`hl.dsp.focus({ window = "address:0x${open.address}" })`);
        } else {
            Hyprland.dispatch('hl.dsp.focus({ workspace = "empty" })');
            item.activate();
        }
    }

    spacing: 2

    Repeater {
        model: SystemTray.items

        Item {
            id: entry

            required property SystemTrayItem modelData

            implicitWidth: 28
            implicitHeight: 24

            Rectangle {
                anchors.fill: parent
                radius: Theme.radiusSmall
                color: area.containsMouse ? Theme.hover : "transparent"
            }

            IconImage {
                anchors.centerIn: parent
                implicitSize: 15
                source: entry.modelData.icon
            }

            MouseArea {
                id: area

                anchors.fill: parent
                hoverEnabled: true
                acceptedButtons: Qt.LeftButton | Qt.RightButton
                onClicked: mouse => {
                    const item = entry.modelData;
                    if (mouse.button === Qt.LeftButton && !item.onlyMenu) {
                        root.focusOrOpen(item);
                        return;
                    }
                    const pos = entry.mapToItem(null, 0, entry.height + 6);
                    item.display(root.window, pos.x, pos.y);
                }
            }
        }
    }
}
