//@ pragma UseQApplication
// QApplication mode is what lets tray icons open their native right-click menus.
import Quickshell
import qs.bar
import qs.osd
import qs.panels

ShellRoot {
    Variants {
        model: Quickshell.screens

        Bar {}
    }

    WorkspaceCompactor {}

    Clipboard {}
    Cheatsheet {}
    Osd {}
}
