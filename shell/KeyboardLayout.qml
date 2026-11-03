import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io

// Keyboard layouts of Hyprland's main keyboard, from `hyprctl devices -j`
// (layout "us,br", variant "intl,abnt2", active_layout_index). Updates on
// Hyprland's activelayout and configreloaded events. Empty without Hyprland.
Scope {
    id: root

    readonly property bool available: !!Quickshell.env("HYPRLAND_INSTANCE_SIGNATURE")
    property string device: ""        // main keyboard name
    property var codes: []             // short code per layout: "US", "BR"
    property int index: 0              // active layout
    property string keymap: ""         // active layout's long name
    readonly property string code: codes.length > 0 ? codes[Math.max(0, Math.min(index, codes.length - 1))] : ""

    function refresh() {
        if (available)
            query.running = true;
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
        command: ["hyprctl", "devices", "-j"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    var keyboards = JSON.parse(text).keyboards || [];
                    var keyboard = keyboards.find(entry => entry.main) || keyboards[0];
                    root.device = keyboard ? keyboard.name : "";
                    root.codes = keyboard && keyboard.layout ? root.shortCodes(keyboard.layout, keyboard.variant || "") : [];
                    root.index = keyboard ? keyboard.active_layout_index : 0;
                    root.keymap = keyboard ? keyboard.active_keymap : "";
                } catch (e) {
                    root.codes = [];
                }
            }
        }
    }

    Process {
        id: switcher
    }

    // Each keyboard device sends its own event; refresh once per burst.
    Timer {
        id: debounce
        interval: 80
        onTriggered: root.refresh()
    }

    Connections {
        target: root.available ? Hyprland : null
        function onRawEvent(event) {
            if (event.name === "activelayout" || event.name === "configreloaded")
                debounce.restart();
        }
    }
}
