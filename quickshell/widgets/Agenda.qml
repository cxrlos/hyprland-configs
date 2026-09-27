pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io

// Today's events from scripts/calendar-feed.py (feeds listed in ~/.config/calendars.yaml),
// refreshed every 5 minutes and when the day rolls over. Only timed events from `bar: true`
// styles count as meetings for the bar.
Singleton {
    id: root

    property var events: []
    property date now: new Date()

    readonly property var meetings: events.filter(e => e.bar && !e.allDay)
    // Only a running call counts as current, so a long block (focus time) never hides the meetings inside it.
    readonly property var current: meetings.find(e => e.call && e.start <= now.getTime() && now.getTime() < e.end) ?? null
    readonly property var next: meetings.find(e => e.start > now.getTime()) ?? null
    readonly property int minutesToNext: next ? Math.ceil((next.start - now.getTime()) / 60000) : -1

    // Zen opens the link as a tab without raising itself, so focus follows explicitly.
    function join(event): void {
        if (!event?.link)
            return;
        Quickshell.execDetached(["xdg-open", event.link]);
        Hyprland.dispatch('hl.dsp.focus({ window = "class:^zen$" })');
    }

    IpcHandler {
        target: "agenda"

        function refresh(): void {
            feed.running = true;
        }
    }

    Process {
        id: feed

        running: true
        command: ["bash", "-c", "~/.config/scripts/calendar-feed.py"]
        stdout: StdioCollector {
            onStreamFinished: root.events = JSON.parse(text || "[]")
        }
    }

    Timer {
        interval: 30000
        running: true
        repeat: true
        onTriggered: {
            const previous = root.now;
            root.now = new Date();
            if (previous.toDateString() !== root.now.toDateString())
                feed.running = true;
        }
    }

    Timer {
        interval: 5 * 60000
        running: true
        repeat: true
        onTriggered: feed.running = true
    }
}
