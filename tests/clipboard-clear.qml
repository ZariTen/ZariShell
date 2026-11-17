import QtQuick
import Quickshell

ShellRoot {
    property int step: 0

    Component.onCompleted: ClipboardHistory.refresh()

    Timer {
        interval: 25
        repeat: true
        running: true
        onTriggered: {
            if (step === 0 && ClipboardHistory.ids.length === 2) {
                ClipboardHistory.refresh();
                if (typeof ClipboardHistory.clear !== "function") {
                    console.error("FAIL Clipboard history has no clear action");
                    Qt.quit();
                    return;
                }
                ClipboardHistory.clear();
                ClipboardHistory.paste(ClipboardHistory.ids[0]);
                step++;
            } else if (step === 1 && !ClipboardHistory.clearing) {
                if (ClipboardHistory.clearFailed || ClipboardHistory.ids.length !== 0 || ClipboardHistory.previews.length !== 0) {
                    console.error("FAIL Clearing should leave no history entries, even with an in-flight list");
                    Qt.quit();
                    return;
                }
                // Clearing must also work when only the current clipboard has data.
                ClipboardHistory.clear();
                step++;
            } else if (step === 2 && !ClipboardHistory.clearing) {
                if (ClipboardHistory.clearFailed || ClipboardHistory.ids.length !== 0) {
                    console.error("FAIL Clearing an empty history should succeed");
                } else {
                    console.log("PASS QML regression tests: clearing the clipboard and history");
                }
                Qt.quit();
            }
        }
    }
}
