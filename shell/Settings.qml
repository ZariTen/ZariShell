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

    readonly property string path: (Quickshell.env("XDG_CONFIG_HOME") || (Quickshell.env("HOME") + "/.config")) + "/zarishell/settings.json"
    property var values: ({})
    property bool invalid: false
    property string lastWritten: ""
    property string lastWarned: ""

    // Stored value for key, or fallback when unset or of the wrong type.
    function get(key, fallback) {
        var v = values[key];
        if (v === undefined || v === null)
            return fallback;
        if (fallback !== undefined && typeof v !== typeof fallback)
            return fallback;
        return v;
    }

    function has(key) {
        return values[key] !== undefined && values[key] !== null;
    }

    function set(key, value) {
        if (values[key] === value)
            return;
        var next = Object.assign({}, values);
        next[key] = value;
        values = next;
        save.restart();
    }

    function reset(key) {
        resetKeys([key]);
    }

    function resetKeys(keys) {
        var next = Object.assign({}, values);
        var changed = false;
        for (var i = 0; i < keys.length; i++) {
            if (next[keys[i]] !== undefined) {
                delete next[keys[i]];
                changed = true;
            }
        }
        if (!changed)
            return;
        values = next;
        save.restart();
    }

    function ingest(text) {
        if (text === lastWritten)
            return;
        if (text.trim() === "") {
            invalid = false;
            values = {};
            return;
        }
        try {
            var o = JSON.parse(text);
            if (o === null || typeof o !== "object" || Array.isArray(o))
                throw "not a JSON object";
            invalid = false;
            values = o;
        } catch (e) {
            if (text !== lastWarned) {
                console.warn("Settings: invalid " + path + " (" + e + "); using defaults, the file is left untouched");
                lastWarned = text;
            }
            invalid = true;
            values = {};
        }
    }

    Component.onCompleted: ingest(file.text())

    Timer {
        id: save
        interval: 400
        onTriggered: {
            if (root.invalid)
                return;
            var text = JSON.stringify(root.values, null, 2) + "\n";
            root.lastWritten = text;
            file.setText(text);
        }
    }

    FileView {
        id: file
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
            var v;
            try { v = JSON.parse(value); } catch (e) { v = value; }
            root.set(key, v);
        }
        function reset(key: string): void { root.reset(key); }
        function get(key: string): string { return JSON.stringify(root.values[key] === undefined ? null : root.values[key]); }
    }
}
