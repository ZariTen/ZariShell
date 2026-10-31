import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Mpris
import Quickshell.Wayland
import Quickshell.Widgets

// Dropdown media player under the bar's media button.
Scope {
    id: root

    // -- State and derived properties ---------------------------------------
    readonly property bool open: ShellState.panel === "media"
    readonly property var player: ShellState.player
    readonly property var players: Mpris.players.values

    // Per-player volume via MPRIS (slider hidden when the player lacks it).
    readonly property bool hasVolume: player !== null && player.volumeSupported && player.canControl
    readonly property real volume: hasVolume ? player.volume : 0
    readonly property bool muted: hasVolume && player.volume <= 0
    property real restoreVolume: 0.5

    // -- Helper functions ---------------------------------------------------
    function setVolume(volumeLevel) {
        if (hasVolume)
            player.volume = Math.max(0, Math.min(1, volumeLevel));
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

    function formatDuration(seconds) {
        if (!isFinite(seconds) || seconds < 0)
            seconds = 0;
        var totalSeconds = Math.floor(seconds);
        var hours = Math.floor(totalSeconds / 3600);
        var minutes = Math.floor((totalSeconds % 3600) / 60);
        var remainingSeconds = totalSeconds % 60;
        var paddedMinutes = hours > 0 && minutes < 10 ? "0" + minutes : "" + minutes;
        return (hours > 0 ? hours + ":" : "") + paddedMinutes + ":" + (remainingSeconds < 10 ? "0" : "") + remainingSeconds;
    }

    function nextLoopState(loopState) {
        if (loopState === MprisLoopState.None)
            return MprisLoopState.Playlist;
        if (loopState === MprisLoopState.Playlist)
            return MprisLoopState.Track;
        return MprisLoopState.None;
    }

    function loopStateGlyph(loopState) {
        if (!root.player || loopState === MprisLoopState.None)
            return 0xF0457;
        if (loopState === MprisLoopState.Track)
            return 0xF0458;
        return 0xF0456;
    }

    // -- Visual tree --------------------------------------------------------
    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: window

            required property var modelData
            readonly property bool focusedHere: root.open && ShellState.isFocusedScreen(modelData)

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
                readonly property var activePlayer: root.player

                anchors.horizontalCenter: parent.horizontalCenter
                y: Theme.barSpace + Theme.gap + (shown ? 0 : -16)
                width: Theme.widthPx(440)
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
                    headerHeight: Theme.px(44)
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
                            text: card.activePlayer ? (card.activePlayer.identity || "Media") : "Nothing playing"
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
                                implicitHeight: Theme.px(26)
                                framed: true
                                active: modelData === card.activePlayer
                                onClicked: ShellState.chosenPlayer = chip.modelData

                                StyledText {
                                    id: chipText
                                    anchors.centerIn: parent
                                    text: (chip.modelData.isPlaying ? "\u25b6 " : "") + (chip.modelData.identity || "Player")
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
                            implicitWidth: Theme.px(128)
                            implicitHeight: Theme.px(128)

                            Surface {
                                anchors.fill: parent
                                radius: Theme.radiusLarge
                                visible: !art.visible

                                MdIcon {
                                    anchors.centerIn: parent
                                    codepoint: 0xF075A
                                    font.pixelSize: Theme.iconPx(56)
                                    color: Theme.accent
                                }
                            }

                            Frame {
                                id: art
                                anchors.fill: parent
                                visible: artImage.status === Image.Ready
                                radius: Theme.radiusLarge
                                color: "transparent"
                                bordered: true

                                Image {
                                    id: artImage
                                    anchors.fill: parent
                                    fillMode: Image.PreserveAspectCrop
                                    asynchronous: true
                                    sourceSize.width: 256
                                    sourceSize.height: 256
                                    source: card.activePlayer ? card.activePlayer.trackArtUrl : ""
                                }
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            Layout.alignment: Qt.AlignVCenter
                            spacing: Theme.px(2)

                            StyledText {
                                Layout.fillWidth: true
                                text: card.activePlayer ? (card.activePlayer.trackTitle || "Unknown title") : ""
                                font.pixelSize: Theme.fontTitle + 2
                                font.weight: Font.Bold
                                wrapMode: Text.WordWrap
                                maximumLineCount: 2
                            }
                            StyledText {
                                Layout.fillWidth: true
                                visible: text !== ""
                                text: card.activePlayer ? card.activePlayer.trackArtist : ""
                                color: Theme.accent
                            }
                            StyledText {
                                Layout.fillWidth: true
                                visible: text !== ""
                                text: card.activePlayer ? card.activePlayer.trackAlbum : ""
                                color: Theme.textSurfaceVariant
                                font.pixelSize: Theme.fontSmall + 1
                            }
                        }
                    }

                    // Seek bar
                    ColumnLayout {
                        Layout.fillWidth: true
                        visible: card.activePlayer !== null && card.activePlayer.lengthSupported && card.activePlayer.length > 0
                        spacing: Theme.px(2)

                        Slider {
                            id: seek
                            Layout.fillWidth: true
                            implicitHeight: Theme.px(12)
                            tone: "accent"
                            interactive: card.activePlayer !== null && card.activePlayer.canSeek
                            value: card.activePlayer && card.activePlayer.length > 0 ? Math.min(1, card.activePlayer.position / card.activePlayer.length) : 0
                            onReleased: ratio => {
                                if (card.activePlayer && card.activePlayer.canSeek)
                                    card.activePlayer.position = ratio * card.activePlayer.length;
                            }
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            StyledText {
                                Layout.fillWidth: true
                                text: root.formatDuration(card.activePlayer ? (seek.pressed ? seek.shown * card.activePlayer.length : card.activePlayer.position) : 0)
                                font.pixelSize: Theme.fontSmall
                                color: Theme.textSurfaceVariant
                            }
                            StyledText {
                                text: root.formatDuration(card.activePlayer ? card.activePlayer.length : 0)
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

                        IconButton {
                            codepoint: ShellState.volumeGlyph(root.volume, root.muted)
                            icon.color: root.muted ? Theme.outline : Theme.textSurface
                            onClicked: root.toggleMute()
                        }

                        Slider {
                            id: volSlider
                            Layout.fillWidth: true
                            value: root.volume
                            onMoved: ratio => root.setVolume(ratio)
                        }

                        StyledText {
                            Layout.preferredWidth: Theme.px(40)
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

                        IconButton {
                            visible: card.activePlayer !== null && card.activePlayer.shuffleSupported
                            implicitWidth: Theme.px(34)
                            active: card.activePlayer !== null && card.activePlayer.shuffle
                            codepoint: active ? 0xF049D : 0xF049E
                            icon.color: active ? Theme.accent : Theme.textSurfaceVariant
                            onClicked: card.activePlayer.shuffle = !card.activePlayer.shuffle
                        }

                        IconButton {
                            implicitWidth: Theme.px(44)
                            implicitHeight: Theme.px(40)
                            framed: true
                            enabled: card.activePlayer !== null && card.activePlayer.canGoPrevious
                            opacity: enabled ? 1 : Theme.dim(0.4)
                            codepoint: 0xF04AE
                            icon.font.pixelSize: Theme.iconPx(22)
                            onClicked: card.activePlayer.previous()
                        }

                        IconButton {
                            implicitWidth: Theme.px(56)
                            implicitHeight: Theme.px(48)
                            framed: true
                            active: true
                            enabled: card.activePlayer !== null && card.activePlayer.canTogglePlaying
                            opacity: enabled ? 1 : Theme.dim(0.4)
                            codepoint: card.activePlayer && card.activePlayer.isPlaying ? 0xF03E4 : 0xF040A
                            icon.font.pixelSize: Theme.iconPx(28)
                            onClicked: card.activePlayer.togglePlaying()
                        }

                        IconButton {
                            implicitWidth: Theme.px(44)
                            implicitHeight: Theme.px(40)
                            framed: true
                            enabled: card.activePlayer !== null && card.activePlayer.canGoNext
                            opacity: enabled ? 1 : Theme.dim(0.4)
                            codepoint: 0xF04AD
                            icon.font.pixelSize: Theme.iconPx(22)
                            onClicked: card.activePlayer.next()
                        }

                        IconButton {
                            visible: card.activePlayer !== null && card.activePlayer.loopSupported
                            implicitWidth: Theme.px(34)
                            active: card.activePlayer !== null && card.activePlayer.loopState !== MprisLoopState.None
                            codepoint: root.loopStateGlyph(card.activePlayer ? card.activePlayer.loopState : MprisLoopState.None)
                            icon.color: active ? Theme.accent : Theme.textSurfaceVariant
                            onClicked: card.activePlayer.loopState = root.nextLoopState(card.activePlayer.loopState)
                        }
                    }
                }
            }
        }
    }

    // -- Background objects -------------------------------------------------
    // Mpris position isn't pushed live; poke it while visible and playing.
    Timer {
        running: root.open && root.player !== null && root.player.isPlaying
        interval: 1000
        repeat: true
        triggeredOnStart: true
        onTriggered: root.player.positionChanged()
    }
}
