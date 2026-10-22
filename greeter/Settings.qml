pragma Singleton
import QtQuick
import Quickshell

// Greeter stand-in for the shell's Settings singleton (same get() API).
// The greeter runs as the greeter user and cannot read the user's
// settings.json, so it always uses the theme values.
Singleton {
    readonly property var values: ({})
    readonly property bool invalid: false

    function get(key, fallback) {
        return fallback;
    }

    function has(key) {
        return false;
    }
}
