import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs
import qs.widgets

// Clipboard history: type to filter, arrows to move, Return (or click) copies and closes.
Panel {
    id: root

    property var entries: []
    property int selected: 0

    readonly property var matches: entries.filter(e => e.text.toLowerCase().includes(search.text.toLowerCase()))

    function copy(entry): void {
        if (!entry)
            return;
        Quickshell.execDetached(["bash", "-c", `~/.config/scripts/clipboard.sh copy ${entry.id}`]);
        PanelState.close(name);
    }

    name: "clipboard"
    onShownChanged: {
        search.text = "";
        selected = 0;
        if (shown) {
            load.running = true;
            search.input.forceActiveFocus();
        }
    }

    Process {
        id: load

        command: ["bash", "-c", "~/.config/scripts/clipboard.sh list"]
        stdout: StdioCollector {
            onStreamFinished: root.entries = JSON.parse(text)
        }
    }

    SearchField {
        id: search

        placeholder: "Search clipboard"
        onTextChanged: root.selected = 0
        onSubmitted: root.copy(root.matches[root.selected])
        onMovedUp: root.selected = Math.max(0, root.selected - 1)
        onMovedDown: root.selected = Math.min(root.matches.length - 1, root.selected + 1)
        onCancelled: PanelState.close(root.name)
    }

    ListView {
        id: list

        Layout.fillWidth: true
        Layout.topMargin: 4
        Layout.bottomMargin: 2
        implicitHeight: Math.min(contentHeight, 440)
        clip: true
        spacing: 2
        model: root.matches
        currentIndex: root.selected
        boundsBehavior: Flickable.StopAtBounds

        delegate: Rectangle {
            id: row

            required property var modelData
            required property int index
            readonly property bool isImage: modelData.image !== ""
            readonly property bool current: index === root.selected

            width: ListView.view.width
            implicitHeight: isImage ? 72 : 34
            radius: 8
            color: current ? Theme.accent : area.containsMouse ? Qt.rgba(1, 1, 1, 0.08) : "transparent"

            RowLayout {
                anchors {
                    fill: parent
                    leftMargin: 12
                    rightMargin: 12
                }
                spacing: 12

                Image {
                    visible: row.isImage
                    Layout.preferredHeight: 56
                    Layout.preferredWidth: 96
                    source: row.isImage ? "file://" + row.modelData.image : ""
                    sourceSize.height: 112
                    fillMode: Image.PreserveAspectFit
                    horizontalAlignment: Image.AlignLeft
                    asynchronous: true
                }

                Text {
                    Layout.fillWidth: true
                    text: row.isImage ? row.modelData.text.replace(/^\[\[ binary data (.*) \]\]$/, "Image · $1")
                                      : row.modelData.text
                    color: row.current ? Theme.accentInk : row.isImage ? Theme.text2 : Theme.text
                    elide: Text.ElideRight
                    maximumLineCount: 1
                    font.family: Theme.font
                    font.pixelSize: Theme.fontSize
                }
            }

            MouseArea {
                id: area

                anchors.fill: parent
                hoverEnabled: true
                onClicked: root.copy(row.modelData)
            }
        }
    }

    Text {
        visible: root.matches.length === 0
        Layout.leftMargin: 12
        Layout.topMargin: 8
        Layout.bottomMargin: 8
        text: root.entries.length === 0 ? "Clipboard history is empty" : "No matches"
        color: Theme.text3
        font.family: Theme.font
        font.pixelSize: Theme.fontSize
    }
}
