import QtQuick
import Quickshell
import Quickshell.Io
import "CalculatorQuery.js" as CalculatorQuery

Scope {
    id: root
    property string query: ""
    property bool active: false
    readonly property string expression: active ? CalculatorQuery.expression(query) : ""
    property string result: ""
    property int generation: 0
    property int requestGeneration: -1
    property bool busy: false
    property bool processStarted: false
    property bool outputDone: false
    property bool errorsDone: false
    property bool exitDone: false
    property int exitCode: -1
    property string output: ""
    property string errors: ""

    onQueryChanged: invalidate()
    onActiveChanged: invalidate()

    function invalidate() {
        generation++;
        result = "";
        debounce.restart();
    }

    function start() {
        if (busy || expression === "" || requestGeneration === generation)
            return;
        requestGeneration = generation;
        busy = true;
        processStarted = false;
        outputDone = false;
        errorsDone = false;
        exitDone = false;
        output = "";
        errors = "";
        calculation.command = ["timeout", "2s", "qalc", "-t", "-defaults",
            "-s", "update exchange rates 0", "-s", "autoconversion 0",
            "-s", "decimal comma 0", "-m", "500", "--", expression];
        calculation.running = true;
    }

    function finish() {
        // Collectors and process exit can arrive in either order.
        if (!outputDone || !errorsDone || !exitDone)
            return;
        busy = false;
        if (requestGeneration === generation && expression !== "" && exitCode === 0
                && errors.trim() === "" && output.trim() !== "" && output.trim().indexOf("\n") === -1)
            result = output.trim();
        if (!debounce.running)
            Qt.callLater(start);
    }

    Timer {
        id: debounce
        interval: 150
        onTriggered: root.start()
    }

    Process {
        id: calculation
        onStarted: root.processStarted = true
        onRunningChanged: {
            // FailedToStart emits neither exited nor collector completion.
            if (!running && root.busy && !root.processStarted) {
                root.exitCode = -1;
                root.outputDone = true;
                root.errorsDone = true;
                root.exitDone = true;
                root.finish();
            }
        }
        stdout: StdioCollector {
            onStreamFinished: {
                root.output = text;
                root.outputDone = true;
                root.finish();
            }
        }
        stderr: StdioCollector {
            onStreamFinished: {
                root.errors = text;
                root.errorsDone = true;
                root.finish();
            }
        }
        onExited: (exitCode, exitStatus) => {
            root.exitCode = exitStatus === 0 ? exitCode : -1;
            root.exitDone = true;
            root.finish();
        }
    }
}
