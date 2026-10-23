pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// User settings: ${XDG_CONFIG_HOME:-~/.config}/zarishell/settings.json, a flat
// JSON object written by the settings panel (or by hand; edits apply live).
// Theme reads it through get(): a key present here wins over theme.json,
// which wins over the neutral defaults. Missing keys mean "use the theme".
//
// Writes are debounced; the file view ignores the echo of its own write, so
// there is no read/write loop. A malformed file is treated as empty (one
// warning per bad content) and is never overwritten: panel edits then apply
// in memory only until the file is fixed or deleted.
//
// JsonAdapter is not used on purpose: it serializes every declared property,
// so it cannot tell "unset" (follow the theme) from a stored value.
Singleton {
    id: root

    // -- Public properties --------------------------------------------------
    readonly property string path: (Quickshell.env("XDG_CONFIG_HOME") || (Quickshell.env("HOME") + "/.config")) + "/zarishell/settings.json"
    property var values: ({})
    property bool invalid: false

    // -- Internal state -----------------------------------------------------
    property string lastWrittenText: ""
    property string lastWarnedText: ""

    // -- Helper functions ---------------------------------------------------
    // Stored value for key, or fallbackValue when unset or of the wrong type.
    function get(key, fallbackValue) {
        var rawValue = values[key];
        if (rawValue === undefined || rawValue === null)
            return fallbackValue;
        if (fallbackValue !== undefined && typeof rawValue !== typeof fallbackValue)
            return fallbackValue;
        return rawValue;
    }

    function has(key) {
        return values[key] !== undefined && values[key] !== null;
    }

    function set(key, value) {
        if (values[key] === value)
            return;
        var nextValues = Object.assign({}, values);
        nextValues[key] = value;
        values = nextValues;
        saveTimer.restart();
    }

    function reset(key) {
        resetKeys([key]);
    }

    function resetKeys(keys) {
        var nextValues = Object.assign({}, values);
        var hasChanged = false;
        for (var i = 0; i < keys.length; i++) {
            if (nextValues[keys[i]] !== undefined) {
                delete nextValues[keys[i]];
                hasChanged = true;
            }
        }
        if (!hasChanged)
            return;
        values = nextValues;
        saveTimer.restart();
    }

    function ingest(jsonText) {
        if (jsonText === lastWrittenText)
            return;
        if (jsonText.trim() === "") {
            invalid = false;
            values = {};
            return;
        }
        try {
            var parsedObject = JSON.parse(jsonText);
            if (parsedObject === null || typeof parsedObject !== "object" || Array.isArray(parsedObject))
                throw "not a JSON object";
            invalid = false;
            values = parsedObject;
        } catch (parseError) {
            if (jsonText !== lastWarnedText) {
                console.warn("Settings: invalid " + path + " (" + parseError + "); using defaults, the file is left untouched");
                lastWarnedText = jsonText;
            }
            invalid = true;
            values = {};
        }
    }

    // -- Lifecycle and background objects -----------------------------------
    Component.onCompleted: ingest(settingsFile.text())

    Timer {
        id: saveTimer
        interval: 400
        onTriggered: {
            if (root.invalid)
                return;
            var formattedJson = JSON.stringify(root.values, null, 2) + "\n";
            root.lastWrittenText = formattedJson;
            settingsFile.setText(formattedJson);
        }
    }

    FileView {
        id: settingsFile
        path: root.path
        watchChanges: true
        blockLoading: true
        printErrors: false
        atomicWrites: true
        onLoaded: root.ingest(text())
        onFileChanged: reload()
        onLoadFailed: {
            // Missing file: defaults.
            root.invalid = false;
            root.values = {};
        }
    }

    IpcHandler {
        target: "settings"

        function open(): void { ShellState.panel = "settings"; }
        function close(): void { if (ShellState.panel === "settings") ShellState.close(); }
        function toggle(): void { ShellState.toggle("settings"); }
        // value is JSON ("1.25", "true", "\"#ff8800\""); a bare word is a string.
        function set(key: string, value: string): void {
            var parsedValue;
            try {
                parsedValue = JSON.parse(value);
            } catch (parseError) {
                parsedValue = value;
            }
            root.set(key, parsedValue);
        }
        function reset(key: string): void { root.reset(key); }
        function get(key: string): string { return JSON.stringify(root.values[key] === undefined ? null : root.values[key]); }
    }
}
