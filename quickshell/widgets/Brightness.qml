pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Laptop backlight through brightnessctl. On machines without a backlight (or without
// brightnessctl) the first read fails and `available` stays false, hiding the bar item.
Singleton {
    id: root

    property bool available: false
    property real value: 0

    // Emitted for keyboard changes, which show the level OSD.
    signal stepped

    function refresh(): void {
        read.running = true;
    }

    function set(fraction: real): void {
        value = Math.max(0.01, Math.min(1, fraction));
        Quickshell.execDetached(["brightnessctl", "-q", "-c", "backlight", "set", Math.round(value * 100) + "%"]);
    }

    function step(delta: real): void {
        if (!available)
            return;
        set(value + delta);
        stepped();
    }

    Process {
        id: read

        running: true
        command: ["brightnessctl", "-m", "-c", "backlight", "info"]
        stdout: StdioCollector {
            onStreamFinished: {
                // device,class,current,percent,max
                const fields = text.trim().split(",");
                if (fields.length < 5)
                    return;
                root.available = true;
                root.value = Number(fields[2]) / Number(fields[4]);
            }
        }
    }

    IpcHandler {
        target: "brightness"

        function up(): void {
            root.step(0.05);
        }
        function down(): void {
            root.step(-0.05);
        }
    }
}
