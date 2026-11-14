import QtQuick
import Quickshell

ShellRoot {
    property int step: 0
    LauncherCalculator { id: calculator; active: true; query: "2+2" }
    Timer {
        interval: 20
        running: true
        repeat: true
        onTriggered: {
            try {
                if (step === 0 || step === 6) {
                    if (!calculator.busy) return;
                    if (step === 0) calculator.query = "3+3";
                    else calculator.active = false;
                } else if (step === 1 || step === 5 || step === 8) {
                    if (calculator.result === "") return;
                    var expected = step === 1 ? "6" : step === 5 ? "10" : "9";
                    if (calculator.result !== expected) throw new Error("Stale/partial result: " + calculator.result);
                    calculator.query = step === 1 ? "9/0" : step === 5 ? "6+6" : "Firefox";
                } else {
                    if (calculator.busy || (step !== 7 && calculator.requestGeneration !== calculator.generation)) return;
                    if (calculator.result !== "") throw new Error("Failed/cancelled job published output");
                    if (step === 2) calculator.query = "8+8";
                    if (step === 3) calculator.query = "4+4";
                    if (step === 4) calculator.query = "5+5";
                    if (step === 7) {
                        calculator.active = true;
                        calculator.query = "= sqrt(81)";
                    }
                }
                step++;
            } catch (error) {
                console.error("FAIL QML regression tests: " + error.message);
                Qt.quit();
            }
        }
    }
    Timer {
        interval: 350
        running: step === 9
        onTriggered: {
            if (calculator.result !== "" || calculator.busy || calculator.expression !== "")
                console.error("FAIL QML regression tests: application search started calculation");
            else
                console.log("PASS QML regression tests: stale jobs, split output, errors, timeout, recovery, and inactive results");
            Qt.quit();
        }
    }
}
