import QtQuick
import Quickshell

ShellRoot {
    Timer {
        interval: 30
        running: true
        onTriggered: {
            try {
                if (Theme.useSystemdScope !== "auto") throw new Error("Scope mode must default to auto");
                Settings.set("useSystemdScope", false);
                if (Theme.useSystemdScope !== "false") throw new Error("False must bypass systemd");
                Settings.set("useSystemdScope", true);
                if (Theme.useSystemdScope !== "true") throw new Error("True must force systemd");
                Settings.set("useSystemdScope", "invalid");
                if (Theme.useSystemdScope !== "auto") throw new Error("Invalid mode must fall back to auto");
                console.log("PASS QML regression tests: reactive launcher scope setting");
            } catch (error) {
                console.error("FAIL QML regression tests: " + error.message);
            }
            Qt.quit();
        }
    }
}
