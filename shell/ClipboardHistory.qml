pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root
    readonly property bool enabled: Theme.clipboardHistory
    property var ids: []
    property var previews: []

    onEnabledChanged: {
        if (!enabled) {
            listProcess.running = false;
            pasteProcess.running = false;
            ids = [];
            previews = [];
        }
    }

    function refresh() {
        if (enabled)
            listProcess.running = true;
    }

    function paste(entryId) {
        if (!enabled || !/^\d+$/.test(entryId))
            return;
        pasteProcess.command = ["sh", "-c", "cliphist decode \"$1\" | wl-copy", "sh", entryId];
        pasteProcess.running = true;
    }

    Process {
        id: listProcess
        command: ["cliphist", "list"]
        stdout: StdioCollector {
            onStreamFinished: {
                // A cancelled query can still finish after the privacy setting changes.
                if (!root.enabled)
                    return;
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
                root.ids = ids;
                root.previews = previews;
            }
        }
    }

    Process { id: pasteProcess }
}
