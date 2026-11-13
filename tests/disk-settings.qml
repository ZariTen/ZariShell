import QtQuick
import Quickshell

ShellRoot {
    Timer {
        interval: 30
        running: true
        onTriggered: {
            try {
                var home = Quickshell.env("HOME");
                var defaults = home === "/" ? ["/"] : ["/", home];
                if (JSON.stringify(Theme.diskMounts) !== JSON.stringify(defaults)) throw new Error("Default disks must use actual HOME");
                Settings.set("diskMounts", ["/with spaces", "/with spaces", "/literal;$HOME"]);
                if (JSON.stringify(Theme.diskMounts) !== JSON.stringify(["/with spaces", "/literal;$HOME"])) throw new Error("Disk paths must update without splitting or expanding");
                Settings.set("diskMounts", ["relative"]);
                if (JSON.stringify(Theme.diskMounts) !== JSON.stringify(defaults)) throw new Error("Invalid disk paths must fall back");
                Settings.set("diskMounts", []);
                if (Theme.diskMounts.length !== 0) throw new Error("Empty mount list must disable rows");
                console.log("PASS QML regression tests: disk mount defaults and reactive validation");
            } catch(error) { console.error("FAIL QML regression tests: " + error.message); }
            Qt.quit();
        }
    }
}
