import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Bluetooth
import Quickshell.Io
import Quickshell.Services.Pipewire

// Quick settings: Wi-Fi, Bluetooth, DND, volume, brightness, power.
Scope {
    id: root

    readonly property bool open: ShellState.panel === "quicksettings"
    property bool wifiOn: false
    property string ssid: ""
    property string wired: ""
    property bool hasBacklight: false
    property real brightness: 0
    readonly property var sink: Pipewire.defaultAudioSink
    readonly property var adapter: Bluetooth.defaultAdapter
    readonly property var btConnected: adapter ? adapter.devices.values.filter(d => d.connected) : []

    function refresh() {
        netQuery.running = true;
        backlightQuery.running = true;
    }

    onOpenChanged: if (open) refresh()

    PwObjectTracker {
        objects: root.sink ? [root.sink] : []
    }

    // "WIFI\n<on/off>" then "dev:type:state:connection" lines, then active SSID.
    Process {
        id: netQuery
        command: ["sh", "-c", "nmcli -t -f WIFI g; echo ---; nmcli -t -f TYPE,STATE,CONNECTION dev; echo ---; nmcli -t -f ACTIVE,SSID dev wifi 2>/dev/null | grep '^yes:' | head -1 | cut -d: -f2-"]
        stdout: StdioCollector {
            onStreamFinished: {
                var parts = text.split("---\n");
                root.wifiOn = (parts[0] || "").trim() === "enabled";
                var wired = "";
                (parts[1] || "").split("\n").forEach(l => {
                    var f = l.split(":");
                    if (f[0] === "ethernet" && f[1] === "connected" && wired === "")
                        wired = f.slice(2).join(":");
                });
                root.wired = wired;
                root.ssid = (parts[2] || "").trim();
            }
        }
    }

    Process {
        id: wifiToggle
        onExited: netQuery.running = true
    }

    // brightnessctl -m: device,class,current,percent%,max
    Process {
        id: backlightQuery
        command: ["brightnessctl", "-m", "-c", "backlight"]
        stdout: StdioCollector {
            onStreamFinished: {
                var m = /,(\d+)%,/.exec(text);
                root.hasBacklight = m !== null;
                if (m)
                    root.brightness = Number(m[1]) / 100;
            }
        }
    }

    Process {
        id: backlightSet
    }

    DropPanel {
        name: "quicksettings"
        align: "right"
        cardWidth: 360

        PanelHeader {
            codepoint: 0xF0493 // md-cog
            title: "Quick settings"

            AeroButton {
                implicitWidth: 30
                implicitHeight: 28
                onClicked: ShellState.toggle("power")
                MdIcon {
                    anchors.centerIn: parent
                    codepoint: 0xF0425 // md-power
                    color: Theme.error
                }
            }
        }

        GridLayout {
            Layout.fillWidth: true
            columns: 2
            rowSpacing: Theme.spacingS
            columnSpacing: Theme.spacingS

            Tile {
                codepoint: root.wifiOn ? 0xF05A9 : 0xF05AA
                label: "Wi-Fi"
                sublabel: root.wifiOn ? (root.ssid || "Not connected") : (root.wired !== "" ? "Off · wired: " + root.wired : "Off")
                active: root.wifiOn
                onClicked: {
                    wifiToggle.command = ["nmcli", "radio", "wifi", root.wifiOn ? "off" : "on"];
                    wifiToggle.running = true;
                }
            }

            Tile {
                codepoint: root.adapter && root.adapter.enabled ? 0xF00AF : 0xF00B2 // md-bluetooth / md-bluetooth_off
                label: "Bluetooth"
                sublabel: !root.adapter ? "No adapter" : (!root.adapter.enabled ? "Off" : (root.btConnected.length > 0 ? root.btConnected.map(d => d.name).join(", ") : "On"))
                active: root.adapter !== null && root.adapter.enabled
                enabled: root.adapter !== null
                onClicked: root.adapter.enabled = !root.adapter.enabled
            }

            Tile {
                codepoint: Notifs.dnd ? 0xF009B : 0xF009A
                label: "Do not disturb"
                sublabel: Notifs.dnd ? "Toasts hidden" : "Off"
                active: Notifs.dnd
                onClicked: Notifs.dnd = !Notifs.dnd
            }

            Tile {
                codepoint: 0xF0425
                label: "Power"
                sublabel: "Lock, sleep, restart…"
                onClicked: ShellState.toggle("power")
            }
        }

        // System volume
        RowLayout {
            Layout.fillWidth: true
            visible: root.sink !== null && root.sink.audio !== null
            spacing: Theme.spacingS

            AeroButton {
                implicitWidth: 30
                implicitHeight: 28
                onClicked: root.sink.audio.muted = !root.sink.audio.muted
                MdIcon {
                    anchors.centerIn: parent
                    readonly property real v: root.sink && root.sink.audio ? root.sink.audio.volume : 0
                    codepoint: !root.sink || !root.sink.audio || root.sink.audio.muted || v <= 0 ? 0xF0581 : (v < 0.34 ? 0xF057F : (v < 0.67 ? 0xF0580 : 0xF057E))
                }
            }
            GlossySlider {
                Layout.fillWidth: true
                value: root.sink && root.sink.audio && !root.sink.audio.muted ? Math.min(1, root.sink.audio.volume) : 0
                onMoved: v => {
                    root.sink.audio.muted = false;
                    root.sink.audio.volume = v;
                }
            }
            StyledText {
                Layout.preferredWidth: 40
                horizontalAlignment: Text.AlignRight
                text: root.sink && root.sink.audio ? (root.sink.audio.muted ? "Muted" : Math.round(root.sink.audio.volume * 100) + "%") : ""
                font.pixelSize: Theme.fontSmall
                color: Theme.textSurfaceVariant
            }
        }

        // Brightness (only with a backlight device)
        RowLayout {
            Layout.fillWidth: true
            visible: root.hasBacklight
            spacing: Theme.spacingS

            MdIcon {
                Layout.preferredWidth: 30
                codepoint: 0xF00DF
            }
            GlossySlider {
                Layout.fillWidth: true
                value: root.brightness
                onMoved: v => {
                    root.brightness = v;
                    backlightSet.command = ["brightnessctl", "-c", "backlight", "set", Math.max(1, Math.round(v * 100)) + "%"];
                    backlightSet.running = true;
                }
            }
            StyledText {
                Layout.preferredWidth: 40
                horizontalAlignment: Text.AlignRight
                text: Math.round(root.brightness * 100) + "%"
                font.pixelSize: Theme.fontSmall
                color: Theme.textSurfaceVariant
            }
        }
    }
}
