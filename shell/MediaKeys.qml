import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Services.Pipewire
import Quickshell.Wayland

Scope {
    id: root

    property var sink: Pipewire.defaultAudioSink
    property real shown: 0
    property string label: ""
    property string kind: "volume"
    property bool open: false

    PwObjectTracker {
        objects: root.sink ? [root.sink] : []
    }

    function show(value, text, what) {
        shown = value;
        label = text;
        kind = what;
        open = true;
        hide.restart();
    }

    function bumpVolume(delta) {
        if (!sink || !sink.audio)
            return;
        sink.audio.muted = false;
        sink.audio.volume = Math.max(0, Math.min(1.5, sink.audio.volume + delta));
        show(Math.min(1, sink.audio.volume), Math.round(sink.audio.volume * 100) + "%", "volume");
    }

    function toggleMute() {
        if (!sink || !sink.audio)
            return;
        sink.audio.muted = !sink.audio.muted;
        show(sink.audio.muted ? 0 : Math.min(1, sink.audio.volume), sink.audio.muted ? "Muted" : Math.round(sink.audio.volume * 100) + "%", sink.audio.muted ? "muted" : "volume");
    }

    function bumpBrightness(up) {
        brightness.command = ["brightnessctl", "set", up ? "5%+" : "5%-"];
        brightness.running = true;
    }

    IpcHandler {
        target: "media"

        function volumeUp(): void { root.bumpVolume(0.05); }
        function volumeDown(): void { root.bumpVolume(-0.05); }
        function volumeMute(): void { root.toggleMute(); }
        function brightnessUp(): void { root.bumpBrightness(true); }
        function brightnessDown(): void { root.bumpBrightness(false); }
    }

    Process {
        id: brightness
        stdout: StdioCollector {
            onStreamFinished: {
                var match = /(\d+)%/.exec(text);
                if (match)
                    root.show(Number(match[1]) / 100, match[1] + "%", "brightness");
            }
        }
    }

    Timer {
        id: hide
        interval: 1400
        onTriggered: root.open = false
    }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: window

            required property var modelData
            readonly property var monitor: Hyprland.monitorFor(modelData)
            readonly property bool showHere: {
                if (!root.open)
                    return false;
                if (Hyprland.focusedMonitor === null)
                    return modelData === Quickshell.screens[0];
                return monitor !== null && monitor.name === Hyprland.focusedMonitor.name;
            }

            screen: modelData
            visible: showHere || pill.opacity > 0
            color: "transparent"
            aboveWindows: true
            exclusionMode: ExclusionMode.Ignore

            anchors.bottom: true
            margins.bottom: 48
            implicitWidth: 320
            implicitHeight: 80

            WlrLayershell.namespace: "shell-osd"
            mask: Region {}

            Rectangle {
                id: pill
                anchors.horizontalCenter: parent.horizontalCenter
                y: window.showHere ? 12 : 36
                width: 280
                height: 56
                radius: Theme.radiusLarge
                color: "transparent"

                Glass {
                    anchors.fill: parent
                    tint: Theme.glassTintStrong
                }
                opacity: window.showHere ? 1 : 0

                Behavior on opacity { NumberAnimation { duration: Theme.durMedium; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.standard } }
                Behavior on y { NumberAnimation { duration: Theme.durLong; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.emphasized } }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 10
                    anchors.rightMargin: Theme.spacingL
                    spacing: Theme.spacingM

                    Rectangle {
                        implicitWidth: 36
                        implicitHeight: 36
                        radius: Theme.radius
                        color: "transparent"

                        MdIcon {
                            anchors.centerIn: parent
                            font.pixelSize: 18
                            color: root.kind === "muted" ? Theme.outline : Theme.glow
                            codepoint: {
                                if (root.kind === "brightness")
                                    return 0xF00DF;
                                if (root.kind === "muted" || root.shown <= 0)
                                    return 0xF0581;
                                return root.shown < 0.34 ? 0xF057F : (root.shown < 0.67 ? 0xF0580 : 0xF057E);
                            }
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: 14
                        radius: 2
                        color: Qt.rgba(0, 0, 0, 0.5)
                        border.width: 1
                        border.color: Qt.rgba(1, 1, 1, 0.25)

                        Rectangle {
                            width: (parent.width - 2) * Math.max(0, Math.min(1, root.shown))
                            x: 1
                            y: 1
                            height: parent.height - 2
                            radius: 1
                            // Win7 glossy green progress fill
                            gradient: Gradient {
                                GradientStop { position: 0.0; color: root.kind === "muted" ? "#9a9a9a" : "#b6f39a" }
                                GradientStop { position: 0.45; color: root.kind === "muted" ? "#6b6b6b" : "#4fc22a" }
                                GradientStop { position: 0.5; color: root.kind === "muted" ? "#555555" : "#2f9e12" }
                                GradientStop { position: 1.0; color: root.kind === "muted" ? "#777777" : "#5fd23a" }
                            }
                            Behavior on width { NumberAnimation { duration: Theme.durShort; easing.type: Easing.OutCubic } }
                        }
                    }

                    StyledText {
                        Layout.preferredWidth: 44
                        horizontalAlignment: Text.AlignRight
                        text: root.label
                        font.weight: Font.DemiBold
                    }
                }
            }
        }
    }
}
