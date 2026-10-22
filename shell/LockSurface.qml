import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Services.UPower
import Quickshell.Widgets

// Lock screen UI: blurred wallpaper, glowing clock, glass logon card.
Item {
    id: surface

    required property var lock
    property string realName: Quickshell.env("USER") || "user"
    property bool capsLock: false

    SystemClock {
        id: clock
        precision: SystemClock.Seconds
    }

    // Real name from passwd (GECOS field).
    FileView {
        path: "/etc/passwd"
        onLoaded: {
            var user = Quickshell.env("USER");
            var lines = text().split("\n");
            for (var i = 0; i < lines.length; i++) {
                var f = lines[i].split(":");
                if (f[0] === user && f[4]) {
                    surface.realName = f[4].split(",")[0];
                    break;
                }
            }
        }
    }

    // Caps Lock state from Hyprland (no native QML API for it).
    Process {
        id: caps
        command: ["hyprctl", "devices", "-j"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    var kbs = JSON.parse(text).keyboards || [];
                    surface.capsLock = kbs.some(k => k.capsLock);
                } catch (e) {}
            }
        }
    }
    Timer {
        running: surface.visible
        interval: 1000
        repeat: true
        triggeredOnStart: true
        onTriggered: caps.running = true
    }

    // ── Background: blurred, darkened wallpaper ─────────────────────────
    Image {
        id: wall
        anchors.fill: parent
        fillMode: Image.PreserveAspectCrop
        source: Theme.fileUrl(Wallpaper.path)
        asynchronous: true
        visible: false
    }
    MultiEffect {
        anchors.fill: parent
        source: wall
        blurEnabled: true
        blur: 1
        blurMax: 64
        brightness: -0.25
        saturation: -0.1
    }
    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            GradientStop { position: 0.0; color: Qt.rgba(0, 0, 0, 0.35) }
            GradientStop { position: 0.6; color: Qt.rgba(0, 0, 0, 0.55) }
            GradientStop { position: 1.0; color: Qt.rgba(0, 0, 0, 0.8) }
        }
    }

    // ── Clock ────────────────────────────────────────────────────────────
    Column {
        id: clockBlock
        anchors.horizontalCenter: parent.horizontalCenter
        y: parent.height * 0.12
        spacing: 0

        layer.enabled: true
        layer.effect: MultiEffect {
            shadowEnabled: true
            shadowColor: Theme.accent
            shadowOpacity: 0.6
            shadowBlur: 1
            shadowHorizontalOffset: 0
            shadowVerticalOffset: 0
            blurMax: 40
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: Qt.formatDateTime(clock.date, "HH:mm")
            color: "#ffffff"
            font.family: Theme.font
            font.pixelSize: 112
            font.weight: Font.Light
        }
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: Qt.formatDateTime(clock.date, "dddd, d MMMM")
            color: Qt.rgba(1, 1, 1, 0.85)
            font.family: Theme.font
            font.pixelSize: 22
        }
    }

    // ── Logon card ───────────────────────────────────────────────────────
    Item {
        id: card
        anchors.horizontalCenter: parent.horizontalCenter
        y: parent.height * 0.42
        width: 380
        height: cardColumn.implicitHeight + Theme.spacingXl * 2

        transform: Translate { id: shake }

        SequentialAnimation {
            id: shakeAnim
            loops: 1
            NumberAnimation { target: shake; property: "x"; to: -14; duration: 50 }
            NumberAnimation { target: shake; property: "x"; to: 12; duration: 70 }
            NumberAnimation { target: shake; property: "x"; to: -8; duration: 60 }
            NumberAnimation { target: shake; property: "x"; to: 5; duration: 50 }
            NumberAnimation { target: shake; property: "x"; to: 0; duration: 40 }
        }

        Connections {
            target: surface.lock
            function onFailed() {
                password.text = "";
                shakeAnim.restart();
                password.forceActiveFocus();
            }
        }

        Surface {
            anchors.fill: parent
            color: Theme.panel
            headerHeight: 60
        }

        ColumnLayout {
            id: cardColumn
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: Theme.spacingXl
            spacing: Theme.spacingM

            // Avatar in a glossy glass frame
            Item {
                Layout.alignment: Qt.AlignHCenter
                implicitWidth: 112
                implicitHeight: 112

                Surface {
                    anchors.fill: parent
                    radius: 10
                    color: Theme.surfaceContainerHighest
                }

                ClippingRectangle {
                    anchors.fill: parent
                    anchors.margins: 8
                    radius: 5
                    color: Theme.primaryContainer

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
                        font.pixelSize: 56
                    }

                    // Glass reflection
                    Rectangle {
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.top: parent.top
                        height: parent.height * 0.45
                        gradient: Gradient {
                            GradientStop { position: 0.0; color: Qt.rgba(1, 1, 1, 0.28) }
                            GradientStop { position: 1.0; color: Qt.rgba(1, 1, 1, 0.02) }
                        }
                    }
                }
            }

            StyledText {
                Layout.alignment: Qt.AlignHCenter
                text: surface.realName
                font.pixelSize: 22
                font.weight: Font.Medium
            }

            StyledText {
                Layout.alignment: Qt.AlignHCenter
                Layout.topMargin: -Theme.spacingS
                text: "Locked"
                color: Theme.textSurfaceVariant
                font.pixelSize: Theme.fontSmall
            }

            // Password field + glossy arrow button
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
                        passwordCharacter: "●"
                        color: "#ffffff"
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
                            text: surface.lock.busy ? "Checking…" : "Password"
                            color: Theme.textSurfaceVariant
                            font.italic: true
                        }
                    }
                }

                Button {
                    implicitWidth: 34
                    implicitHeight: 34
                    radius: 17
                    framed: true
                    active: password.text !== ""
                    onClicked: surface.lock.tryUnlock(password.text)

                    Rectangle {
                        anchors.fill: parent
                        anchors.margins: 1
                        radius: width / 2
                        z: -1
                        gradient: Gradient {
                            GradientStop { position: 0.0; color: Qt.lighter(Theme.primary, 1.3) }
                            GradientStop { position: 0.5; color: Qt.darker(Theme.primary, 1.6) }
                            GradientStop { position: 1.0; color: Theme.primary }
                        }
                    }

                    MdIcon {
                        anchors.centerIn: parent
                        codepoint: surface.lock.busy ? 0xF0450 : 0xF0054 // md-refresh / md-arrow_right
                        font.pixelSize: 18
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

    // ── Bottom bar: branding, media, battery ─────────────────────────────
    Surface {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        height: 44
        radius: 0
        shadow: false

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: Theme.spacingL
            anchors.rightMargin: Theme.spacingL
            spacing: Theme.spacingM

            MdIcon {
                codepoint: 0xF1105
                color: Theme.accent
                font.pixelSize: 20
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
                implicitHeight: 32
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
                        Layout.maximumWidth: 320
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
}
