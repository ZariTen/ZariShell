import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Wayland
import Quickshell.Widgets

Scope {
    id: root

    // -- State and derived properties ---------------------------------------
    property string query: ""
    property var clipIds: []
    property var clipPreviews: []

    // Launch-frequency ranking: {desktopEntryId: count} in $XDG_STATE_HOME/quickshell/launches.json.
    readonly property string stateDir: (Quickshell.env("XDG_STATE_HOME") || Quickshell.env("HOME") + "/.local/state") + "/quickshell"
    property var launchCounts: ({})
    // Sorting uses a snapshot taken when the launcher opens, so recording a
    // launch never reorders the list underneath the item being activated.
    property var rankCounts: ({})
    // Last pointer position in scene coordinates; hover only selects when the
    // pointer actually moves, not when the list scrolls under a still cursor.
    property point lastPointer: Qt.point(-1, -1)

    readonly property bool listPanel: ShellState.panel === "launcher" || ShellState.panel === "clipboard" || ShellState.panel === "switcher"
    // Remember the last list panel so contents stay put during the exit animation.
    property string mode: "launcher"

    readonly property int headerGlyph: {
        if (mode === "clipboard")
            return 0xF0147;
        if (mode === "switcher")
            return 0xF05B6;
        return 0xF1105;
    }

    readonly property string headerTitle: {
        if (mode === "clipboard")
            return "Clipboard history";
        if (mode === "switcher")
            return "Switch window";
        return "All Programs";
    }

    readonly property string searchPlaceholder: {
        if (mode === "clipboard")
            return "Search clipboard";
        if (mode === "switcher")
            return "Search windows";
        return "Search programs and files";
    }

    readonly property var apps: {
        var allApps = DesktopEntries.applications.values;
        var needle = root.query.toLowerCase();
        var prefixMatches = [];
        var otherMatches = [];
        for (var i = 0; i < allApps.length; i++) {
            var app = allApps[i];
            var appName = app.name.toLowerCase();
            if (needle === "")
                otherMatches.push(app);
            else if (appName.indexOf(needle) === 0)
                prefixMatches.push(app);
            else if (appName.indexOf(needle) !== -1
                || (app.genericName || "").toLowerCase().indexOf(needle) !== -1
                || app.keywords.join(" ").toLowerCase().indexOf(needle) !== -1)
                otherMatches.push(app);
        }
        var compareApps = (firstApp, secondApp) => root.launchCount(secondApp) - root.launchCount(firstApp) || firstApp.name.localeCompare(secondApp.name);
        prefixMatches.sort(compareApps);
        otherMatches.sort(compareApps);
        return prefixMatches.concat(otherMatches).slice(0, 60);
    }

    readonly property var windows: {
        var allToplevels = Hyprland.toplevels.values;
        var matchingWindows = [];
        var needle = root.query.toLowerCase();
        for (var i = 0; i < allToplevels.length; i++) {
            var title = allToplevels[i].title.toLowerCase();
            if (needle === "" || title.indexOf(needle) !== -1)
                matchingWindows.push(allToplevels[i]);
        }
        return matchingWindows;
    }

    readonly property var clipHits: {
        var matchingIndices = [];
        var needle = root.query.toLowerCase();
        for (var i = 0; i < root.clipPreviews.length && matchingIndices.length < 40; i++) {
            if (needle === "" || root.clipPreviews[i].toLowerCase().indexOf(needle) !== -1)
                matchingIndices.push(i);
        }
        return matchingIndices;
    }

    // -- Helper functions ---------------------------------------------------
    function launchCount(app) {
        return root.rankCounts[app.id] || 0;
    }

    function recordLaunch(app) {
        var updatedCounts = Object.assign({}, root.launchCounts);
        updatedCounts[app.id] = (updatedCounts[app.id] || 0) + 1;
        root.launchCounts = updatedCounts;
        launchFile.setText(JSON.stringify(updatedCounts));
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
            return {
                title: app.name,
                subtitle: app.comment || app.genericName || "",
                icon: app.icon,
                glyph: 0xF003B
            };
        }
        if (mode === "clipboard") {
            var previewText = clipPreviews[clipHits[index]].replace(/\s+/g, " ");
            var isBinaryImage = /^\[\[ binary data/.test(previewText);
            return {
                title: previewText,
                subtitle: "",
                icon: "",
                glyph: isBinaryImage ? 0xF02E9 : 0xF0147
            };
        }
        var windowItem = windows[index];
        var appId = windowItem.wayland ? windowItem.wayland.appId : "";
        var desktopEntry = appId !== "" ? DesktopEntries.heuristicLookup(appId) : null;
        var workspaceSuffix = windowItem.workspace ? "  \u00b7  workspace " + windowItem.workspace.name : "";
        return {
            title: windowItem.title,
            subtitle: (desktopEntry ? desktopEntry.name : appId) + workspaceSuffix,
            icon: desktopEntry ? desktopEntry.icon : appId,
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
            var entryId = clipIds[clipHits[index]];
            if (/^\d+$/.test(entryId)) {
                clipPasteProcess.command = ["sh", "-c", "cliphist decode \"$1\" | wl-copy", "sh", entryId];
                clipPasteProcess.running = true;
            }
        } else if (windows[index].wayland) {
            windows[index].wayland.activate();
        }
        ShellState.close();
    }

    function refreshClipboard() {
        clipListProcess.running = true;
    }

    // -- Visual tree --------------------------------------------------------
    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: window

            required property var modelData
            readonly property bool focusedHere: root.listPanel && ShellState.isFocusedScreen(modelData)

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

            // Centered window for every list panel.
            PanelCard {
                id: card
                shown: window.focusedHere
                width: Math.min(window.width - 80, 620)
                height: Math.min(window.height - Theme.barSpace - 80, 540)

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: Theme.spacingM
                    spacing: Theme.spacingS

                    // Header (title-bar band)
                    RowLayout {
                        Layout.fillWidth: true
                        Layout.preferredHeight: Theme.px(28)
                        spacing: Theme.spacingS

                        MdIcon {
                            codepoint: root.headerGlyph
                            color: Theme.accent
                        }
                        StyledText {
                            Layout.fillWidth: true
                            text: root.headerTitle
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
                            border.color: Theme.outlineFaint
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
                            highlight: Highlight {
                                radius: Theme.radius
                                bordered: true
                                level: 0.9
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
                                        implicitWidth: Theme.px(32)
                                        implicitHeight: Theme.px(32)

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
                                            font.pixelSize: Theme.iconPx(20)
                                            color: row.current ? Theme.accent : Theme.textSurfaceVariant
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
                                        var scenePoint = mapToItem(null, mouse.x, mouse.y);
                                        var pointerMoved = root.lastPointer.x >= 0 && (scenePoint.x !== root.lastPointer.x || scenePoint.y !== root.lastPointer.y);
                                        root.lastPointer = scenePoint;
                                        if (pointerMoved)
                                            list.currentIndex = row.index;
                                    }
                                    onClicked: root.activate(row.index)
                                }
                            }
                        }
                    }

                    // Search box at the bottom
                    Field {
                        Layout.fillWidth: true
                        implicitHeight: Theme.px(32)
                        input: search

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
                                selectedTextColor: Theme.textPrimaryContainer
                                font.family: Theme.font
                                font.pixelSize: Theme.fontBody
                                clip: true

                                StyledText {
                                    anchors.fill: parent
                                    visible: search.text === ""
                                    color: Theme.textSurfaceVariant
                                    font.italic: true
                                    text: root.searchPlaceholder
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

    // -- Lifecycle and background objects -----------------------------------
    Component.onCompleted: Quickshell.execDetached(["mkdir", "-p", root.stateDir])

    Connections {
        target: ShellState
        function onPanelChanged() {
            if (root.listPanel)
                root.mode = ShellState.panel;
        }
    }

    FileView {
        id: launchFile
        path: root.stateDir + "/launches.json"
        printErrors: false
        onLoaded: {
            try {
                var parsed = JSON.parse(text());
                root.launchCounts = parsed && typeof parsed === "object" && !Array.isArray(parsed) ? parsed : {};
            } catch (parseError) {
                root.launchCounts = {};
            }
        }
        onLoadFailed: root.launchCounts = {}
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
        id: clipListProcess
        command: ["cliphist", "list"]
        stdout: StdioCollector {
            onStreamFinished: {
                var trimmed = text.trim();
                var lines = trimmed === "" ? [] : trimmed.split("\n");
                var ids = [];
                var previews = [];
                for (var i = 0; i < lines.length && ids.length < 80; i++) {
                    var tabIndex = lines[i].indexOf("\t");
                    if (tabIndex < 1)
                        continue;
                    ids.push(lines[i].slice(0, tabIndex));
                    previews.push(lines[i].slice(tabIndex + 1));
                }
                root.clipIds = ids;
                root.clipPreviews = previews;
            }
        }
    }

    Process {
        id: clipPasteProcess
    }
}
