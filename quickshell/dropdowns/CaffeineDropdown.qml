import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs
import qs.widgets

Dropdown {
    id: root

    required property string mode
    // Epoch seconds a timed caffeine ends at; 0 when it runs until turned off.
    property real ends: 0

    property int working: 0
    property int sessions: 0

    function choose(next: string): void {
        DropdownState.open = "";
        Quickshell.execDetached(["bash", "-c", "~/.config/scripts/caffeine.sh " + next]);
    }

    name: "caffeine"
    panelWidth: 340
    onShownChanged: if (shown) countSessions.running = true

    Process {
        id: countSessions

        command: ["bash", "-c", "~/.config/scripts/claude-busy.sh count"]
        stdout: StdioCollector {
            onStreamFinished: {
                const [busy, open] = text.trim().split(" ").map(Number);
                root.working = busy || 0;
                root.sessions = open || 0;
            }
        }
    }

    PanelHeader {
        title: "Idle"
    }

    MenuRow {
        glyph: ""
        title: "Auto-lock"
        subtitle: "Lock after 10 minutes idle"
        badgeOn: root.mode === "off"
        checked: badgeOn
        onClicked: root.choose("off")
    }

    MenuRow {
        glyph: ""
        title: "Caffeine"
        subtitle: root.mode === "on" && root.ends > 0
            ? `Stay awake until ${Qt.formatDateTime(new Date(root.ends * 1000), "HH:mm")}`
            : "Stay awake until turned off"
        badgeOn: root.mode === "on"
        checked: badgeOn
        onClicked: root.choose("on")
    }

    // Timed caffeine, under the row titles (10 margin + 26 badge + 10 gap); any one restarts the clock.
    RowLayout {
        Layout.leftMargin: 46
        Layout.bottomMargin: 4
        spacing: 6

        Repeater {
            model: [
                { label: "30 min", minutes: 30 },
                { label: "1 hour", minutes: 60 },
                { label: "2 hours", minutes: 120 }
            ]

            PillButton {
                required property var modelData

                text: modelData.label
                onClicked: root.choose("on " + modelData.minutes)
            }
        }
    }

    MenuRow {
        glyph: ""
        title: "Caffeine while Claude works"
        subtitle: "Stay awake while a Claude session is working"
        badgeOn: root.mode === "claude"
        checked: badgeOn
        enabled: root.working > 0 || root.mode === "claude"
        onClicked: root.choose("claude")
    }

    Separator {}

    Text {
        Layout.fillWidth: true
        Layout.leftMargin: 12
        Layout.bottomMargin: 6
        text: root.sessions === 0 ? "No Claude sessions open"
            : `Claude sessions: ${root.working} working · ${root.sessions - root.working} idle`
        color: Theme.text2
        font.family: Theme.font
        font.pixelSize: 12
    }
}
