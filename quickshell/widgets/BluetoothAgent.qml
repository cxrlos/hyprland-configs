pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Bluetooth
import Quickshell.Io

// BlueZ pairing agent (scripts/bluetooth-agent.py): Quickshell has none of its own. A pairing
// or connection request opens the Bluetooth dropdown, which answers it, and turns the bar icon
// sage until it is answered or bluetoothd gives up (60 s, a refusal). While the screen is
// shared the dropdown stays shut and only the icon shows it.
Singleton {
    id: root

    // {id, kind: confirm|pair|pin|passkey|service|display, device, name, code?, entered?, service?};
    // a display (a code to type on a keyboard) has no id, as nothing waits on it.
    property var request: null
    readonly property BluetoothDevice device: request ? Bluetooth.devices.values.find(d => d.dbusPath === request.device) ?? null : null

    function answer(accept: bool, value: string): void {
        const request = root.request;
        if (!request)
            return;
        root.request = null;
        if (request.id !== undefined)
            agent.write(JSON.stringify({ id: request.id, accept: accept, value: value }) + "\n");
        else if (!accept)
            root.device?.cancelPair();
    }

    Process {
        id: agent

        running: true
        stdinEnabled: true
        command: ["bash", "-c", "~/.config/scripts/bluetooth-agent.py"]
        stdout: SplitParser {
            onRead: line => {
                const message = JSON.parse(line);
                root.request = message.kind === "cancel" ? null : message;
                if (!root.request)
                    return;
                if (root.request.kind === "display")
                    shown.restart();
                if (!ScreenShare.active)
                    DropdownState.show("bluetooth");
            }
        }
        onExited: {
            root.request = null;
            restart.start();
        }
    }

    Timer {
        id: restart

        interval: 10000
        onTriggered: agent.running = true
    }

    // A shown code has no request for bluetoothd to cancel: it goes when the device finishes
    // pairing either way, or after a minute without news.
    Connections {
        target: root.request?.kind === "display" ? root.device : null

        function onPairingChanged(): void {
            if (!root.device.pairing)
                root.request = null;
        }

        function onPairedChanged(): void {
            root.request = null;
        }
    }

    Timer {
        id: shown

        interval: 60000
        onTriggered: if (root.request?.kind === "display") root.request = null
    }
}
