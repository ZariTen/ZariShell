import QtQuick
import Quickshell
import "Command.js" as Command

ShellRoot {
    Timer {
        interval: 20
        running: true
        onTriggered: {
            var args = Command.parse('"/session dir/start" "two words" %% %f', true);
            if (JSON.stringify(args) !== JSON.stringify(["/session dir/start", "two words", "%"]))
                console.error("FAIL QML regression tests: shared command parser");
            else
                console.log("PASS QML regression tests: shared command parser");
            Qt.quit();
        }
    }
}
