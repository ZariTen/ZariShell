import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Services.Pipewire
import Quickshell.Wayland

// On-screen pill for volume and brightness changes. Volume shows for any
// change of the default sink (keys, bar scroll, sliders, other apps); the IPC
// handlers below go through the same show path.
Scope {
    id: root

    property var sink: Pipewire.defaultAudioSink
    property real shown: 0
    property string label: ""
    property string kind: "volume"
    property bool open: false

    // Volume events are ignored right after startup, a sink switch or a sink
    // becoming ready, when its values are just being populated.
    property bool armed: false
    property real seenVolume: -1
    property bool seenMuted: false

    readonly property bool over: kind === "volume" && shown > 1.001

    // Meter tone: muted, warning above 100%, else normal.
    readonly property string tone: kind === "muted" ? "muted" : (over ? "warning" : "normal")

    PwObjectTracker {
        objects: root.sink ? [root.sink] : []
    }

    function disarm(ms) {
        armed = false;
        arm.interval = ms;
        arm.restart();
    }

    onSinkChanged: disarm(500)
    Component.onCompleted: disarm(1500)

    function show(value, text, what) {
        shown = value;
        label = text;
        kind = what;
        open = true;
        hide.restart();
    }

    // Show the sink's current state. Unless forced, skips a repeat of what is
    // already on screen.
    function showAudio(force) {
        var a = sink ? sink.audio : null;
        if (!a)
            return;
        var text = a.muted ? "Muted" : Math.round(a.volume * 100) + "%";
        var what = a.muted ? "muted" : "volume";
        if (!force && open && kind === what && label === text)
            return;
        show(a.muted ? 0 : a.volume, text, what);
    }

    // Any volume/mute change of the default sink, whoever made it.
    function audioEvent() {
        var a = sink ? sink.audio : null;
        if (!a)
            return;
        var changed = Math.abs(a.volume - seenVolume) > 0.0005 || a.muted !== seenMuted;
        seenVolume = a.volume;
        seenMuted = a.muted;
        if (armed && changed)
            showAudio(false);
    }

    function bumpVolume(delta) {
        if (!sink || !sink.audio)
            return;
        sink.audio.muted = false;
        sink.audio.volume = Math.max(0, Math.min(1.5, sink.audio.volume + delta));
        showAudio(true);
    }

    function toggleMute() {
        if (!sink || !sink.audio)
            return;
        sink.audio.muted = !sink.audio.muted;
        showAudio(true);
    }

    function bumpBrightness(up) {
        brightness.command = ["brightnessctl", "set", up ? "5%+" : "5%-"];
        brightness.running = true;
    }

    Connections {
        target: root.sink
        function onReadyChanged() {
            root.disarm(500);
        }
    }

    // `audio` has no change signal; depending on `ready` re-evaluates it.
    Connections {
        target: root.sink && root.sink.ready ? root.sink.audio : null
        function onVolumesChanged() {
            root.audioEvent();
        }
        function onMutedChanged() {
            root.audioEvent();
        }
    }

    Timer {
        id: arm
        onTriggered: {
            var a = root.sink ? root.sink.audio : null;
            if (a) {
                root.seenVolume = a.volume;
                root.seenMuted = a.muted;
            }
            root.armed = true;
        }
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

            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.namespace: "shell-osd"
            mask: Region {}

            Item {
                id: pill
                anchors.horizontalCenter: parent.horizontalCenter
                y: window.showHere ? 12 : 36
                width: 280
                height: 56
                opacity: window.showHere ? 1 : 0

                Behavior on opacity { NumberAnimation { duration: Theme.durMedium; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.standard } }
                Behavior on y { NumberAnimation { duration: Theme.durLong; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.emphasized } }

                Surface {
                    anchors.fill: parent
                    radius: Theme.radiusLarge
                    color: Theme.panel
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: Theme.spacingM
                    anchors.rightMargin: Theme.spacingL
                    spacing: Theme.spacingM

                    MdIcon {
                        Layout.alignment: Qt.AlignVCenter
                        font.pixelSize: 24
                        color: root.kind === "muted" ? Theme.outline : (root.over ? Theme.warning : Theme.accent)
                        codepoint: {
                            if (root.kind === "brightness")
                                return 0xF00DF;
                            if (root.kind === "muted" || root.shown <= 0)
                                return 0xF0581;
                            var v = Math.min(1, root.shown);
                            return v < 0.34 ? 0xF057F : (v < 0.67 ? 0xF0580 : 0xF057E);
                        }
                    }

                    Slider {
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignVCenter
                        implicitHeight: 14
                        interactive: false
                        value: root.shown
                        tone: root.tone
                    }

                    StyledText {
                        Layout.preferredWidth: 48
                        Layout.alignment: Qt.AlignVCenter
                        horizontalAlignment: Text.AlignRight
                        text: root.label
                        font.weight: Font.DemiBold
                        color: root.over ? Theme.warning : Theme.textSurface
                    }
                }
            }
        }
    }
}
