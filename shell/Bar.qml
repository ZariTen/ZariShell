import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Networking
import Quickshell.Services.Mpris
import Quickshell.Services.Pipewire
import Quickshell.Services.SystemTray
import Quickshell.Services.UPower
import Quickshell.Wayland
import Quickshell.Widgets

Scope {
    id: root

    property var sink: Pipewire.defaultAudioSink

    readonly property var player: ShellState.player

    // Connected network device (wifi preferred for the signal icon).
    readonly property var netDevice: {
        var all = Networking.devices.values;
        var found = null;
        for (var i = 0; i < all.length; i++) {
            if (!all[i].connected)
                continue;
            if (all[i].type === DeviceType.Wired && found === null)
                found = all[i];
            else if (all[i].type === DeviceType.Wifi)
                return all[i];
        }
        return found;
    }

    readonly property var wifiNetwork: {
        if (!netDevice || netDevice.type !== DeviceType.Wifi)
            return null;
        var nets = netDevice.networks.values;
        for (var i = 0; i < nets.length; i++) {
            if (nets[i].connected)
                return nets[i];
        }
        return null;
    }

    readonly property int volumeIcon: {
        if (!sink || !sink.audio || sink.audio.muted || sink.audio.volume <= 0)
            return 0xF0581;
        return sink.audio.volume < 0.34 ? 0xF057F : (sink.audio.volume < 0.67 ? 0xF0580 : 0xF057E);
    }

    PwObjectTracker {
        objects: root.sink ? [root.sink] : []
    }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: bar

            required property var modelData
            readonly property var monitor: Hyprland.monitorFor(modelData)

            screen: modelData
            color: "transparent"
            implicitHeight: Theme.barHeight + 6   // room for the shadow
            exclusiveZone: Theme.barHeight

            anchors {
                top: true
                left: true
                right: true
            }

            WlrLayershell.namespace: "shell-bar"

            SystemClock {
                id: clock
                precision: SystemClock.Minutes
            }

            // Taskbar strip
            Surface {
                id: strip
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                height: Theme.barHeight
                radius: 0
                color: Theme.bar

                // Thin bright line along the bottom edge, like the Win7 taskbar top edge.
                Rectangle {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    height: 1
                    color: Qt.rgba(1, 1, 1, 0.22)
                }
            }

            // ── Left: orb, workspaces, window title ─────────────────────
            RowLayout {
                anchors.left: parent.left
                anchors.leftMargin: Theme.spacingS
                anchors.verticalCenter: strip.verticalCenter
                spacing: Theme.spacingS

                Island {
                    spacing: Theme.spacingXs

                    Repeater {
                        model: Hyprland.workspaces

                        delegate: Button {
                            id: ws
                            required property var modelData
                            readonly property bool occupied: modelData.toplevels.values.length > 0

                            visible: bar.monitor !== null && modelData.monitor === bar.monitor && modelData.id > 0
                            implicitWidth: modelData.active ? 44 : 32
                            implicitHeight: 30
                            active: modelData.active
                            tint: modelData.urgent ? Theme.error : Theme.highlight
                            onClicked: modelData.activate()

                            Behavior on implicitWidth {
                                NumberAnimation { duration: Theme.durMedium; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.emphasized }
                            }

                            StyledText {
                                anchors.centerIn: parent
                                text: ws.modelData.name
                                font.weight: ws.active ? Font.Bold : Font.Normal
                                opacity: ws.active || ws.occupied || ws.hovered ? 1 : 0.5
                            }

                            // Occupied marker
                            Rectangle {
                                visible: ws.occupied && !ws.active
                                anchors.horizontalCenter: parent.horizontalCenter
                                anchors.bottom: parent.bottom
                                anchors.bottomMargin: Theme.spacingXs
                                width: 10
                                height: 2
                                radius: 1
                                color: Theme.accent
                            }
                        }
                    }
                }

                // Windows on this monitor's active workspace, as taskbar icons.
                Rectangle { implicitWidth: 1; implicitHeight: 26; color: Theme.surfaceContainerHighest; visible: winRow.count > 0 }

                Island {
                    visible: winRow.count > 0
                    spacing: Theme.spacingXs

                    Repeater {
                        id: winRow
                        model: ScriptModel {
                            values: {
                                var ws = bar.monitor ? bar.monitor.activeWorkspace : null;
                                if (!ws)
                                    return [];
                                return Hyprland.toplevels.values.filter(t => t.workspace === ws);
                            }
                        }

                        delegate: Button {
                            id: win
                            required property var modelData
                            readonly property string appId: modelData.wayland ? modelData.wayland.appId : ""
                            readonly property var entry: appId !== "" ? DesktopEntries.heuristicLookup(appId) : null
                            readonly property string iconName: entry ? entry.icon : appId

                            implicitWidth: 38
                            implicitHeight: 30
                            active: modelData.activated || Hyprland.activeToplevel === modelData
                            onClicked: {
                                if (win.modelData.wayland) {
                                    win.modelData.wayland.activate();
                                } else {
                                    var addr = win.modelData.address;
                                    Hyprland.dispatch("focuswindow address:" + (addr.indexOf("0x") === 0 ? addr : "0x" + addr));
                                }
                            }

                            IconImage {
                                id: winIcon
                                anchors.centerIn: parent
                                implicitSize: 20
                                visible: win.iconName !== "" && status === Image.Ready
                                source: win.iconName !== "" ? Quickshell.iconPath(win.iconName, true) : ""
                                asynchronous: true
                            }

                            MdIcon {
                                anchors.centerIn: parent
                                visible: !winIcon.visible
                                codepoint: 0xF05B6 // md-application
                                color: Theme.textSurfaceVariant
                            }
                        }
                    }
                }
            }

            // ── Center: media ────────────────────────────────────────────
            Button {
                id: media
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.verticalCenter: strip.verticalCenter
                visible: root.player !== null
                implicitWidth: mediaRow.implicitWidth + Theme.spacingM * 2
                implicitHeight: 32
                framed: true
                active: ShellState.panel === "media"
                acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
                // Left: media panel; middle: play/pause; right: next track.
                onClicked: mouse => {
                    if (mouse.button === Qt.LeftButton)
                        ShellState.toggle("media");
                    else if (!root.player)
                        return;
                    else if (mouse.button === Qt.MiddleButton && root.player.canTogglePlaying)
                        root.player.togglePlaying();
                    else if (mouse.button === Qt.RightButton && root.player.canGoNext)
                        root.player.next();
                }

                RowLayout {
                    id: mediaRow
                    anchors.centerIn: parent
                    spacing: Theme.spacingS

                    // Album art with a play/pause badge; play/pause orb when no art.
                    Item {
                        implicitWidth: 24
                        implicitHeight: 24

                        Rectangle {
                            anchors.fill: parent
                            visible: !art.visible
                            radius: width / 2
                            border.width: 1
                            border.color: Theme.border
                            gradient: Gradient {
                                GradientStop { position: 0.0; color: Qt.lighter(Theme.primary, 1.2) }
                                GradientStop { position: 0.5; color: Qt.darker(Theme.primary, 1.6) }
                                GradientStop { position: 1.0; color: Theme.primary }
                            }

                            MdIcon {
                                anchors.centerIn: parent
                                codepoint: root.player && root.player.isPlaying ? 0xF03E4 : 0xF040A
                                font.pixelSize: 13
                            }
                        }

                        ClippingRectangle {
                            id: art
                            anchors.fill: parent
                            visible: artImage.status === Image.Ready
                            radius: Theme.radiusSmall
                            color: "transparent"
                            border.width: 1
                            border.color: Theme.borderLight

                            Image {
                                id: artImage
                                anchors.fill: parent
                                fillMode: Image.PreserveAspectCrop
                                asynchronous: true
                                sourceSize.width: 64
                                sourceSize.height: 64
                                source: root.player ? root.player.trackArtUrl : ""
                            }
                        }

                        Rectangle {
                            visible: art.visible
                            anchors.right: parent.right
                            anchors.bottom: parent.bottom
                            anchors.margins: -3
                            width: 13
                            height: 13
                            radius: width / 2
                            color: Theme.primary
                            border.width: 1
                            border.color: Theme.border

                            MdIcon {
                                anchors.centerIn: parent
                                codepoint: root.player && root.player.isPlaying ? 0xF03E4 : 0xF040A
                                font.pixelSize: 8
                            }
                        }
                    }

                    StyledText {
                        Layout.maximumWidth: 260
                        text: root.player ? (root.player.trackTitle || root.player.identity) : ""
                    }
                }
            }

            // ── Right: notification area ─────────────────────────────────
            RowLayout {
                anchors.right: parent.right
                anchors.rightMargin: Theme.spacingS
                anchors.verticalCenter: strip.verticalCenter
                spacing: Theme.spacingXs

                // System monitor indicator (CPU / RAM)
                Button {
                    implicitWidth: sysRow.implicitWidth + Theme.spacingS * 2
                    implicitHeight: 26
                    active: ShellState.panel === "sysmon"
                    onClicked: ShellState.toggle("sysmon")

                    RowLayout {
                        id: sysRow
                        anchors.centerIn: parent
                        spacing: Theme.spacingXs

                        MdIcon { codepoint: 0xF061A; font.pixelSize: 14; color: Theme.accent } // md-chip
                        StyledText { text: Math.round(SysStats.cpu * 100) + "%"; font.pixelSize: Theme.fontSmall }
                        MdIcon { Layout.leftMargin: Theme.spacingXs; codepoint: 0xF035B; font.pixelSize: 14; color: Theme.accent } // md-memory
                        StyledText { text: Math.round(SysStats.mem * 100) + "%"; font.pixelSize: Theme.fontSmall }
                    }
                }

                Island {
                    framed: true
                    spacing: Theme.spacingXs

                    Repeater {
                        model: SystemTray.items

                        delegate: Button {
                            id: trayIcon
                            required property var modelData
                            implicitWidth: 26
                            implicitHeight: 26
                            acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton

                            IconImage {
                                anchors.centerIn: parent
                                implicitSize: 16
                                source: trayIcon.modelData.icon
                            }

                            onClicked: mouse => {
                                var at = trayIcon.mapToItem(bar.contentItem, mouse.x, mouse.y);
                                if (trayIcon.modelData.hasMenu && (mouse.button === Qt.RightButton || trayIcon.modelData.onlyMenu))
                                    trayIcon.modelData.display(bar, at.x, at.y);
                                else if (mouse.button === Qt.MiddleButton)
                                    trayIcon.modelData.secondaryActivate();
                                else
                                    trayIcon.modelData.activate();
                            }
                            onWheel: wheel => trayIcon.modelData.scroll(wheel.angleDelta.y, false)
                        }
                    }

                    // System: network, volume and battery in one button.
                    // Opens quick settings; scroll adjusts the volume.
                    Button {
                        id: system
                        implicitWidth: systemRow.implicitWidth + Theme.spacingS * 2
                        implicitHeight: 26
                        active: ShellState.panel === "quicksettings"
                        onClicked: ShellState.toggle("quicksettings")
                        onWheel: wheel => {
                            if (root.sink && root.sink.audio)
                                root.sink.audio.volume = Math.max(0, Math.min(1.5, root.sink.audio.volume + (wheel.angleDelta.y > 0 ? 0.05 : -0.05)));
                        }

                        RowLayout {
                            id: systemRow
                            anchors.centerIn: parent
                            spacing: Theme.spacingXs

                            MdIcon {
                                codepoint: {
                                    if (!root.netDevice)
                                        return 0xF05AA;
                                    if (root.netDevice.type === DeviceType.Wired)
                                        return 0xF0200;
                                    var s = root.wifiNetwork ? root.wifiNetwork.signalStrength : 1;
                                    return s < 0.25 ? 0xF091F : (s < 0.5 ? 0xF0922 : (s < 0.75 ? 0xF0925 : 0xF0928));
                                }
                                color: root.netDevice ? Theme.textSurface : Theme.outline
                            }

                            MdIcon {
                                codepoint: root.volumeIcon
                                color: root.sink && root.sink.audio && root.sink.audio.muted ? Theme.outline : Theme.textSurface
                            }

                            // Battery: icon only, plus the percentage when low or charging.
                            RowLayout {
                                id: battery
                                readonly property var device: UPower.displayDevice
                                readonly property bool charging: device.state === UPowerDeviceState.Charging || device.state === UPowerDeviceState.FullyCharged
                                readonly property bool low: device.percentage <= 15 && device.state === UPowerDeviceState.Discharging
                                visible: device.ready && device.isLaptopBattery
                                spacing: 2

                                MdIcon {
                                    codepoint: {
                                        if (battery.charging)
                                            return 0xF0084;
                                        var level = Math.floor(battery.device.percentage / 10);
                                        return level >= 10 ? 0xF0079 : (level < 1 ? 0xF008E : 0xF007A + level - 1);
                                    }
                                    color: battery.low ? Theme.error : (battery.charging ? Theme.success : Theme.textSurface)
                                }
                                StyledText {
                                    visible: battery.low || battery.device.state === UPowerDeviceState.Charging
                                    text: Math.round(battery.device.percentage) + "%"
                                    font.pixelSize: Theme.fontSmall
                                    color: battery.low ? Theme.error : Theme.textSurface
                                }
                            }
                        }
                    }

                    // Notification center (bell + unread badge)
                    Button {
                        id: bellButton
                        implicitWidth: 26
                        implicitHeight: 26
                        active: ShellState.panel === "notifications"
                        onClicked: ShellState.toggle("notifications")

                        MdIcon {
                            anchors.centerIn: parent
                            codepoint: Notifs.unread > 0 ? 0xF009E : 0xF009A
                            color: Notifs.unread > 0 ? Theme.accent : Theme.textSurface
                        }

                        Rectangle {
                            visible: Notifs.unread > 0
                            anchors.right: parent.right
                            anchors.top: parent.top
                            anchors.margins: -Theme.spacingXs / 2
                            width: Math.max(15, badge.implicitWidth + Theme.spacingS - 1)
                            height: 15
                            radius: height / 2
                            border.width: 1
                            border.color: Theme.border
                            gradient: Gradient {
                                GradientStop { position: 0.0; color: "#ff8a7a" }
                                GradientStop { position: 1.0; color: "#c4271b" }
                            }
                            scale: visible ? 1 : 0
                            Behavior on scale { NumberAnimation { duration: Theme.durMedium; easing.type: Easing.OutBack } }

                            StyledText {
                                id: badge
                                anchors.centerIn: parent
                                text: Notifs.unread > 9 ? "9+" : Notifs.unread
                                font.pixelSize: 9
                                font.weight: Font.Bold
                            }
                        }
                    }
                }

                // Clock: time over date, like the Win7 notification area
                Button {
                    implicitWidth: clockColumn.implicitWidth + Theme.spacingS * 2
                    implicitHeight: 34
                    active: ShellState.panel === "calendar"
                    onClicked: ShellState.toggle("calendar")

                    Column {
                        id: clockColumn
                        anchors.centerIn: parent
                        spacing: -2

                        StyledText {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: Qt.formatDateTime(clock.date, "HH:mm")
                            font.pixelSize: Theme.fontBody
                        }
                        StyledText {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: Qt.formatDateTime(clock.date, "dd/MM/yyyy")
                            font.pixelSize: Theme.fontSmall
                        }
                    }
                }
            }
        }
    }
}
