import QtQuick
import Quickshell
import Quickshell.Io

Scope {
    id: root
    readonly property bool enabled: Theme.clipboardHistory
    readonly property bool shouldWatch: enabled && !ClipboardHistory.clearing
    readonly property bool watching: watcher.running
    readonly property bool restartPending: restart.running

    onShouldWatchChanged: {
        restart.stop();
        watcher.running = shouldWatch;
    }

    Process {
        id: watcher
        // With no intermediate flock process, stopping the watcher terminates
        // wl-paste itself; already spawned stores still inherit the lock.
        command: ["bash", "-c", 'if ! command -v flock >/dev/null; then exec wl-paste --watch cliphist store; fi; mkdir -p -- "${1%/*}" && exec flock -s -F -- "$1" wl-paste --watch cliphist store', "clipboard-watch", ClipboardHistory.lockPath]
        running: root.shouldWatch

        onRunningChanged: {
            if (!running && root.shouldWatch)
                restart.restart();
        }
    }

    Timer {
        id: restart
        interval: 1000
        onTriggered: if (root.shouldWatch) watcher.running = true
    }
}
