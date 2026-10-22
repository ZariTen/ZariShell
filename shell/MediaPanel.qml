import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Services.Mpris
import Quickshell.Wayland
import Quickshell.Widgets

// Dropdown media player under the bar's media button.
Scope {
    id: root

    readonly property bool open: ShellState.panel === "media"
    readonly property var player: ShellState.player
    readonly property var players: Mpris.players.values

    // Per-player volume via MPRIS (slider hidden when the player lacks it).
    readonly property bool hasVolume: player !== null && player.volumeSupported && player.canControl
    readonly property real volume: hasVolume ? player.volume : 0
    readonly property bool muted: hasVolume && player.volume <= 0
    property real restoreVolume: 0.5

    function setVolume(v) {
        if (hasVolume)
            player.volume = Math.max(0, Math.min(1, v));
    }

    function toggleMute() {
        if (!hasVolume)
            return;
        if (player.volume > 0) {
            restoreVolume = player.volume;
            player.volume = 0;
        } else {
            player.volume = restoreVolume > 0 ? restoreVolume : 0.5;
        }
    }

    function fmt(seconds) {
        if (!isFinite(seconds) || seconds < 0)
            seconds = 0;
        var s = Math.floor(seconds);
        var h = Math.floor(s / 3600);
        var m = Math.floor((s % 3600) / 60);
        var sec = s % 60;
        var mm = h > 0 && m < 10 ? "0" + m : "" + m;
        return (h > 0 ? h + ":" : "") + mm + ":" + (sec < 10 ? "0" : "") + sec;
    }

    // Mpris position isn't pushed live; poke it while visible and playing.
    Timer {
        running: root.open && root.player !== null && root.player.isPlaying
        interval: 1000
        repeat: true
        triggeredOnStart: true
        onTriggered: root.player.positionChanged()
    }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: window

            required property var modelData
            readonly property var monitor: Hyprland.monitorFor(modelData)
            readonly property bool focusedHere: {
                if (!root.open)
                    return false;
                if (Hyprland.focusedMonitor === null)
                    return modelData === Quickshell.screens[0];
                return monitor !== null && monitor.name === Hyprland.focusedMonitor.name;
            }

            screen: modelData
            visible: focusedHere || card.opacity > 0
            color: "transparent"
            aboveWindows: true
            exclusionMode: ExclusionMode.Ignore

            anchors {
                top: true
                bottom: true
                left: true
                right: true
            }

            WlrLayershell.namespace: "shell-panel"
            WlrLayershell.keyboardFocus: focusedHere ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

            onFocusedHereChanged: if (focusedHere) card.forceActiveFocus()

            MouseArea {
                anchors.fill: parent
                onClicked: ShellState.close()
            }

            Item {
                id: card

                readonly property bool shown: window.focusedHere
                readonly property var p: root.player

                anchors.horizontalCenter: parent.horizontalCenter
                y: Theme.barHeight + Theme.gap + (shown ? 0 : -16)
                width: 440
                height: column.implicitHeight + Theme.spacingL * 2
                opacity: shown ? 1 : 0
                focus: true
                Keys.onEscapePressed: ShellState.close()

                Behavior on opacity { NumberAnimation { duration: Theme.durMedium; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.standard } }
                Behavior on y { NumberAnimation { duration: Theme.durLong; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.emphasized } }
                Behavior on height { NumberAnimation { duration: Theme.durMedium; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.standard } }

                Surface {
                    anchors.fill: parent
                    color: Theme.panel
                    headerHeight: 44
                }

                MouseArea {
                    anchors.fill: parent
                }

                ColumnLayout {
                    id: column
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.margins: Theme.spacingL
                    spacing: Theme.spacingM

                    // Header
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: Theme.spacingS

                        MdIcon {
                            codepoint: 0xF075A // md-music
                            color: Theme.accent
                        }
                        StyledText {
                            Layout.fillWidth: true
                            text: card.p ? (card.p.identity || "Media") : "Nothing playing"
                            font.pixelSize: Theme.fontTitle
                            font.weight: Font.DemiBold
                        }
                    }

                    // Player switcher (only with several players)
                    Flow {
                        Layout.fillWidth: true
                        visible: root.players.length > 1
                        spacing: Theme.spacingXs

                        Repeater {
                            model: root.players

                            delegate: Button {
                                id: chip
                                required property var modelData
                                implicitWidth: chipText.implicitWidth + Theme.spacingM * 2
                                implicitHeight: 26
                                framed: true
                                active: modelData === card.p
                                onClicked: ShellState.chosenPlayer = chip.modelData

                                StyledText {
                                    id: chipText
                                    anchors.centerIn: parent
                                    text: (chip.modelData.isPlaying ? "▶ " : "") + (chip.modelData.identity || "Player")
                                    font.pixelSize: Theme.fontSmall
                                }
                            }
                        }
                    }

                    // Art + metadata
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: Theme.spacingL

                        Item {
                            implicitWidth: 128
                            implicitHeight: 128

                            Surface {
                                anchors.fill: parent
                                radius: Theme.radiusLarge
                                visible: !art.visible

                                MdIcon {
                                    anchors.centerIn: parent
                                    codepoint: 0xF075A
                                    font.pixelSize: 56
                                    color: Theme.accent
                                }
                            }

                            ClippingRectangle {
                                id: art
                                anchors.fill: parent
                                visible: artImage.status === Image.Ready
                                radius: Theme.radiusLarge
                                color: "transparent"
                                border.width: 1
                                border.color: Theme.borderLight

                                Image {
                                    id: artImage
                                    anchors.fill: parent
                                    fillMode: Image.PreserveAspectCrop
                                    asynchronous: true
                                    sourceSize.width: 256
                                    sourceSize.height: 256
                                    source: card.p ? card.p.trackArtUrl : ""
                                }

                                // Glass reflection over the cover
                                Rectangle {
                                    anchors.left: parent.left
                                    anchors.right: parent.right
                                    anchors.top: parent.top
                                    height: parent.height * 0.45
                                    gradient: Gradient {
                                        GradientStop { position: 0.0; color: Qt.rgba(1, 1, 1, 0.22) }
                                        GradientStop { position: 1.0; color: Qt.rgba(1, 1, 1, 0.03) }
                                    }
                                }
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            Layout.alignment: Qt.AlignVCenter
                            spacing: 2

                            StyledText {
                                Layout.fillWidth: true
                                text: card.p ? (card.p.trackTitle || "Unknown title") : ""
                                font.pixelSize: Theme.fontTitle + 2
                                font.weight: Font.Bold
                                wrapMode: Text.WordWrap
                                maximumLineCount: 2
                            }
                            StyledText {
                                Layout.fillWidth: true
                                visible: text !== ""
                                text: card.p ? card.p.trackArtist : ""
                                color: Theme.accent
                            }
                            StyledText {
                                Layout.fillWidth: true
                                visible: text !== ""
                                text: card.p ? card.p.trackAlbum : ""
                                color: Theme.textSurfaceVariant
                                font.pixelSize: Theme.fontSmall + 1
                            }
                        }
                    }

                    // Seek bar
                    ColumnLayout {
                        Layout.fillWidth: true
                        visible: card.p !== null && card.p.lengthSupported && card.p.length > 0
                        spacing: 2

                        Slider {
                            id: seek
                            Layout.fillWidth: true
                            implicitHeight: 12
                            tone: "accent"
                            interactive: card.p !== null && card.p.canSeek
                            value: card.p && card.p.length > 0 ? Math.min(1, card.p.position / card.p.length) : 0
                            onReleased: v => {
                                if (card.p && card.p.canSeek)
                                    card.p.position = v * card.p.length;
                            }
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            StyledText {
                                Layout.fillWidth: true
                                text: root.fmt(card.p ? (seek.pressed ? seek.shown * card.p.length : card.p.position) : 0)
                                font.pixelSize: Theme.fontSmall
                                color: Theme.textSurfaceVariant
                            }
                            StyledText {
                                text: root.fmt(card.p ? card.p.length : 0)
                                font.pixelSize: Theme.fontSmall
                                color: Theme.textSurfaceVariant
                            }
                        }
                    }

                    // Per-player volume (MPRIS)
                    RowLayout {
                        Layout.fillWidth: true
                        visible: root.hasVolume
                        spacing: Theme.spacingS

                        Button {
                            implicitWidth: 28
                            implicitHeight: 28
                            onClicked: root.toggleMute()
                            MdIcon {
                                anchors.centerIn: parent
                                codepoint: root.muted ? 0xF0581 : (root.volume < 0.34 ? 0xF057F : (root.volume < 0.67 ? 0xF0580 : 0xF057E))
                                color: root.muted ? Theme.outline : Theme.textSurface
                            }
                        }

                        Slider {
                            id: volSlider
                            Layout.fillWidth: true
                            value: root.volume
                            onMoved: v => root.setVolume(v)
                        }

                        StyledText {
                            Layout.preferredWidth: 40
                            horizontalAlignment: Text.AlignRight
                            text: root.muted ? "Muted" : Math.round((volSlider.pressed ? volSlider.shown : root.volume) * 100) + "%"
                            font.pixelSize: Theme.fontSmall
                            color: Theme.textSurfaceVariant
                        }
                    }

                    // Transport controls
                    RowLayout {
                        Layout.alignment: Qt.AlignHCenter
                        spacing: Theme.spacingS

                        Button {
                            visible: card.p !== null && card.p.shuffleSupported
                            implicitWidth: 34
                            implicitHeight: 34
                            active: card.p !== null && card.p.shuffle
                            onClicked: card.p.shuffle = !card.p.shuffle
                            MdIcon {
                                anchors.centerIn: parent
                                codepoint: card.p && card.p.shuffle ? 0xF049D : 0xF049E
                                color: card.p && card.p.shuffle ? Theme.accent : Theme.textSurfaceVariant
                            }
                        }

                        Button {
                            implicitWidth: 44
                            implicitHeight: 40
                            framed: true
                            enabled: card.p !== null && card.p.canGoPrevious
                            opacity: enabled ? 1 : 0.4
                            onClicked: card.p.previous()
                            MdIcon { anchors.centerIn: parent; codepoint: 0xF04AE; font.pixelSize: 22 }
                        }

                        Button {
                            implicitWidth: 56
                            implicitHeight: 48
                            framed: true
                            active: true
                            enabled: card.p !== null && card.p.canTogglePlaying
                            opacity: enabled ? 1 : 0.4
                            onClicked: card.p.togglePlaying()
                            MdIcon {
                                anchors.centerIn: parent
                                codepoint: card.p && card.p.isPlaying ? 0xF03E4 : 0xF040A
                                font.pixelSize: 28
                            }
                        }

                        Button {
                            implicitWidth: 44
                            implicitHeight: 40
                            framed: true
                            enabled: card.p !== null && card.p.canGoNext
                            opacity: enabled ? 1 : 0.4
                            onClicked: card.p.next()
                            MdIcon { anchors.centerIn: parent; codepoint: 0xF04AD; font.pixelSize: 22 }
                        }

                        Button {
                            visible: card.p !== null && card.p.loopSupported
                            implicitWidth: 34
                            implicitHeight: 34
                            active: card.p !== null && card.p.loopState !== MprisLoopState.None
                            onClicked: {
                                var s = card.p.loopState;
                                card.p.loopState = s === MprisLoopState.None ? MprisLoopState.Playlist : (s === MprisLoopState.Playlist ? MprisLoopState.Track : MprisLoopState.None);
                            }
                            MdIcon {
                                anchors.centerIn: parent
                                codepoint: !card.p || card.p.loopState === MprisLoopState.None ? 0xF0457 : (card.p.loopState === MprisLoopState.Track ? 0xF0458 : 0xF0456)
                                color: card.p && card.p.loopState !== MprisLoopState.None ? Theme.accent : Theme.textSurfaceVariant
                            }
                        }
                    }
                }
            }
        }
    }
}
