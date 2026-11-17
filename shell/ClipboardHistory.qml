pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root
    readonly property bool enabled: Theme.clipboardHistory
    readonly property string lockPath: (Quickshell.env("XDG_CACHE_HOME") || Quickshell.env("HOME") + "/.cache") + "/zarishell-clipboard.lock"
    property var ids: []
    property var previews: []
    property string pendingPaste: ""
    // Remain busy until exit, not merely until running=false requests a stop.
    property bool pasteInFlight: false
    property bool clearing: false
    property bool clearFailed: false

    onEnabledChanged: {
        if (!enabled) {
            pendingPaste = "";
            listProcess.running = false;
            pasteProcess.running = false;
            ids = [];
            previews = [];
        }
    }

    function refresh() {
        if (enabled && !clearing)
            listProcess.running = true;
    }

    function clear() {
        if (!enabled || clearing)
            return;
        clearing = true;
        clearFailed = false;
        pendingPaste = "";
        if (pasteInFlight)
            pasteProcess.running = false;
        startClear();
    }

    function startClear() {
        // Let the old clipboard owner and any stale history query finish first.
        if (clearing && !pasteInFlight && !listProcess.running && !clearProcess.running)
            clearProcess.running = true;
    }

    function finishClear(success) {
        if (success) {
            ids = [];
            previews = [];
        }
        clearFailed = !success;
        clearing = false;
        if (!success)
            refresh();
    }

    function paste(entryId) {
        if (!enabled || clearing || !/^\d+$/.test(entryId))
            return;
        pendingPaste = entryId;
        if (pasteInFlight)
            pasteProcess.running = false;
        else
            startPendingPaste();
    }

    function startPendingPaste() {
        if (!enabled || clearing || pasteInFlight || pendingPaste === "")
            return;
        var entryId = pendingPaste;
        pendingPaste = "";
        pasteInFlight = true;
        pasteProcess.command = ["bash", Quickshell.shellDir + "/scripts/clipboard-paste.sh", entryId];
        pasteProcess.running = true;
    }

    Process {
        id: listProcess
        command: ["cliphist", "list"]
        onRunningChanged: {
            if (!running && root.clearing)
                Qt.callLater(root.startClear);
        }
        stdout: StdioCollector {
            onStreamFinished: {
                // A cancelled query can still finish after the privacy setting changes.
                if (!root.enabled || root.clearing)
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

    Process {
        id: pasteProcess
        onExited: {
            root.pasteInFlight = false;
            Qt.callLater(root.startClear);
            Qt.callLater(root.startPendingPaste);
        }
    }

    Process {
        id: clearProcess
        property bool startedSuccessfully: false
        // Wait for any old watcher child to finish storing before wiping.
        command: ["bash", "-c", 'wl-copy --clear; status=$?; mkdir -p -- "${1%/*}" && flock -x -w 5 -F -- "$1" cliphist wipe && exit "$status"', "clipboard-clear", root.lockPath]
        onStarted: startedSuccessfully = true
        onRunningChanged: {
            if (!running && root.clearing && !startedSuccessfully)
                root.finishClear(false);
        }
        onExited: (exitCode, exitStatus) => {
            root.finishClear(exitCode === 0 && exitStatus === 0);
            startedSuccessfully = false;
        }
    }
}
