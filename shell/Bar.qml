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

    // -- Derived state ------------------------------------------------------
    property var sink: Pipewire.defaultAudioSink
    readonly property var player: ShellState.player

    // Connected network device (wifi preferred for the signal icon).
    readonly property var netDevice: {
        var devices = Networking.devices.values;
        var fallbackWired = null;
        for (var i = 0; i < devices.length; i++) {
            var device = devices[i];
            if (!device.connected)
                continue;
            if (device.type === DeviceType.Wired && fallbackWired === null)
                fallbackWired = device;
            else if (device.type === DeviceType.Wifi)
                return device;
        }
        return fallbackWired;
    }

    readonly property var wifiNetwork: {
        if (!netDevice || netDevice.type !== DeviceType.Wifi)
            return null;
        var networks = netDevice.networks.values;
        for (var i = 0; i < networks.length; i++) {
            if (networks[i].connected)
                return networks[i];
        }
        return null;
    }

    readonly property int volumeIcon: {
        var isMuted = !sink || !sink.audio || sink.audio.muted;
        var volumeLevel = sink && sink.audio ? sink.audio.volume : 0;
        return ShellState.volumeGlyph(volumeLevel, isMuted);
    }

    readonly property int networkIcon: {
        if (!netDevice)
            return 0xF05AA; // md-wifi_off
        if (netDevice.type === DeviceType.Wired)
            return 0xF0200; // md-ethernet
        var signalStrength = wifiNetwork ? wifiNetwork.signalStrength : 1;
        if (signalStrength < 0.25)
            return 0xF091F;
        if (signalStrength < 0.5)
            return 0xF0922;
        if (signalStrength < 0.75)
            return 0xF0925;
        return 0xF0928;
    }

    // -- Visual tree --------------------------------------------------------
    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: bar

            required property var modelData
            readonly property var monitor: Hyprland.monitorFor(modelData)

            screen: modelData
            color: "transparent"
            implicitHeight: Theme.barSpace + Theme.shadowRoom
            exclusiveZone: Theme.barSpace

            anchors {
                top: true
                left: true
                right: true
            }

            WlrLayershell.namespace: "shell-bar"

            // Taskbar strip (full style). Hidden in pills style, where it still
            // marks the band the bar content is centered in.
            Surface {
                id: strip
                visible: !Theme.barPills
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.topMargin: Theme.barMargin
                height: Theme.barHeight
                radius: Theme.barRadius
                color: Theme.bar

                // Edge line along the bottom of the bar.
                Divider {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    strong: true
                }
            }

            // Pills style: one floating surface behind each group of bar content.
            Repeater {
                model: Theme.barPills ? [leftGroup, mediaButton, rightGroup] : []

                Surface {
                    required property Item modelData
                    visible: modelData.visible && modelData.width > 0
                    x: modelData.x - Theme.spacingS
                    y: Theme.barMargin
                    width: modelData.width + Theme.spacingS * 2
                    height: Theme.barHeight
                    radius: Math.max(Theme.barRadius, Theme.radiusLarge)
                    color: Theme.bar
                }
            }

            // -- Left: workspaces and window icons --------------------------
            RowLayout {
                id: leftGroup
                anchors.left: parent.left
                anchors.leftMargin: Theme.barMargin + Theme.spacingS
                anchors.verticalCenter: strip.verticalCenter
                spacing: Theme.spacingS

                Island {
                    spacing: Theme.spacingXs

                    Repeater {
                        model: Hyprland.workspaces

                        delegate: Button {
                            id: workspaceButton
                            required property var modelData
                            readonly property bool occupied: modelData.toplevels.values.length > 0

                            visible: bar.monitor !== null && modelData.monitor === bar.monitor && modelData.id > 0
                            implicitWidth: modelData.active ? 44 : 32
                            implicitHeight: Theme.px(30)
                            active: modelData.active
                            tint: modelData.urgent ? Theme.error : Theme.highlight
                            onClicked: modelData.activate()

                            Behavior on implicitWidth {
                                NumberAnimation { duration: Theme.durMedium; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.emphasized }
                            }

                            StyledText {
                                anchors.centerIn: parent
                                text: workspaceButton.modelData.name
                                font.weight: workspaceButton.active ? Font.Bold : Font.Normal
                                opacity: workspaceButton.active || workspaceButton.occupied || workspaceButton.hovered ? 1 : Theme.dim(0.5)
                            }

                            // Occupied marker
                            Rectangle {
                                visible: workspaceButton.occupied && !workspaceButton.active
                                anchors.horizontalCenter: parent.horizontalCenter
                                anchors.bottom: parent.bottom
                                anchors.bottomMargin: Theme.spacingXs
                                width: Theme.px(10)
                                height: Theme.px(2)
                                radius: Theme.radiusFull
                                color: Theme.accent
                            }
                        }
                    }
                }

                // Windows on this monitor's active workspace, as icons.
                Divider { implicitHeight: Theme.px(26); visible: windowRepeater.count > 0 }

                Island {
                    visible: windowRepeater.count > 0
                    spacing: Theme.spacingXs

                    Repeater {
                        id: windowRepeater
                        model: ScriptModel {
                            values: {
                                var activeWorkspace = bar.monitor ? bar.monitor.activeWorkspace : null;
                                if (!activeWorkspace)
                                    return [];
                                return Hyprland.toplevels.values.filter(toplevel => toplevel.workspace === activeWorkspace);
                            }
                        }

                        delegate: Button {
                            id: windowButton
                            required property var modelData
                            readonly property string appId: modelData.wayland ? modelData.wayland.appId : ""
                            readonly property var desktopEntry: appId !== "" ? DesktopEntries.heuristicLookup(appId) : null
                            readonly property string iconName: desktopEntry ? desktopEntry.icon : appId

                            implicitWidth: Theme.px(38)
                            implicitHeight: Theme.px(30)
                            active: modelData.activated || Hyprland.activeToplevel === modelData
                            restyleContent: false
                            onClicked: {
                                if (windowButton.modelData.wayland) {
                                    windowButton.modelData.wayland.activate();
                                } else {
                                    var windowAddress = windowButton.modelData.address;
                                    var normalizedAddress = windowAddress.indexOf("0x") === 0 ? windowAddress : "0x" + windowAddress;
                                    Hyprland.dispatch("focuswindow address:" + normalizedAddress);
                                }
                            }

                            IconImage {
                                id: windowIcon
                                anchors.centerIn: parent
                                implicitSize: 20
                                visible: windowButton.iconName !== "" && status === Image.Ready
                                source: windowButton.iconName !== "" ? Quickshell.iconPath(windowButton.iconName, true) : ""
                                asynchronous: true
                            }

                            MdIcon {
                                anchors.centerIn: parent
                                visible: !windowIcon.visible
                                codepoint: 0xF05B6 // md-application
                                color: Theme.textSurfaceVariant
                            }
                        }
                    }
                }
            }

            // -- Center: media ----------------------------------------------
            Button {
                id: mediaButton
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.verticalCenter: strip.verticalCenter
                visible: root.player !== null
                implicitWidth: mediaRow.implicitWidth + Theme.spacingM * 2
                implicitHeight: Theme.px(32)
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
                        implicitWidth: Theme.px(24)
                        implicitHeight: Theme.px(24)

                        Fill {
                            anchors.fill: parent
                            visible: !albumArtClip.visible
                            role: "orb"
                            bordered: true

                            MdIcon {
                                anchors.centerIn: parent
                                codepoint: root.player && root.player.isPlaying ? 0xF03E4 : 0xF040A
                                font.pixelSize: Theme.iconPx(13)
                            }
                        }

                        ClippingRectangle {
                            id: albumArtClip
                            anchors.fill: parent
                            visible: albumArtImage.status === Image.Ready
                            radius: Theme.radiusSmall
                            color: "transparent"
                            border.width: 1
                            border.color: Theme.borderLight

                            Image {
                                id: albumArtImage
                                anchors.fill: parent
                                fillMode: Image.PreserveAspectCrop
                                asynchronous: true
                                sourceSize.width: 64
                                sourceSize.height: 64
                                source: root.player ? root.player.trackArtUrl : ""
                            }
                        }

                        Rectangle {
                            visible: albumArtClip.visible
                            anchors.right: parent.right
                            anchors.bottom: parent.bottom
                            anchors.margins: Theme.px(-3)
                            width: Theme.px(13)
                            height: Theme.px(13)
                            radius: Theme.radiusFull
                            color: Theme.primary
                            border.width: 1
                            border.color: Theme.border

                            MdIcon {
                                anchors.centerIn: parent
                                codepoint: root.player && root.player.isPlaying ? 0xF03E4 : 0xF040A
                                font.pixelSize: Theme.iconPx(8)
                            }
                        }
                    }

                    StyledText {
                        Layout.maximumWidth: Theme.px(260)
                        text: root.player ? (root.player.trackTitle || root.player.identity) : ""
                    }
                }
            }

            // -- Right: notification area -----------------------------------
            RowLayout {
                id: rightGroup
                anchors.right: parent.right
                anchors.rightMargin: Theme.barMargin + Theme.spacingS
                anchors.verticalCenter: strip.verticalCenter
                spacing: Theme.spacingXs

                // System monitor indicator (CPU / RAM)
                Button {
                    implicitWidth: sysRow.implicitWidth + Theme.spacingS * 2
                    implicitHeight: Theme.px(26)
                    active: ShellState.panel === "sysmon"
                    onClicked: ShellState.toggle("sysmon")

                    RowLayout {
                        id: sysRow
                        anchors.centerIn: parent
                        spacing: Theme.spacingXs

                        MdIcon { codepoint: 0xF061A; font.pixelSize: Theme.iconPx(14); color: Theme.accent } // md-chip
                        StyledText { text: Math.round(SysStats.cpu * 100) + "%"; font.pixelSize: Theme.fontSmall }
                        MdIcon { Layout.leftMargin: Theme.spacingXs; codepoint: 0xF035B; font.pixelSize: Theme.iconPx(14); color: Theme.accent } // md-memory
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
                            implicitWidth: Theme.px(26)
                            implicitHeight: Theme.px(26)
                            acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton

                            IconImage {
                                anchors.centerIn: parent
                                implicitSize: 16
                                source: trayIcon.modelData.icon
                            }

                            onClicked: mouse => {
                                var menuPos = trayIcon.mapToItem(bar.contentItem, mouse.x, mouse.y);
                                if (trayIcon.modelData.hasMenu && (mouse.button === Qt.RightButton || trayIcon.modelData.onlyMenu))
                                    trayIcon.modelData.display(bar, menuPos.x, menuPos.y);
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
                        implicitWidth: systemRow.implicitWidth + Theme.spacingS * 2
                        implicitHeight: Theme.px(26)
                        active: ShellState.panel === "quicksettings"
                        onClicked: ShellState.toggle("quicksettings")
                        onWheel: wheel => {
                            if (root.sink && root.sink.audio) {
                                var step = wheel.angleDelta.y > 0 ? 0.05 : -0.05;
                                root.sink.audio.volume = Math.max(0, Math.min(1.5, root.sink.audio.volume + step));
                            }
                        }

                        RowLayout {
                            id: systemRow
                            anchors.centerIn: parent
                            spacing: Theme.spacingXs

                            MdIcon {
                                codepoint: root.networkIcon
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
                                spacing: Theme.px(2)

                                MdIcon {
                                    codepoint: {
                                        if (battery.charging)
                                            return 0xF0084;
                                        var decile = Math.floor(battery.device.percentage / 10);
                                        if (decile >= 10)
                                            return 0xF0079;
                                        if (decile < 1)
                                            return 0xF008E;
                                        return 0xF007A + decile - 1;
                                    }
                                    color: {
                                        if (battery.low)
                                            return Theme.error;
                                        if (battery.charging)
                                            return Theme.success;
                                        return Theme.textSurface;
                                    }
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
                        implicitWidth: Theme.px(26)
                        implicitHeight: Theme.px(26)
                        active: ShellState.panel === "notifications"
                        onClicked: ShellState.toggle("notifications")

                        MdIcon {
                            anchors.centerIn: parent
                            codepoint: Notifs.unread > 0 ? 0xF009E : 0xF009A
                            color: Notifs.unread > 0 ? Theme.accent : Theme.textSurface
                        }

                        Fill {
                            visible: Notifs.unread > 0
                            anchors.right: parent.right
                            anchors.top: parent.top
                            anchors.margins: -Theme.spacingXs / 2
                            width: Math.max(15, badge.implicitWidth + Theme.spacingS - 1)
                            height: Theme.px(15)
                            role: "badge"
                            color: Theme.badge
                            bordered: true
                            scale: visible ? 1 : 0
                            Behavior on scale { NumberAnimation { duration: Theme.durMedium; easing.type: Easing.OutBack } }

                            StyledText {
                                id: badge
                                anchors.centerIn: parent
                                text: Notifs.unread > 9 ? "9+" : Notifs.unread
                                font.pixelSize: Theme.fontPx(9)
                                font.weight: Font.Bold
                            }
                        }
                    }
                }

                // Clock: time over date
                Button {
                    implicitWidth: clockColumn.implicitWidth + Theme.spacingS * 2
                    implicitHeight: Theme.px(34)
                    active: ShellState.panel === "calendar"
                    onClicked: ShellState.toggle("calendar")

                    Column {
                        id: clockColumn
                        anchors.centerIn: parent
                        spacing: Theme.px(-2)

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

            SystemClock {
                id: clock
                precision: SystemClock.Minutes
            }
        }
    }

    // -- Background objects -------------------------------------------------
    PwObjectTracker {
        objects: root.sink ? [root.sink] : []
    }
}
