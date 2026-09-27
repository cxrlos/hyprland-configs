import QtQuick
import QtQuick.Layouts
import Quickshell
import qs

// Frosted panel hanging under a bar item. The blur comes from the bar layer's
// blur_popups rule; grabFocus closes it on an outside click and gives Esc to it.
PopupWindow {
    id: root

    required property string name
    required property Item anchorItem
    property int panelWidth: 320
    default property alias content: body.data

    readonly property bool shown: DropdownState.open === name

    anchor.item: anchorItem
    anchor.edges: Edges.Bottom
    anchor.gravity: Edges.Bottom
    anchor.adjustment: PopupAdjustment.Slide
    anchor.margins.top: 4

    visible: shown
    grabFocus: true
    color: "transparent"
    implicitWidth: panelWidth
    implicitHeight: body.implicitHeight + 14

    onVisibleChanged: if (!visible) DropdownState.dismissed(name)

    Rectangle {
        anchors.fill: parent
        radius: Theme.radiusPanel
        color: Theme.elevated
        border.width: 1
        border.color: Theme.rim
        focus: true
        Keys.onEscapePressed: DropdownState.dismissed(root.name)

        opacity: root.shown ? 1 : 0
        Behavior on opacity {
            NumberAnimation {
                duration: Theme.animFast
            }
        }

        ColumnLayout {
            id: body

            anchors {
                left: parent.left
                right: parent.right
                top: parent.top
                margins: 7
            }
            spacing: 1
        }
    }
}
