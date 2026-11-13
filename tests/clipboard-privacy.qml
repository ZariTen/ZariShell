import QtQuick
import Quickshell

ShellRoot {
    ClipboardWatcher { id: watcher }
    property int step: 0
    function check(ok, message) { if (!ok) throw new Error(message); }
    Timer {
        interval: 150
        repeat: true
        running: true
        onTriggered: {
            try {
                if (step === 0) {
                    check(Theme.clipboardHistory === true, "History must default to enabled");
                    check(watcher.restartPending, "Exited fake watcher must have a pending restart");
                    Settings.set("clipboardHistory", false);
                } else if (step === 1) {
                    check(!watcher.watching && !watcher.restartPending, "Opt-out must stop watcher and restart timer");
                    ClipboardHistory.ids = ["42"];
                    ClipboardHistory.previews = ["private"];
                    Settings.set("clipboardHistory", true);
                } else if (step === 2) {
                    check(watcher.watching, "Re-enable must restart watcher after imperative stop");
                    ClipboardHistory.refresh();
                } else if (step === 3) {
                    check(ClipboardHistory.ids.length === 1, "Enabled history must query fake database");
                    Settings.set("clipboardHistory", false);
                } else if (step === 4) {
                    check(!watcher.watching && !watcher.restartPending, "Second opt-out must remain reactive");
                    check(ClipboardHistory.ids.length === 0 && ClipboardHistory.previews.length === 0, "Opt-out must remove stale cache");
                    ClipboardHistory.refresh();
                    ClipboardHistory.paste("42");
                } else {
                    check(ClipboardHistory.ids.length === 0, "Disabled history must stay empty");
                    console.log("PASS QML regression tests: clipboard opt-out");
                    Qt.quit();
                }
                step++;
            } catch (error) {
                console.error("FAIL QML regression tests: " + error.message);
                Qt.quit();
            }
        }
    }
}
