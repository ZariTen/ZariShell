import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire
import Quickshell.Wayland

// On-screen pill for volume and brightness changes. Volume shows for any
// change of the default sink (keys, bar scroll, sliders, other apps); the IPC
// handlers below go through the same show path.
Scope {
    id: root

    // -- State and derived properties ---------------------------------------
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
    readonly property string tone: {
        if (kind === "muted")
            return "muted";
        if (over)
            return "warning";
        return "normal";
    }

    onSinkChanged: disarm(500)

    // -- Helper functions ---------------------------------------------------
    function disarm(milliseconds) {
        armed = false;
        arm.interval = milliseconds;
        arm.restart();
    }

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
        var audio = sink ? sink.audio : null;
        if (!audio)
            return;
        var text = audio.muted ? "Muted" : Math.round(audio.volume * 100) + "%";
        var what = audio.muted ? "muted" : "volume";
        if (!force && open && kind === what && label === text)
            return;
        show(audio.muted ? 0 : audio.volume, text, what);
    }

    // Any volume/mute change of the default sink, whoever made it.
    function audioEvent() {
        var audio = sink ? sink.audio : null;
        if (!audio)
            return;
        var changed = Math.abs(audio.volume - seenVolume) > 0.0005 || audio.muted !== seenMuted;
        seenVolume = audio.volume;
        seenMuted = audio.muted;
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

    // -- Visual tree --------------------------------------------------------
    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: window

            required property var modelData
            readonly property bool showHere: root.open && ShellState.isFocusedScreen(modelData)

            screen: modelData
            visible: showHere || pill.opacity > 0
            color: "transparent"
            aboveWindows: true
            exclusionMode: ExclusionMode.Ignore

            anchors.bottom: true
            margins.bottom: 48
            implicitWidth: Theme.widthPx(320)
            implicitHeight: Theme.px(80)

            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.namespace: "shell-osd"
            mask: Region {}

            Item {
                id: pill
                anchors.horizontalCenter: parent.horizontalCenter
                y: window.showHere ? 12 : 36
                width: Theme.widthPx(280)
                height: Theme.px(56)
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
                        font.pixelSize: Theme.iconPx(24)
                        color: {
                            if (root.kind === "muted")
                                return Theme.outline;
                            if (root.over)
                                return Theme.warning;
                            return Theme.accent;
                        }
                        codepoint: {
                            if (root.kind === "brightness")
                                return 0xF00DF;
                            return ShellState.volumeGlyph(Math.min(1, root.shown), root.kind === "muted");
                        }
                    }

                    Slider {
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignVCenter
                        implicitHeight: Theme.px(14)
                        interactive: false
                        value: root.shown
                        tone: root.tone
                    }

                    StyledText {
                        Layout.preferredWidth: Theme.px(48)
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

    // -- Lifecycle and background objects -----------------------------------
    Component.onCompleted: disarm(1500)

    PwObjectTracker {
        objects: root.sink ? [root.sink] : []
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
            var audio = root.sink ? root.sink.audio : null;
            if (audio) {
                root.seenVolume = audio.volume;
                root.seenMuted = audio.muted;
            }
            root.armed = true;
        }
    }

    Timer {
        id: hide
        interval: 1400
        onTriggered: root.open = false
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
}
