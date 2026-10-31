import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Bluetooth
import Quickshell.Io
import Quickshell.Services.Pipewire

// Quick settings: Wi-Fi and Bluetooth (tiles open their pickers), DND, volume,
// brightness, power.
Scope {
    id: root

    // -- State and derived properties ---------------------------------------
    readonly property bool open: ShellState.panel === "quicksettings"
    property string page: "main"   // "main" | "wifi" | "bluetooth"
    property bool hasBacklight: false
    property real brightness: 0
    readonly property var sink: Pipewire.defaultAudioSink
    readonly property var adapter: Bluetooth.defaultAdapter
    readonly property var btConnected: adapter ? adapter.devices.values.filter(device => device.connected) : []

    // -- Helper functions ---------------------------------------------------
    function refresh() {
        wifi.refresh(false);
        backlightQuery.running = true;
    }

    onOpenChanged: if (open) {
        page = "main";
        refresh();
    }

    // -- Visual tree --------------------------------------------------------
    DropPanel {
        name: "quicksettings"
        align: "right"
        cardWidth: Theme.widthPx(380)
        canGoBack: root.page !== "main"
        onBack: root.page = "main"

        ColumnLayout {
            id: mainPage
            Layout.fillWidth: true
            spacing: Theme.spacingM
            visible: root.page === "main"
            onVisibleChanged: if (visible) mainFade.restart()

            NumberAnimation {
                id: mainFade
                target: mainPage
                property: "opacity"
                from: 0
                to: 1
                duration: Theme.durMedium
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Theme.standard
            }

            PanelHeader {
                codepoint: 0xF0493 // md-cog
                title: "Quick settings"

                Button {
                    implicitWidth: Theme.px(28)
                    implicitHeight: Theme.px(28)
                    onClicked: ShellState.toggle("settings")
                    MdIcon {
                        anchors.centerIn: parent
                        codepoint: 0xF062E // md-tune
                    }
                }
                Button {
                    implicitWidth: Theme.px(28)
                    implicitHeight: Theme.px(28)
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
                uniformCellWidths: true
                rowSpacing: Theme.spacingS
                columnSpacing: Theme.spacingS

                // Tile body toggles the radio; the chevron opens the picker.
                ExpandTile {
                    codepoint: {
                        if (!wifi.radioOn)
                            return 0xF05AA;
                        if (wifi.activeSsid !== "")
                            return ShellState.wifiGlyph(wifi.activeSignal / 100);

                        return 0xF05A9;
                    }
                    label: "Wi-Fi"
                    sublabel: {
                        if (wifi.connecting !== "")
                            return "Connecting to " + wifi.connecting + "\u2026";
                        if (wifi.radioOn)
                            return wifi.activeSsid || "Not connected";
                        return wifi.wired !== "" ? "Off \u00b7 wired: " + wifi.wired : "Off";
                    }
                    active: wifi.radioOn
                    onClicked: wifi.setRadio()
                    onExpand: root.page = "wifi"
                }

                ExpandTile {
                    codepoint: root.adapter && root.adapter.enabled ? 0xF00AF : 0xF00B2 // md-bluetooth / md-bluetooth_off
                    label: "Bluetooth"
                    sublabel: {
                        if (!root.adapter)
                            return "No adapter";
                        if (!root.adapter.enabled)
                            return "Off";
                        if (root.btConnected.length > 0)
                            return root.btConnected.map(device => device.name).join(", ");
                        return "On";
                    }
                    active: root.adapter !== null && root.adapter.enabled
                    enabled: root.adapter !== null
                    onClicked: root.adapter.enabled = !root.adapter.enabled
                    onExpand: root.page = "bluetooth"
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
                    sublabel: "Lock, sleep, restart\u2026"
                    onClicked: ShellState.toggle("power")
                }
            }

            // System volume
            RowLayout {
                Layout.fillWidth: true
                visible: root.sink !== null && root.sink.audio !== null
                spacing: Theme.spacingS

                Button {
                    implicitWidth: Theme.px(28)
                    implicitHeight: Theme.px(28)
                    onClicked: root.sink.audio.muted = !root.sink.audio.muted
                    MdIcon {
                        anchors.centerIn: parent
                        codepoint: ShellState.sinkGlyph(root.sink)

                    }
                }
                Slider {
                    Layout.fillWidth: true
                    value: root.sink && root.sink.audio && !root.sink.audio.muted ? Math.min(1, root.sink.audio.volume) : 0
                    onMoved: ratio => {
                        root.sink.audio.muted = false;
                        root.sink.audio.volume = ratio;
                    }
                }
                StyledText {
                    Layout.preferredWidth: Theme.px(40)
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
                    Layout.preferredWidth: Theme.px(28)
                    codepoint: 0xF00DF
                }
                Slider {
                    Layout.fillWidth: true
                    value: root.brightness
                    onMoved: ratio => {
                        root.brightness = ratio;
                        backlightSet.command = ["brightnessctl", "-c", "backlight", "set", Math.max(1, Math.round(ratio * 100)) + "%"];
                        backlightSet.running = true;
                    }
                }
                StyledText {
                    Layout.preferredWidth: Theme.px(40)
                    horizontalAlignment: Text.AlignRight
                    text: Math.round(root.brightness * 100) + "%"
                    font.pixelSize: Theme.fontSmall
                    color: Theme.textSurfaceVariant
                }
            }
        }

        WifiPage {
            id: wifi
            shown: root.open && root.page === "wifi"
            onBack: root.page = "main"
        }

        BluetoothPage {
            shown: root.open && root.page === "bluetooth"
            onBack: root.page = "main"
        }
    }

    // -- Background objects -------------------------------------------------
    PwObjectTracker {
        objects: root.sink ? [root.sink] : []
    }

    // brightnessctl -m: device,class,current,percent%,max
    Process {
        id: backlightQuery
        command: ["brightnessctl", "-m", "-c", "backlight"]
        stdout: StdioCollector {
            onStreamFinished: {
                var match = /,(\d+)%,/.exec(text);
                root.hasBacklight = match !== null;
                if (match)
                    root.brightness = Number(match[1]) / 100;
            }
        }
    }

    Process {
        id: backlightSet
    }
}
