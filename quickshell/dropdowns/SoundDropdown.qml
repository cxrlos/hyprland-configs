import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Pipewire
import qs
import qs.widgets

Dropdown {
    id: root

    readonly property PwNode sink: Pipewire.defaultAudioSink
    readonly property var devices: Pipewire.nodes.values.filter(n => n.audio && !n.isStream)

    function label(node: PwNode): string {
        return node.nickname || node.description || node.name;
    }

    function icon(node: PwNode): string {
        const id = (node.name + " " + node.description).toLowerCase();
        if (!node.isSink)
            return "";
        if (id.includes("hdmi") || id.includes("displayport"))
            return "";
        if (id.includes("headphone") || id.includes("headset") || id.includes("bluez"))
            return "";
        return "";
    }

    name: "sound"

    PwObjectTracker {
        objects: root.devices
    }

    PanelHeader {
        title: "Sound"
    }

    RowLayout {
        Layout.fillWidth: true
        Layout.leftMargin: 4
        Layout.rightMargin: 10
        Layout.bottomMargin: 6
        spacing: 8

        BarIconButton {
            glyph: root.sink?.audio?.muted ? "" : ""
            onClicked: if (root.sink?.audio) root.sink.audio.muted = !root.sink.audio.muted
        }

        Slider {
            Layout.fillWidth: true
            value: root.sink?.audio?.muted ? 0 : root.sink?.audio?.volume ?? 0
            onMoved: value => {
                if (!root.sink?.audio)
                    return;
                root.sink.audio.muted = false;
                root.sink.audio.volume = value;
            }
        }

        Text {
            Layout.preferredWidth: 34
            horizontalAlignment: Text.AlignRight
            text: root.sink?.audio?.muted ? "Muted" : Math.round((root.sink?.audio?.volume ?? 0) * 100) + "%"
            color: Theme.text2
            font.family: Theme.font
            font.pixelSize: 12
            font.features: { "tnum": 1 }
        }
    }

    SectionLabel {
        text: "Output"
    }

    Repeater {
        model: root.devices.filter(n => n.isSink)

        MenuRow {
            required property PwNode modelData

            glyph: root.icon(modelData)
            title: root.label(modelData)
            badgeOn: modelData === Pipewire.defaultAudioSink
            checked: badgeOn
            onClicked: Pipewire.preferredDefaultAudioSink = modelData
        }
    }

    SectionLabel {
        text: "Input"
    }

    Repeater {
        model: root.devices.filter(n => !n.isSink)

        MenuRow {
            required property PwNode modelData

            glyph: root.icon(modelData)
            title: root.label(modelData)
            badgeOn: modelData === Pipewire.defaultAudioSource
            checked: badgeOn
            onClicked: Pipewire.preferredDefaultAudioSource = modelData
        }
    }

    Separator {}

    MenuRow {
        title: "Sound settings…"
        onClicked: {
            DropdownState.open = "";
            Quickshell.execDetached(["pavucontrol"]);
        }
    }
}
