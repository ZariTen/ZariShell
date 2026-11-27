pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io

// Keyboard layouts of Hyprland's main keyboard, from `hyprctl devices -j`
// (layout "us,br", variant "intl,abnt2", active_layout_index). Updates on
// Hyprland's activelayout and configreloaded events. Empty without Hyprland.
// Shared by the bar, quick settings, and on-screen indicator.
Singleton {
    id: root

    readonly property bool available: !!Quickshell.env("HYPRLAND_INSTANCE_SIGNATURE")
    property string device: ""        // main keyboard name
    property var codes: []             // short code per layout: "US", "BR"
    property int index: 0              // active layout
    property string keymap: ""         // active layout's long name
    property bool capsLock: false
    readonly property bool several: codes.length > 1
    readonly property string code: codes.length > 0 ? codes[Math.max(0, Math.min(index, codes.length - 1))] : ""

    signal switched(string code, string keymap)

    function refresh() {
        if (available && !query.running) {
            query.startedSuccessfully = false;
            query.running = true;
        }
    }

    function next() {
        if (device === "")
            return;
        switcher.command = ["hyprctl", "switchxkblayout", device, "next"];
        switcher.running = true;
    }

    // "br(abnt2)" -> "BR"; a layout listed twice gets its variant: "US INTL".
    function shortCodes(layoutList, variantList) {
        var layouts = layoutList.split(",").map(layout => layout.trim().replace(/\(.*$/, "").toUpperCase());
        var variants = variantList.split(",");
        return layouts.map((layout, i) => {
            var variant = (variants[i] || "").trim().toUpperCase();
            var repeated = layouts.indexOf(layout) !== layouts.lastIndexOf(layout);
            return repeated && variant !== "" ? layout + " " + variant : layout;
        });
    }

    Component.onCompleted: refresh()

    Process {
        id: query
        property bool startedSuccessfully: false
        command: ["hyprctl", "devices", "-j"]
        stdout: StdioCollector { id: devicesOutput }
        onStarted: startedSuccessfully = true
        onRunningChanged: {
            if (!running && !startedSuccessfully)
                root.capsLock = false;
        }
        onExited: (exitCode, exitStatus) => {
            if (exitCode !== 0 || exitStatus !== 0) {
                root.capsLock = false;
                return;
            }
            try {
                var keyboards = JSON.parse(devicesOutput.text).keyboards;
                if (!Array.isArray(keyboards) || keyboards.some(entry => !entry || typeof entry !== "object" || Array.isArray(entry)))
                    throw new Error("Invalid keyboards array");
                var keyboard = keyboards.find(entry => entry.main === true) || keyboards[0];
                if (keyboard && (typeof keyboard.name !== "string" || typeof keyboard.layout !== "string"
                    || !Number.isInteger(keyboard.active_layout_index)
                    || (keyboard.variant !== undefined && typeof keyboard.variant !== "string")
                    || (keyboard.active_keymap !== undefined && typeof keyboard.active_keymap !== "string")))
                    throw new Error("Invalid keyboard layout");

                var previousDevice = root.device;
                var previousCode = root.code;
                var previousKeymap = root.keymap;
                root.device = keyboard ? keyboard.name : "";
                root.codes = keyboard && keyboard.layout ? root.shortCodes(keyboard.layout, keyboard.variant || "") : [];
                root.index = keyboard ? keyboard.active_layout_index : 0;
                root.keymap = keyboard ? keyboard.active_keymap || "" : "";
                root.capsLock = !!keyboard && keyboard.capsLock === true;
                if (root.device === previousDevice && previousCode && root.code
                    && (root.code !== previousCode || root.keymap !== previousKeymap))
                    root.switched(root.code, root.keymap);
            } catch (e) {
                root.capsLock = false;
            }
        }
    }

    Process {
        id: switcher
    }

    // Hyprland reports Caps Lock in devices JSON but doesn't emit a lock-key event.
    Timer {
        running: root.available
        repeat: true
        interval: 1000
        onTriggered: root.refresh()
    }

    // Each keyboard device sends its own event; refresh once per burst.
    Timer {
        id: debounce
        interval: 80
        onTriggered: {
            if (query.running)
                restart();
            else
                root.refresh();
        }
    }

    Connections {
        target: root.available ? Hyprland : null
        function onRawEvent(event) {
            if (event.name === "activelayout" || event.name === "configreloaded")
                debounce.restart();
        }
    }
}
