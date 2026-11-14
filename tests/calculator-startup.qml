import QtQuick
import Quickshell

ShellRoot {
    LauncherCalculator { id: calculator; active: true; query: "2+2" }
    Timer {
        interval: 600
        running: true
        onTriggered: {
            if (calculator.requestGeneration < 0 || calculator.busy || calculator.result !== "") {
                console.error("FAIL QML regression tests: failed startup left calculator busy or published output");
                Qt.quit();
                return;
            }
            console.log("READY calculator startup recovery");
            recovery.start();
        }
    }
    Timer {
        id: recovery
        interval: 300
        onTriggered: calculator.query = "3+3"
    }
    Timer {
        interval: 20
        running: true
        repeat: true
        onTriggered: {
            if (calculator.result === "") return;
            if (calculator.result !== "6" || calculator.busy)
                console.error("FAIL QML regression tests: startup recovery published wrong result");
            else
                console.log("PASS QML regression tests: failed startup clears busy and next query recovers");
            Qt.quit();
        }
    }
    Timer {
        interval: 5000
        running: true
        onTriggered: {
            console.error("FAIL QML regression tests: startup recovery timed out");
            Qt.quit();
        }
    }
}
