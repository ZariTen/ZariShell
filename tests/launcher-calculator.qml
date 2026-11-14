import QtQuick
import Quickshell

ShellRoot {
    property int step: 0
    LauncherCalculator { id: calculator; active: true; query: "2+2" }
    Timer {
        interval: 30
        running: true
        repeat: true
        onTriggered: {
            try {
                if (calculator.result === "") return;
                if (step === 0) {
                    if (calculator.result !== "4") throw new Error("Arithmetic: " + calculator.result);
                    calculator.query = "= sqrt(81)";
                    if (calculator.result !== "") throw new Error("Old result survived editing");
                } else if (step === 1) {
                    if (calculator.result !== "9") throw new Error("Function: " + calculator.result);
                    calculator.query = "= 10 km to mi";
                } else if (step === 2) {
                    if (!/^6\.213\d* mi$/.test(calculator.result)) throw new Error("Conversion: " + calculator.result);
                    calculator.query = "= -sqrt(81)";
                } else if (step === 3) {
                    if (!/^[-−]9$/.test(calculator.result)) throw new Error("Negative function: " + calculator.result);
                    calculator.query = "= -pi";
                } else {
                    if (!/^[-−]3\.14159/.test(calculator.result)) throw new Error("Negative constant: " + calculator.result);
                    calculator.active = false;
                    if (calculator.result !== "" || calculator.expression !== "") throw new Error("Inactive calculator retained result");
                    console.log("PASS QML regression tests: real qalc arithmetic, functions, units, and invalidation");
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
