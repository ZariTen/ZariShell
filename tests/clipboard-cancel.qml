import QtQuick
import Quickshell

ShellRoot {
    property int step: 0
    readonly property bool replacement: Quickshell.env("ZS_PASTE_REPLACEMENT") === "1"
    Timer {
        interval: 100
        repeat: true
        running: true
        onTriggered: {
            if (replacement) {
                if (step === 0) ClipboardHistory.paste("42");
                if (step === 5) {
                    ClipboardHistory.paste("43");
                    Qt.callLater(() => ClipboardHistory.paste("44"));
                }
                if (step === 12) {
                    ClipboardHistory.paste("45");
                    Settings.set("clipboardHistory", false);
                }
                if (step === 15) Settings.set("clipboardHistory", true);
                if (step++ === 20) {
                    console.log("PASS QML regression tests: latest clipboard selection");
                    Qt.quit();
                }
                return;
            }
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
