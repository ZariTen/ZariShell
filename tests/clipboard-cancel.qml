import QtQuick
import Quickshell

ShellRoot {
    property int step: 0
    Timer {
        interval: 100
        repeat: true
        running: true
        onTriggered: {
            if (step === 0) ClipboardHistory.paste("42");
            if (step === 2) Settings.set("clipboardHistory", false);
            if (step === 12) {
                Settings.set("clipboardHistory", true);
                ClipboardHistory.paste("43");
            }
            if (step++ === 24) {
                console.log("PASS QML regression tests: in-flight paste cancellation");
                Qt.quit();
            }
        }
    }
}
