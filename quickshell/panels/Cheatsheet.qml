import QtQuick
import QtQuick.Layouts
import qs
import qs.widgets

// Keybind reference. Mirror every bind in hypr/keybinds.lua here.
Panel {
    id: root

    readonly property var groups: [
        { title: "Applications", binds: [
            ["Super Return", "Terminal"],
            ["Super Space", "App launcher"],
            ["Super W", "Browser (Zen)"],
            ["Super Shift W", "Private browser window"],
            ["Super Y", "Files (Thunar)"],
            ["Super N", "Obsidian"],
            ["Super Shift O", "Window switcher"],
        ] },
        { title: "Windows", binds: [
            ["Super Q", "Close window"],
            ["Super F", "Fullscreen"],
            ["Super Shift V", "Float / tile"],
            ["Super Tab", "Cycle windows (Shift reverses)"],
            ["Super HJKL", "Focus left / down / up / right"],
            ["Super Shift HJKL", "Move window"],
            ["Super R then HJKL", "Resize · Esc or Return exits"],
            ["Super LMB / RMB", "Drag to move / resize"],
        ] },
        { title: "Workspaces", binds: [
            ["Super 1–9 0", "Go to workspace 1–10"],
            ["Super Shift 1–9 0", "Move window to workspace"],
            ["Super D", "Empty workspace"],
            ["Super `", "Terminal scratchpad"],
            ["Super B", "Hide / show the bar"],
        ] },
        { title: "Capture", binds: [
            ["Super Shift A", "Screenshot an area"],
            ["Super Shift F", "Screenshot the screen"],
            ["Super Shift R", "Record an area (again to stop)"],
            ["Super Shift P", "Pick a colour"],
        ] },
        { title: "Clipboard", binds: [
            ["Super C", "Copy selection to clipboard"],
            ["Super V", "Clipboard history"],
        ] },
        { title: "System", binds: [
            ["Super Escape", "Lock"],
            ["Super Shift M", "Power menu"],
            ["Super Shift I", "Wallpaper"],
            ["Super Shift /", "This cheatsheet"],
        ] },
        { title: "Media keys", binds: [
            ["Vol+ / Vol−", "Volume ±5%"],
            ["Bright+ / Bright−", "Screen brightness ±5% (laptop)"],
            ["Mute", "Mute output"],
            ["Mic", "Mute microphone"],
            ["Play Next Prev", "Media controls"],
        ] },
    ]

    readonly property string query: search.text.toLowerCase()

    function matches(bind): bool {
        return query === "" || bind[0].toLowerCase().includes(query) || bind[1].toLowerCase().includes(query);
    }

    name: "cheatsheet"
    panelWidth: 860
    onShownChanged: {
        search.text = "";
        if (shown)
            search.input.forceActiveFocus();
    }

    SearchField {
        id: search

        placeholder: "Search keybinds"
        onCancelled: PanelState.close(root.name)
    }

    GridLayout {
        Layout.fillWidth: true
        Layout.margins: 8
        columns: 2
        columnSpacing: 28
        rowSpacing: 10

        Repeater {
            model: root.groups.filter(g => g.binds.some(b => root.matches(b)))

            ColumnLayout {
                id: group

                required property var modelData

                Layout.fillWidth: true
                Layout.preferredWidth: 1
                Layout.alignment: Qt.AlignTop
                spacing: 4

                SectionLabel {
                    Layout.leftMargin: 2
                    text: group.modelData.title
                }

                Repeater {
                    model: group.modelData.binds.filter(b => root.matches(b))

                    RowLayout {
                        id: bind

                        required property var modelData

                        Layout.fillWidth: true
                        spacing: 10

                        Row {
                            Layout.preferredWidth: 190
                            spacing: 4

                            Repeater {
                                model: bind.modelData[0].split(" ")

                                Rectangle {
                                    required property string modelData
                                    readonly property bool word: ["then", "/"].includes(modelData)

                                    width: word ? label.implicitWidth : label.implicitWidth + 12
                                    height: 20
                                    radius: 5
                                    color: word ? "transparent" : Qt.rgba(1, 1, 1, 0.1)

                                    Text {
                                        id: label

                                        anchors.centerIn: parent
                                        text: parent.modelData
                                        color: parent.word ? Theme.text3 : Theme.text
                                        font.family: Theme.font
                                        font.pixelSize: 12
                                        font.weight: Font.Medium
                                    }
                                }
                            }
                        }

                        Text {
                            Layout.fillWidth: true
                            text: bind.modelData[1]
                            color: Theme.text2
                            elide: Text.ElideRight
                            font.family: Theme.font
                            font.pixelSize: Theme.fontSize
                        }
                    }
                }
            }
        }
    }
}
