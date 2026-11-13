import QtQuick
import Quickshell
import Quickshell.Io

Scope {
    id: root
    readonly property bool enabled: Theme.clipboardHistory
    readonly property bool watching: watcher.running
    readonly property bool restartPending: restart.running

    onEnabledChanged: {
        restart.stop();
        watcher.running = enabled;
    }

    Process {
        id: watcher
        command: ["wl-paste", "--watch", "cliphist", "store"]
        running: root.enabled

        onRunningChanged: {
            if (!running && root.enabled)
                restart.restart();
        }
    }

    Timer {
        id: restart
        interval: 1000
        onTriggered: if (root.enabled) watcher.running = true
    }
}
