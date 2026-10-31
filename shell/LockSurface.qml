import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Services.UPower

// Lock screen UI: backdrop, clock, logon card and a bottom bar.
Item {
    id: surface

    // -- Public API ---------------------------------------------------------
    required property var lock

    // -- Internal state -----------------------------------------------------
    property string realName: Quickshell.env("USER") || "user"
    property bool capsLock: false

    // -- Visual tree --------------------------------------------------------
    // -- Background ---------------------------------------------------------
    Backdrop {
        anchors.fill: parent
        source: Theme.fileUrl(Wallpaper.path)
        role: "lock"
    }

    // -- Clock --------------------------------------------------------------
    Column {
        anchors.horizontalCenter: parent.horizontalCenter
        y: parent.height * 0.12
        spacing: 0

        layer.enabled: layer.effect !== null
        layer.effect: Theme.effect("Glow")

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: Qt.formatDateTime(clock.date, "HH:mm")
            color: Theme.textSurface
            font.family: Theme.font
            font.pixelSize: Theme.fontDisplay
            font.weight: Theme.fontDisplayWeight
        }
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: Qt.formatDateTime(clock.date, "dddd, d MMMM")
            color: Theme.textSoft
            font.family: Theme.font
            font.pixelSize: Theme.fontHeadline
        }
    }

    // -- Logon card ---------------------------------------------------------
    Item {
        id: card
        anchors.horizontalCenter: parent.horizontalCenter
        y: parent.height * 0.42
        width: Theme.widthPx(380)
        height: cardColumn.implicitHeight + Theme.spacingXl * 2

        transform: Translate { id: shake }

        SequentialAnimation {
            id: shakeAnim
            loops: 1
            NumberAnimation { target: shake; property: "x"; to: -14; duration: Theme.dur(50) }
            NumberAnimation { target: shake; property: "x"; to: 12; duration: Theme.dur(70) }
            NumberAnimation { target: shake; property: "x"; to: -8; duration: Theme.dur(60) }
            NumberAnimation { target: shake; property: "x"; to: 5; duration: Theme.dur(50) }
            NumberAnimation { target: shake; property: "x"; to: 0; duration: Theme.dur(40) }
        }

        Surface {
            anchors.fill: parent
            color: Theme.panel
            headerHeight: Theme.px(60)
        }

        ColumnLayout {
            id: cardColumn
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: Theme.spacingXl
            spacing: Theme.spacingM

            // Avatar
            Frame {
                Layout.alignment: Qt.AlignHCenter
                implicitWidth: Theme.avatarSize
                implicitHeight: Theme.avatarSize
                padding: Theme.spacingS
                radius: Theme.radiusFrame
                innerRadius: Theme.radius

                Image {
                    id: face
                    anchors.fill: parent
                    fillMode: Image.PreserveAspectCrop
                    sourceSize.width: 192
                    sourceSize.height: 192
                    source: Theme.fileUrl(Quickshell.env("HOME") + "/.face")
                    asynchronous: true
                    visible: status === Image.Ready
                }

                MdIcon {
                    anchors.centerIn: parent
                    visible: !face.visible
                    codepoint: 0xF0004 // md-account
                    font.pixelSize: Theme.iconPx(56)
                }
            }

            StyledText {
                Layout.alignment: Qt.AlignHCenter
                text: surface.realName
                font.pixelSize: Theme.fontHeadline
                font.weight: Font.Medium
            }

            StyledText {
                Layout.alignment: Qt.AlignHCenter
                Layout.topMargin: -Theme.spacingS
                text: "Locked"
                color: Theme.textSurfaceVariant
                font.pixelSize: Theme.fontSmall
            }

            // Password field + round go button
            RowLayout {
                Layout.fillWidth: true
                Layout.topMargin: Theme.spacingS
                spacing: Theme.spacingS

                Field {
                    Layout.fillWidth: true
                    prominent: true
                    input: password

                    TextInput {
                        id: password
                        anchors.fill: parent
                        anchors.leftMargin: Theme.spacingM
                        anchors.rightMargin: Theme.spacingM
                        verticalAlignment: TextInput.AlignVCenter
                        echoMode: TextInput.Password
                        passwordCharacter: "\u25cf"
                        color: Theme.textSurface
                        font.family: Theme.font
                        font.pixelSize: Theme.fontBody
                        enabled: !surface.lock.busy
                        focus: true
                        clip: true
                        Component.onCompleted: forceActiveFocus()
                        onAccepted: surface.lock.tryUnlock(text)

                        StyledText {
                            anchors.fill: parent
                            visible: password.text === ""
                            text: surface.lock.busy ? "Checking\u2026" : "Password"
                            color: Theme.textSurfaceVariant
                            font.italic: true
                        }
                    }
                }

                Button {
                    implicitWidth: Theme.px(34)
                    implicitHeight: Theme.px(34)
                    radius: Theme.radiusFull
                    framed: true
                    active: password.text !== ""
                    onClicked: surface.lock.tryUnlock(password.text)

                    Fill {
                        anchors.fill: parent
                        anchors.margins: 1
                        z: -1
                    }

                    MdIcon {
                        anchors.centerIn: parent
                        codepoint: surface.lock.busy ? 0xF0450 : 0xF0054 // md-refresh / md-arrow_right
                        font.pixelSize: Theme.iconPx(18)
                        RotationAnimation on rotation {
                            running: surface.lock.busy
                            from: 0
                            to: 360
                            duration: 900
                            loops: Animation.Infinite
                        }
                    }
                }
            }

            StyledText {
                Layout.alignment: Qt.AlignHCenter
                visible: text !== ""
                text: surface.lock.errorText
                color: Theme.error
            }

            StyledText {
                Layout.alignment: Qt.AlignHCenter
                visible: surface.capsLock
                text: "Caps Lock is on"
                color: Theme.warning
                font.pixelSize: Theme.fontSmall
            }
        }
    }

    // -- Bottom bar: branding, media, battery -------------------------------
    Surface {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        height: Theme.px(44)
        radius: Theme.barRadius
        shadow: false

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: Theme.spacingL
            anchors.rightMargin: Theme.spacingL
            spacing: Theme.spacingM

            MdIcon {
                codepoint: 0xF1105
                color: Theme.accent
                font.pixelSize: Theme.iconPx(20)
            }
            StyledText {
                text: "NixOS"
                font.pixelSize: Theme.fontTitle
                font.weight: Font.DemiBold
            }

            Item { Layout.fillWidth: true }

            Button {
                visible: ShellState.player !== null
                implicitWidth: lockMedia.implicitWidth + Theme.spacingM * 2
                implicitHeight: Theme.px(32)
                onClicked: if (ShellState.player && ShellState.player.canTogglePlaying) ShellState.player.togglePlaying()

                RowLayout {
                    id: lockMedia
                    anchors.centerIn: parent
                    spacing: Theme.spacingS
                    MdIcon {
                        codepoint: ShellState.player && ShellState.player.isPlaying ? 0xF03E4 : 0xF040A
                        color: Theme.accent
                    }
                    StyledText {
                        Layout.maximumWidth: Theme.px(320)
                        text: ShellState.player ? (ShellState.player.trackTitle || ShellState.player.identity) : ""
                    }
                }
            }

            Item { Layout.fillWidth: true }

            RowLayout {
                visible: UPower.displayDevice.ready && UPower.displayDevice.isLaptopBattery
                spacing: Theme.spacingXs
                MdIcon {
                    codepoint: UPower.displayDevice.state === UPowerDeviceState.Charging ? 0xF0084 : 0xF0079
                }
                StyledText {
                    text: Math.round(UPower.displayDevice.percentage) + "%"
                }
            }
        }
    }

    // -- Background objects -------------------------------------------------
    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    // Real name from passwd (GECOS field).
    FileView {
        path: "/etc/passwd"
        onLoaded: {
            var user = Quickshell.env("USER");
            var lines = text().split("\n");
            for (var i = 0; i < lines.length; i++) {
                var fields = lines[i].split(":");
                if (fields[0] === user && fields[4]) {
                    surface.realName = fields[4].split(",")[0];
                    break;
                }
            }
        }
    }

    // Caps Lock state from Hyprland (no native QML API for it).
    Process {
        id: capsLockProcess
        command: ["hyprctl", "devices", "-j"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    var keyboards = JSON.parse(text).keyboards || [];
                    surface.capsLock = keyboards.some(keyboard => keyboard.capsLock);
                } catch (e) {}
            }
        }
    }

    Timer {
        running: surface.visible
        interval: 1000
        repeat: true
        triggeredOnStart: true
        onTriggered: capsLockProcess.running = true
    }

    Connections {
        target: surface.lock
        function onFailed() {
            password.text = "";
            shakeAnim.restart();
            password.forceActiveFocus();
        }
    }
}
