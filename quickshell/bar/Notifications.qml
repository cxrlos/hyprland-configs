import QtQuick
import Quickshell
import Quickshell.Io
import qs

// Follows swaync's state stream; click opens its panel, right-click toggles Do Not Disturb.
BarIcon {
    id: root

    property string state: "none"

    glyph: state.startsWith("dnd") ? "" : ""

    onClicked: mouse => Quickshell.execDetached(
        ["swaync-client", mouse.button === Qt.RightButton ? "-d" : "-t", "-sw"])

    Rectangle {
        visible: root.state.endsWith("notification")
        anchors {
            top: parent.top
            right: parent.right
            topMargin: 4
            rightMargin: 7
        }
        width: 6
        height: 6
        radius: 3
        color: Theme.accent
    }

    Process {
        running: true
        command: ["swaync-client", "-swb"]
        stdout: SplitParser {
            onRead: line => root.state = JSON.parse(line).alt ?? "none"
        }
    }
}
