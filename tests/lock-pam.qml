import QtQuick
import Quickshell

ShellRoot {
    Lock { id: lock }

    Timer {
        interval: 50
        running: true
        onTriggered: {
            try {
                // pamService reads the real context's config; no PAM or lock is started.
                var expected = Quickshell.env("ZARISHELL_TEST_EXPECTED_PAM_SERVICE") || "hyprlock";
                if (lock.pamService !== expected)
                    throw new Error("Expected PAM service " + expected + ", got " + lock.pamService);
                if (lock.locked || lock.busy)
                    throw new Error("Inspection must leave Lock idle and unlocked");
                console.log("PASS QML regression tests: Lock PAM service " + expected);
            } catch (error) {
                console.error("FAIL QML regression tests: " + error.message);
            }
            Qt.quit();
        }
    }
}
