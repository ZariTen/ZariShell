import QtQuick
import Quickshell
import Quickshell.Io

Scope {
    Process {
        id: watcher
        command: ["wl-paste", "--watch", "cliphist", "store"]
        running: true

        onRunningChanged: {
            if (!running)
                restart.restart();
        }
    }

    Timer {
        id: restart
        interval: 1000
        onTriggered: watcher.running = true
    }
}
