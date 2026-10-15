import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Wayland
import Quickshell.Widgets

Scope {
    id: root

    property string query: ""
    property var clipIds: []
    property var clipPreviews: []

    // Launch-frequency ranking: {desktopEntryId: count} in $XDG_STATE_HOME/quickshell/launches.json.
    readonly property string stateDir: (Quickshell.env("XDG_STATE_HOME") || Quickshell.env("HOME") + "/.local/state") + "/quickshell"
    property var launchCounts: ({})
    FileView {
        id: launchFile
        path: root.stateDir + "/launches.json"
        printErrors: false
        onLoaded: {
            try {
                var d = JSON.parse(text());
                root.launchCounts = d && typeof d === "object" && !Array.isArray(d) ? d : {};
            } catch (e) {
                root.launchCounts = {};
            }
        }
        onLoadFailed: root.launchCounts = {}
    }
    Component.onCompleted: Quickshell.execDetached(["mkdir", "-p", root.stateDir])
    // Sorting uses a snapshot taken when the launcher opens, so recording a
    // launch never reorders the list underneath the item being activated.
    property var rankCounts: ({})
    function launchCount(app) {
        return root.rankCounts[app.id] || 0;
    }
    // Last pointer position in scene coordinates; hover only selects when the
    // pointer actually moves, not when the list scrolls under a still cursor.
    property point lastPointer: Qt.point(-1, -1)
    function recordLaunch(app) {
        var c = Object.assign({}, root.launchCounts);
        c[app.id] = (c[app.id] || 0) + 1;
        root.launchCounts = c;
        launchFile.setText(JSON.stringify(c));
    }
    readonly property bool listPanel: ShellState.panel === "launcher" || ShellState.panel === "clipboard" || ShellState.panel === "switcher"
    // Remember the last list panel so contents stay put during the exit animation.
    property string mode: "launcher"
    Connections {
        target: ShellState
        function onPanelChanged() {
            if (root.listPanel)
                root.mode = ShellState.panel;
        }
    }

    readonly property var apps: {
        var all = DesktopEntries.applications.values;
        var needle = root.query.toLowerCase();
        var prefix = [];
        var other = [];
        for (var i = 0; i < all.length; i++) {
            var app = all[i];
            var name = app.name.toLowerCase();
            if (needle === "")
                other.push(app);
            else if (name.indexOf(needle) === 0)
                prefix.push(app);
            else if (name.indexOf(needle) !== -1 || (app.genericName || "").toLowerCase().indexOf(needle) !== -1 || app.keywords.join(" ").toLowerCase().indexOf(needle) !== -1)
                other.push(app);
        }
        var sortByName = (a, b) => root.launchCount(b) - root.launchCount(a) || a.name.localeCompare(b.name);
        prefix.sort(sortByName);
        other.sort(sortByName);
        return prefix.concat(other).slice(0, 60);
    }

    readonly property var windows: {
        var all = Hyprland.toplevels.values;
        var found = [];
        var needle = root.query.toLowerCase();
        for (var i = 0; i < all.length; i++) {
            var title = all[i].title.toLowerCase();
            if (needle === "" || title.indexOf(needle) !== -1)
                found.push(all[i]);
        }
        return found;
    }

    readonly property var clipHits: {
        var found = [];
        var needle = root.query.toLowerCase();
        for (var i = 0; i < root.clipPreviews.length && found.length < 40; i++) {
            if (needle === "" || root.clipPreviews[i].toLowerCase().indexOf(needle) !== -1)
                found.push(i);
        }
        return found;
    }

    function itemCount() {
        if (mode === "launcher")
            return apps.length;
        if (mode === "clipboard")
            return clipHits.length;
        return windows.length;
    }

    // { title, subtitle, icon (theme icon name or ""), glyph (codepoint) }
    function item(index) {
        if (mode === "launcher") {
            var app = apps[index];
            return { title: app.name, subtitle: app.comment || app.genericName || "", icon: app.icon, glyph: 0xF003B };
        }
        if (mode === "clipboard") {
            var text = clipPreviews[clipHits[index]].replace(/\s+/g, " ");
            var image = /^\[\[ binary data/.test(text);
            return { title: text, subtitle: "", icon: "", glyph: image ? 0xF02E9 : 0xF0147 };
        }
        var win = windows[index];
        var appId = win.wayland ? win.wayland.appId : "";
        var entry = appId !== "" ? DesktopEntries.heuristicLookup(appId) : null;
        return {
            title: win.title,
            subtitle: (entry ? entry.name : appId) + (win.workspace ? "  ·  workspace " + win.workspace.name : ""),
            icon: entry ? entry.icon : appId,
            glyph: 0xF05B6
        };
    }

    function activate(index) {
        if (index < 0 || index >= itemCount())
            return;
        if (mode === "launcher") {
            var app = apps[index];
            // Run each app in its own systemd scope so restarting the shell
            // (quickshell.service) doesn't kill everything launched from it.
            if (app.runInTerminal || !app.command || app.command.length === 0)
                app.execute();
            else
                Quickshell.execDetached({
                    command: ["systemd-run", "--user", "--scope", "--collect", "--quiet", "--"].concat(app.command),
                    workingDirectory: app.workingDirectory || ""
                });
            root.recordLaunch(app);
        } else if (mode === "clipboard") {
            var id = clipIds[clipHits[index]];
            if (/^\d+$/.test(id)) {
                clipPaste.command = ["sh", "-c", "cliphist decode " + id + " | wl-copy"];
                clipPaste.running = true;
            }
        } else if (windows[index].wayland) {
            windows[index].wayland.activate();
        }
        ShellState.close();
    }

    function refreshClipboard() {
        clipList.running = true;
    }

    IpcHandler {
        target: "panel"

        function toggle(name: string): void {
            ShellState.toggle(name);
            if (name === "clipboard" && ShellState.panel === "clipboard")
                root.refreshClipboard();
        }

        function close(): void {
            ShellState.close();
        }
    }

    Process {
        id: clipList
        command: ["cliphist", "list"]
        stdout: StdioCollector {
            onStreamFinished: {
                var lines = text.trim() === "" ? [] : text.trim().split("\n");
                var ids = [];
                var previews = [];
                for (var i = 0; i < lines.length && ids.length < 80; i++) {
                    var tab = lines[i].indexOf("\t");
                    if (tab < 1)
                        continue;
                    ids.push(lines[i].slice(0, tab));
                    previews.push(lines[i].slice(tab + 1));
                }
                root.clipIds = ids;
                root.clipPreviews = previews;
            }
        }
    }

    Process {
        id: clipPaste
    }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: window

            required property var modelData
            readonly property var monitor: Hyprland.monitorFor(modelData)
            readonly property bool focusedHere: {
                if (!root.listPanel)
                    return false;
                if (Hyprland.focusedMonitor === null)
                    return modelData === Quickshell.screens[0];
                return monitor !== null && monitor.name === Hyprland.focusedMonitor.name;
            }

            screen: modelData
            visible: focusedHere || card.animating
            color: "transparent"
            aboveWindows: true
            exclusionMode: ExclusionMode.Ignore

            anchors {
                top: true
                bottom: true
                left: true
                right: true
            }

            WlrLayershell.namespace: "shell-panel"
            WlrLayershell.keyboardFocus: focusedHere ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

            onFocusedHereChanged: {
                if (focusedHere) {
                    root.rankCounts = root.launchCounts;
                    root.lastPointer = Qt.point(-1, -1);
                    root.query = "";
                    search.text = "";
                    list.currentIndex = 0;
                    search.forceActiveFocus();
                }
            }

            Rectangle {
                anchors.fill: parent
                color: Theme.scrim
                opacity: card.shown ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: Theme.durMedium } }
            }

            MouseArea {
                anchors.fill: parent
                onClicked: ShellState.close()
            }

            // Centered glass window for every list panel.
            PanelCard {
                id: card
                shown: window.focusedHere
                width: Math.min(window.width - 80, 620)
                height: Math.min(window.height - Theme.barHeight - 80, 540)

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: Theme.spacingM
                    spacing: Theme.spacingS

                    // Header (title-bar band)
                    RowLayout {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 28
                        spacing: Theme.spacingS

                        MdIcon {
                            codepoint: root.mode === "clipboard" ? 0xF0147 : (root.mode === "switcher" ? 0xF05B6 : 0xF1105)
                            color: Theme.glow
                        }
                        StyledText {
                            Layout.fillWidth: true
                            text: root.mode === "clipboard" ? "Clipboard history" : (root.mode === "switcher" ? "Switch window" : "All Programs")
                            font.pixelSize: Theme.fontTitle
                            font.weight: Font.DemiBold
                        }
                        StyledText {
                            text: list.count + (list.count === 1 ? " item" : " items")
                            color: Theme.textSurfaceVariant
                            font.pixelSize: Theme.fontSmall
                        }
                    }

                    // Recessed list well (Start menu's left pane)
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        radius: Theme.radius
                        color: Theme.inset
                        border.width: 1
                        border.color: Theme.insetBorder

                        Rectangle {
                            anchors.fill: parent
                            anchors.margins: 1
                            radius: Theme.radius
                            color: "transparent"
                            border.width: 1
                            border.color: Qt.rgba(1, 1, 1, 0.08)
                        }

                        ListView {
                            id: list
                            anchors.fill: parent
                            anchors.margins: Theme.spacingXs
                            clip: true
                            spacing: 1
                            model: root.itemCount()
                            currentIndex: 0
                            boundsBehavior: Flickable.StopAtBounds
                            highlightMoveDuration: Theme.durShort
                            highlightResizeDuration: 0
                            highlight: Rectangle {
                                radius: Theme.radius
                                border.width: 1
                                border.color: Qt.rgba(Theme.glow.r, Theme.glow.g, Theme.glow.b, 0.7)
                                gradient: Gradient {
                                    GradientStop { position: 0.0; color: Qt.rgba(Theme.glow.r, Theme.glow.g, Theme.glow.b, 0.38) }
                                    GradientStop { position: 0.5; color: Qt.rgba(Theme.glow.r, Theme.glow.g, Theme.glow.b, 0.18) }
                                    GradientStop { position: 1.0; color: Qt.rgba(Theme.glow.r, Theme.glow.g, Theme.glow.b, 0.28) }
                                }
                            }

                            StyledText {
                                anchors.centerIn: parent
                                visible: list.count === 0
                                color: Theme.textSurfaceVariant
                                text: "No items match your search."
                            }

                            delegate: Item {
                                id: row
                                required property int index
                                readonly property var entry: root.item(index)
                                readonly property bool current: ListView.isCurrentItem

                                width: ListView.view.width
                                implicitHeight: entry.subtitle === "" ? 38 : 46

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: Theme.spacingS
                                    anchors.rightMargin: Theme.spacingS
                                    spacing: Theme.spacingS

                                    Item {
                                        implicitWidth: 32
                                        implicitHeight: 32

                                        IconImage {
                                            id: icon
                                            anchors.fill: parent
                                            visible: row.entry.icon !== "" && status === Image.Ready
                                            source: row.entry.icon !== "" ? Quickshell.iconPath(row.entry.icon, true) : ""
                                            asynchronous: true
                                        }

                                        MdIcon {
                                            anchors.centerIn: parent
                                            visible: !icon.visible
                                            codepoint: row.entry.glyph
                                            font.pixelSize: 20
                                            color: row.current ? Theme.glow : Theme.textSurfaceVariant
                                        }
                                    }

                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        spacing: 0

                                        StyledText {
                                            Layout.fillWidth: true
                                            text: row.entry.title
                                            font.weight: row.current ? Font.DemiBold : Font.Normal
                                        }

                                        StyledText {
                                            Layout.fillWidth: true
                                            visible: row.entry.subtitle !== ""
                                            text: row.entry.subtitle
                                            font.pixelSize: Theme.fontSmall
                                            color: Theme.textSurfaceVariant
                                        }
                                    }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onPositionChanged: mouse => {
                                        var p = mapToItem(null, mouse.x, mouse.y);
                                        var moved = root.lastPointer.x >= 0 && (p.x !== root.lastPointer.x || p.y !== root.lastPointer.y);
                                        root.lastPointer = p;
                                        if (moved)
                                            list.currentIndex = row.index;
                                    }
                                    onClicked: root.activate(row.index)
                                }
                            }
                        }
                    }

                    // Search box at the bottom, Win7 style
                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: 32
                        radius: Theme.radius
                        color: Theme.inset
                        border.width: 1
                        border.color: search.activeFocus ? Theme.glow : Qt.rgba(1, 1, 1, 0.25)

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: Theme.spacingS
                            anchors.rightMargin: Theme.spacingS
                            spacing: Theme.spacingS

                            TextInput {
                                id: search
                                Layout.fillWidth: true
                                color: Theme.textSurface
                                selectionColor: Theme.primaryContainer
                                selectedTextColor: "#ffffff"
                                font.family: Theme.font
                                font.pixelSize: Theme.fontBody
                                clip: true

                                StyledText {
                                    anchors.fill: parent
                                    visible: search.text === ""
                                    color: Theme.textSurfaceVariant
                                    font.italic: true
                                    text: root.mode === "clipboard" ? "Search clipboard" : (root.mode === "switcher" ? "Search windows" : "Search programs and files")
                                }

                                onTextChanged: {
                                    root.query = text;
                                    list.currentIndex = 0;
                                }
                                onAccepted: root.activate(list.currentIndex)
                                Keys.onEscapePressed: ShellState.close()
                                Keys.onUpPressed: list.decrementCurrentIndex()
                                Keys.onDownPressed: list.incrementCurrentIndex()
                                Keys.onTabPressed: list.incrementCurrentIndex()
                                Keys.onBacktabPressed: list.decrementCurrentIndex()
                            }

                            MdIcon {
                                codepoint: 0xF0349
                                color: Theme.textSurfaceVariant
                            }
                        }
                    }
                }
            }
        }
    }
}
