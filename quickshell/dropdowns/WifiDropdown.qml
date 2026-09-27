import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Networking
import qs
import qs.widgets

Dropdown {
    id: root

    readonly property var device: Networking.devices.values.find(d => d.type === DeviceType.Wifi) ?? null
    readonly property var networks: device?.networks.values ?? []
    readonly property var current: networks.find(n => n.connected) ?? null
    readonly property var others: networks
        .filter(n => !n.connected && n.name !== "")
        .sort((a, b) => b.signalStrength - a.signalStrength)
        .slice(0, 8)

    // Name of the network whose inline password field is open.
    property string asking: ""

    function bars(strength: real): string {
        return strength < 0.25 ? "" : strength < 0.5 ? "" : strength < 0.75 ? "" : "";
    }

    function secured(network): bool {
        return network.security !== WifiSecurityType.Open && network.security !== WifiSecurityType.Owe;
    }

    name: "wifi"
    onShownChanged: asking = ""

    Binding {
        when: root.device !== null
        target: root.device
        property: "scannerEnabled"
        value: root.shown
    }

    PanelHeader {
        title: "Wi-Fi"

        Switch {
            checked: Networking.wifiEnabled
            onToggled: Networking.wifiEnabled = !Networking.wifiEnabled
        }
    }

    MenuRow {
        visible: root.current !== null
        glyph: ""
        badgeOn: true
        title: root.current?.name ?? ""
        subtitle: "Connected"

        Glyph {
            visible: root.current !== null && root.secured(root.current)
            glyph: ""
            size: 16
            color: Theme.text2
        }
    }

    SectionLabel {
        visible: Networking.wifiEnabled && root.others.length > 0
        text: "Other networks"
    }

    Repeater {
        model: Networking.wifiEnabled ? root.others : []

        ColumnLayout {
            id: entry

            required property var modelData
            readonly property bool askingHere: root.asking === modelData.name

            Layout.fillWidth: true
            spacing: 0

            MenuRow {
                glyph: root.bars(entry.modelData.signalStrength)
                title: entry.modelData.name
                subtitle: entry.modelData.stateChanging ? "Connecting…" : ""
                onClicked: {
                    const network = entry.modelData;
                    if (network.known || !root.secured(network))
                        network.connect();
                    else
                        root.asking = entry.askingHere ? "" : network.name;
                }

                Glyph {
                    visible: root.secured(entry.modelData)
                    glyph: ""
                    size: 16
                    color: Theme.text2
                }
            }

            ColumnLayout {
                id: form

                visible: entry.askingHere
                Layout.fillWidth: true
                Layout.leftMargin: 46
                Layout.rightMargin: 10
                Layout.bottomMargin: 8
                spacing: 8

                function submit(): void {
                    if (password.text === "")
                        return;
                    entry.modelData.connectWithPsk(password.text);
                    root.asking = "";
                }

                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 30
                    radius: 8
                    color: Qt.rgba(1, 1, 1, 0.06)
                    border.width: 1
                    border.color: password.activeFocus ? Theme.accent : Theme.hair

                    TextInput {
                        id: password

                        anchors.fill: parent
                        anchors.leftMargin: 10
                        anchors.rightMargin: 10
                        verticalAlignment: TextInput.AlignVCenter
                        echoMode: TextInput.Password
                        focus: entry.askingHere
                        color: Theme.text
                        selectionColor: Theme.accent
                        font.family: Theme.font
                        font.pixelSize: Theme.fontSize
                        onAccepted: form.submit()
                        onVisibleChanged: text = ""

                        Text {
                            visible: password.text === ""
                            anchors.verticalCenter: parent.verticalCenter
                            text: "Password"
                            color: Theme.text3
                            font: password.font
                        }
                    }
                }

                Row {
                    Layout.alignment: Qt.AlignRight
                    spacing: 6

                    PillButton {
                        text: "Cancel"
                        onClicked: root.asking = ""
                    }
                    PillButton {
                        text: "Connect"
                        primary: true
                        onClicked: form.submit()
                    }
                }
            }
        }
    }

    Separator {}

    MenuRow {
        title: "Network settings…"
        onClicked: {
            DropdownState.open = "";
            Quickshell.execDetached(["nm-connection-editor"]);
        }
    }
}
