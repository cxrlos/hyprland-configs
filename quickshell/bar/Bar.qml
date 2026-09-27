import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import qs

// Frosted menu-bar strip; the blur comes from the Hyprland layer rule on its namespace.
PanelWindow {
    id: bar

    required property ShellScreen modelData

    screen: modelData
    visible: BarState.visible
    anchors {
        top: true
        left: true
        right: true
    }
    implicitHeight: Theme.barHeight
    color: "transparent"
    WlrLayershell.namespace: "quickshell-bar"

    Rectangle {
        anchors.fill: parent
        color: Theme.surface

        Rectangle {
            anchors {
                left: parent.left
                right: parent.right
                bottom: parent.bottom
            }
            height: 1
            color: Theme.hair
        }
    }

    RowLayout {
        anchors {
            left: parent.left
            leftMargin: 14
            verticalCenter: parent.verticalCenter
        }
        spacing: 14

        Workspaces {
            monitor: bar.modelData
        }
        WindowTitle {}
    }

    Clock {
        anchors.centerIn: parent
    }

    RowLayout {
        anchors {
            right: parent.right
            rightMargin: 8
            verticalCenter: parent.verticalCenter
        }
        spacing: 2

        NowPlaying {}
        SystemStatus {}
        Volume {}
        Network {}
        BluetoothStatus {}
        BrightnessStatus {}
        Battery {}
        Caffeine {}
        Notifications {}
        Tray {
            window: bar
        }
        Power {}
    }
}
