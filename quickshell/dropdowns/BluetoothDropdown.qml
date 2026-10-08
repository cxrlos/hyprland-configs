import QtQuick
import QtQuick.Layouts
import Quickshell.Bluetooth
import qs
import qs.widgets

Dropdown {
    id: root

    readonly property BluetoothAdapter adapter: Bluetooth.defaultAdapter
    readonly property var devices: adapter?.devices.values ?? []
    readonly property var paired: devices.filter(d => d.paired).sort((a, b) => b.connected - a.connected)
    // Unnamed LE beacons fall back to their address as a name; only list real devices.
    readonly property var nearby: devices.filter(d => !d.paired && d.deviceName !== "")

    // Maps BlueZ's freedesktop icon names to Material Symbols.
    function glyph(device): string {
        const icon = device.icon;
        if (icon.includes("headset") || icon.includes("headphones"))
            return "";
        if (icon.includes("gaming"))
            return "";
        if (icon.includes("keyboard"))
            return "";
        if (icon.includes("mouse"))
            return "";
        if (icon.includes("phone"))
            return "";
        if (icon.includes("speaker") || icon.includes("audio"))
            return "";
        return "";
    }

    function status(device): string {
        switch (device.state) {
        case BluetoothDeviceState.Connecting:
            return "Connecting…";
        case BluetoothDeviceState.Disconnecting:
            return "Disconnecting…";
        case BluetoothDeviceState.Connected:
            return device.batteryAvailable ? `Connected · ${Math.round(device.battery * 100)}%` : "Connected";
        default:
            return "";
        }
    }

    name: "bluetooth"

    Binding {
        when: root.adapter !== null
        target: root.adapter
        property: "discovering"
        value: root.shown && (root.adapter?.enabled ?? false)
    }

    PanelHeader {
        title: "Bluetooth"

        Switch {
            checked: root.adapter?.enabled ?? false
            onToggled: if (root.adapter) root.adapter.enabled = !root.adapter.enabled
        }
    }

    // A request from the pairing agent (widgets/BluetoothAgent.qml): Enter accepts, Esc refuses;
    // closing the dropdown leaves it waiting until bluetoothd gives up on it.
    ColumnLayout {
        id: prompt

        readonly property var request: BluetoothAgent.request
        readonly property string kind: request?.kind ?? ""
        readonly property bool typed: kind === "pin" || kind === "passkey"

        function submit(): void {
            if (kind === "display" || (typed && field.text === ""))
                return;
            BluetoothAgent.answer(true, field.text);
        }

        // Focus moves in and back out explicitly: a focus binding turning false would leave
        // nothing focused, and Esc would no longer reach the dropdown.
        function takeFocus(): void {
            if (visible)
                (typed ? field : prompt).forceActiveFocus();
            else
                parent?.forceActiveFocus();
        }

        visible: request !== null
        onVisibleChanged: takeFocus()
        onTypedChanged: takeFocus()
        Layout.fillWidth: true
        spacing: 0
        Keys.onReturnPressed: submit()
        Keys.onEnterPressed: submit()
        Keys.onEscapePressed: BluetoothAgent.answer(false, "")

        MenuRow {
            glyph: BluetoothAgent.device ? root.glyph(BluetoothAgent.device) : ""
            title: prompt.request?.name ?? ""
            subtitle: prompt.kind === "service" ? "Connection request" : "Pairing request"
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.leftMargin: 46
            Layout.rightMargin: 10
            Layout.bottomMargin: 8
            spacing: 8

            Text {
                Layout.fillWidth: true
                wrapMode: Text.WordWrap
                color: Theme.text2
                font.family: Theme.font
                font.pixelSize: 12
                text: {
                    switch (prompt.kind) {
                    case "confirm":
                        return "Pair only if the device shows this same code.";
                    case "pair":
                        return "It wants to pair with this computer.";
                    case "pin":
                        return "Enter its PIN (often 0000), or choose one and type it on the device too.";
                    case "passkey":
                        return "Enter the code the device shows.";
                    case "service":
                        return prompt.request.service ? `Allow it to connect for ${prompt.request.service}?` : "Allow it to connect?";
                    default:
                        return "Type this code on the device, then press Enter.";
                    }
                }
            }

            // The code to compare or type; digits a keyboard has already sent turn sage.
            Row {
                visible: (prompt.request?.code ?? "") !== ""
                spacing: 3

                Repeater {
                    model: (prompt.request?.code ?? "").split("")

                    Text {
                        required property string modelData
                        required property int index

                        text: modelData
                        color: index < (prompt.request?.entered ?? 0) ? Theme.accent : Theme.text
                        font.family: Theme.font
                        font.pixelSize: 24
                        font.weight: Font.DemiBold
                    }
                }
            }

            Rectangle {
                visible: prompt.typed
                Layout.fillWidth: true
                implicitHeight: 30
                radius: 8
                color: Qt.rgba(1, 1, 1, 0.06)
                border.width: 1
                border.color: field.activeFocus ? Theme.accent : Theme.hair

                TextInput {
                    id: field

                    anchors.fill: parent
                    anchors.leftMargin: 10
                    anchors.rightMargin: 10
                    verticalAlignment: TextInput.AlignVCenter
                    maximumLength: prompt.kind === "pin" ? 16 : 6
                    validator: RegularExpressionValidator {
                        regularExpression: prompt.kind === "pin" ? /.*/ : /[0-9]*/
                    }
                    color: Theme.text
                    selectionColor: Theme.accent
                    font.family: Theme.font
                    font.pixelSize: Theme.fontSize
                    onAccepted: prompt.submit()
                    onVisibleChanged: text = ""

                    Text {
                        visible: field.text === ""
                        anchors.verticalCenter: parent.verticalCenter
                        text: prompt.kind === "pin" ? "PIN" : "Code"
                        color: Theme.text3
                        font: field.font
                    }
                }
            }

            Row {
                Layout.alignment: Qt.AlignRight
                spacing: 6

                PillButton {
                    text: prompt.kind === "service" ? "Deny" : "Cancel"
                    onClicked: BluetoothAgent.answer(false, "")
                }
                PillButton {
                    visible: prompt.kind !== "display"
                    text: prompt.kind === "service" ? "Allow" : "Pair"
                    primary: true
                    onClicked: prompt.submit()
                }
            }
        }

        Separator {}
    }

    SectionLabel {
        visible: (root.adapter?.enabled ?? false) && root.paired.length > 0
        text: "My devices"
    }

    Repeater {
        model: root.adapter?.enabled ? root.paired : []

        MenuRow {
            required property var modelData

            glyph: root.glyph(modelData)
            title: modelData.name
            subtitle: root.status(modelData)
            badgeOn: modelData.connected
            onClicked: modelData.connected ? modelData.disconnect() : modelData.connect()
        }
    }

    SectionLabel {
        visible: root.adapter?.enabled ?? false
        text: root.nearby.length > 0 ? "Nearby devices" : "Searching for nearby devices…"
    }

    Repeater {
        model: root.adapter?.enabled ? root.nearby.slice(0, 6) : []

        MenuRow {
            required property var modelData

            glyph: root.glyph(modelData)
            title: modelData.name
            subtitle: modelData.pairing ? "Pairing…" : ""
            hint: modelData.pairing ? "" : "Pair"
            onClicked: modelData.pairing ? modelData.cancelPair() : modelData.pair()
        }
    }

    Item {
        implicitHeight: 4
    }
}
