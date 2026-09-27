import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Widgets
import qs
import qs.widgets

// Spotlight-style launcher and window switcher. An empty query lists open windows; typing searches
// windows, apps and Obsidian notes, arithmetic shows its result, and ":" searches emoji
// (unicode-emoji's list).
Panel {
    id: root

    property int selected: 0
    property var emoji: []
    property var notes: []

    readonly property string query: search.text.trim()
    readonly property bool emojiMode: query.startsWith(":")

    readonly property var results: {
        const q = query.toLowerCase();
        if (emojiMode) {
            const eq = q.slice(1).trim();
            return emoji.filter(e => eq === "" || e[2].includes(eq)).slice(0, 40)
                .map(e => ({ kind: "emoji", glyph: e[0], title: e[1], subtitle: "Copy emoji" }));
        }

        const out = [];
        const entries = DesktopEntries.applications.values;
        const calc = evaluate(query);
        if (calc !== null)
            out.push({ kind: "calc", title: calc, subtitle: `${query} =  ·  Return copies` });

        const windows = Hyprland.toplevels.values.filter(t => (t.workspace?.id ?? 0) > 0)
            .sort((a, b) => a.workspace.id - b.workspace.id)
            .filter(t => q === "" || t.title.toLowerCase().includes(q) || (t.wayland?.appId ?? "").toLowerCase().includes(q));
        for (const t of windows)
            out.push({ kind: "window", toplevel: t, title: t.title, subtitle: `${prettyApp(t.wayland?.appId)}  ·  Workspace ${t.workspace?.id}`,
                       icon: DesktopEntries.heuristicLookup(t.wayland?.appId ?? "")?.icon ?? "" });

        if (q !== "") {
            const apps = entries.filter(a => !a.noDisplay)
                .map(a => ({ app: a, score: rank(a, q) })).filter(r => r.score > 0)
                .sort((a, b) => b.score - a.score).slice(0, 8);
            for (const r of apps)
                out.push({ kind: "app", app: r.app, title: r.app.name, subtitle: r.app.genericName || r.app.comment || "Application", icon: r.app.icon });
            const found = notes.filter(n => n.title.toLowerCase().includes(q))
                .sort((a, b) => b.title.toLowerCase().startsWith(q) - a.title.toLowerCase().startsWith(q)).slice(0, 6);
            for (const n of found)
                out.push({ kind: "note", note: n, title: n.title, subtitle: `Note  ·  ${n.folder || n.vault}` });
        }
        return out;
    }

    function prettyApp(id): string {
        return id ? id.charAt(0).toUpperCase() + id.slice(1) : "";
    }

    function rank(app, q): int {
        const name = app.name.toLowerCase();
        if (name.startsWith(q))
            return 4;
        if (name.split(/[\s-]/).some(w => w.startsWith(q)))
            return 3;
        if (name.includes(q))
            return 2;
        const extra = [app.genericName, ...app.keywords, app.id].join(" ").toLowerCase();
        return extra.includes(q) ? 1 : 0;
    }

    function evaluate(expr): var {
        if (!/^[\d\s.+\-*/()%^]+$/.test(expr) || !/\d\s*[+\-*/%^]\s*[\d(]/.test(expr))
            return null;
        try {
            const value = Function(`"use strict"; return (${expr.replace(/\^/g, "**")});`)();
            return Number.isFinite(value) ? String(Math.round(value * 1e10) / 1e10) : null;
        } catch (e) {
            return null;
        }
    }

    function run(item): void {
        if (!item)
            return;
        PanelState.close(name);
        if (item.kind === "app")
            item.app.execute();
        else if (item.kind === "note")
            Quickshell.execDetached(["xdg-open", `obsidian://open?vault=${encodeURIComponent(item.note.vault)}&file=${encodeURIComponent(item.note.file)}`]);
        else if (item.kind === "window")
            Hyprland.dispatch(`hl.dsp.focus({ window = "address:0x${item.toplevel.address}" })`);
        else
            Quickshell.execDetached(["wl-copy", item.kind === "emoji" ? item.glyph : item.title]);
    }

    name: "launcher"
    onShownChanged: {
        search.text = "";
        selected = 0;
        if (shown) {
            search.input.forceActiveFocus();
            loadNotes.running = true;
        }
    }

    Process {
        id: loadNotes

        command: ["bash", "-c", "~/.config/scripts/notes.sh"]
        stdout: StdioCollector {
            onStreamFinished: root.notes = JSON.parse(text || "[]")
        }
    }

    FileView {
        path: "/usr/share/unicode/emoji/emoji-test.txt"
        onLoaded: root.emoji = text().split("\n")
            .map(line => line.match(/; fully-qualified\s+# (\S+) E[\d.]+ (.+)$/))
            .filter(m => m && !m[2].includes("skin tone"))
            .map(m => [m[1], m[2], m[2].toLowerCase()])
    }

    SearchField {
        id: search

        glyph: root.emojiMode ? "mood" : "search"
        placeholder: "Search apps, windows and notes  ·  : for emoji"
        onTextChanged: root.selected = 0
        onSubmitted: root.run(root.results[root.selected])
        onMovedUp: root.selected = Math.max(0, root.selected - 1)
        onMovedDown: root.selected = Math.min(root.results.length - 1, root.selected + 1)
        onCancelled: PanelState.close(root.name)
        input.Keys.onTabPressed: root.selected = (root.selected + 1) % Math.max(1, root.results.length)
    }

    ListView {
        Layout.fillWidth: true
        Layout.topMargin: 4
        Layout.bottomMargin: 2
        implicitHeight: Math.min(contentHeight, 440)
        clip: true
        spacing: 2
        model: root.results
        currentIndex: root.selected
        boundsBehavior: Flickable.StopAtBounds
        highlightMoveDuration: 0

        delegate: Rectangle {
            id: row

            required property var modelData
            required property int index
            readonly property bool current: index === root.selected

            width: ListView.view.width
            implicitHeight: 44
            radius: 8
            color: current ? Theme.accent : area.containsMouse ? Qt.rgba(1, 1, 1, 0.08) : "transparent"

            RowLayout {
                anchors {
                    fill: parent
                    leftMargin: 10
                    rightMargin: 12
                }
                spacing: 12

                Item {
                    Layout.preferredWidth: 28
                    Layout.preferredHeight: 28

                    IconImage {
                        anchors.fill: parent
                        visible: (row.modelData.icon ?? "") !== ""
                        source: visible ? Quickshell.iconPath(row.modelData.icon, true) : ""
                        asynchronous: true
                    }

                    Text {
                        anchors.centerIn: parent
                        visible: row.modelData.kind === "emoji"
                        text: row.modelData.glyph ?? ""
                        font.pixelSize: 22
                    }

                    Glyph {
                        anchors.centerIn: parent
                        visible: row.modelData.kind === "calc" || row.modelData.kind === "note" || (row.modelData.kind === "window" && (row.modelData.icon ?? "") === "")
                        glyph: row.modelData.kind === "calc" ? "calculate" : row.modelData.kind === "note" ? "description" : "web_asset"
                        size: 22
                        color: row.current ? Theme.accentInk : Theme.text2
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 1

                    Text {
                        Layout.fillWidth: true
                        text: row.modelData.title
                        color: row.current ? Theme.accentInk : Theme.text
                        elide: Text.ElideRight
                        font.family: Theme.font
                        font.pixelSize: row.modelData.kind === "calc" ? 18 : Theme.fontSize
                        font.weight: row.modelData.kind === "calc" ? Font.DemiBold : Font.Normal
                    }

                    Text {
                        Layout.fillWidth: true
                        text: row.modelData.subtitle
                        color: row.current ? Qt.rgba(29 / 255, 32 / 255, 33 / 255, 0.7) : Theme.text3
                        elide: Text.ElideRight
                        font.family: Theme.font
                        font.pixelSize: 11
                    }
                }

                Text {
                    visible: row.current
                    text: row.modelData.kind === "app" || row.modelData.kind === "note" ? "Open" : row.modelData.kind === "window" ? "Switch" : "Copy"
                    color: Qt.rgba(29 / 255, 32 / 255, 33 / 255, 0.7)
                    font.family: Theme.font
                    font.pixelSize: 11
                }
            }

            MouseArea {
                id: area

                anchors.fill: parent
                hoverEnabled: true
                onClicked: root.run(row.modelData)
            }
        }
    }

    Text {
        visible: root.results.length === 0
        Layout.leftMargin: 12
        Layout.topMargin: 8
        Layout.bottomMargin: 8
        text: root.query === "" ? "No open windows · type to search apps" : "No matches"
        color: Theme.text3
        font.family: Theme.font
        font.pixelSize: Theme.fontSize
    }
}
