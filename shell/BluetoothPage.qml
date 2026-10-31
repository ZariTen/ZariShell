import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Bluetooth

// Bluetooth picker for quick settings, on Quickshell.Bluetooth: paired and
// connected devices first, then nearby ones; per-device connect / disconnect /
// pair / forget, battery level, a scan toggle and the adapter power switch.
// Discovery runs only while this page is visible.
QsPage {
    id: page

    // -- Derived properties -------------------------------------------------
    readonly property var adapter: Bluetooth.defaultAdapter
    readonly property bool powered: adapter !== null && adapter.enabled
    readonly property bool powering: adapter !== null && (adapter.state === BluetoothAdapterState.Enabling || adapter.state === BluetoothAdapterState.Disabling)
    readonly property bool discovering: adapter !== null && adapter.discovering
    readonly property var devices: {
        if (!adapter)
            return [];
        // Unnamed nearby devices only show their address; hide that noise.
        var macAddressPattern = /^([0-9a-f]{2}[:-]){5}[0-9a-f]{2}$/i;
        var visibleDevices = adapter.devices.values.filter(device =>
            device.paired || device.connected || (device.name !== "" && !macAddressPattern.test(device.name))
        );
        return visibleDevices.sort((firstDevice, secondDevice) =>
            page.deviceRank(secondDevice) - page.deviceRank(firstDevice) || firstDevice.name.localeCompare(secondDevice.name)
        );
    }

    codepoint: 0xF00AF // md-bluetooth
    title: "Bluetooth"

    onShownChanged: {
        if (shown) {
            if (powered)
                adapter.discovering = true;
            list.forceActiveFocus();
        } else if (adapter && adapter.discovering) {
            adapter.discovering = false;
        }
    }

    // -- Helper functions ---------------------------------------------------
    function deviceRank(device) {
        if (device.connected)
            return 2;
        if (device.paired)
            return 1;
        return 0;
    }

    function deviceGroup(device) {
        return device.paired || device.connected ? 0 : 1;
    }

    // BlueZ icon name -> Material glyph.
    function deviceGlyph(iconName) {
        if (iconName.indexOf("headset") !== -1)
            return 0xF02CE;   // md-headset
        if (iconName.indexOf("headphones") !== -1)
            return 0xF02CB;   // md-headphones
        if (iconName.indexOf("audio") !== -1)
            return 0xF04C3;   // md-speaker
        if (iconName.indexOf("keyboard") !== -1)
            return 0xF030C;   // md-keyboard
        if (iconName.indexOf("mouse") !== -1)
            return 0xF037D;   // md-mouse
        if (iconName.indexOf("gaming") !== -1)
            return 0xF0297;   // md-gamepad_variant
        if (iconName.indexOf("phone") !== -1)
            return 0xF011C;   // md-cellphone
        if (iconName.indexOf("computer") !== -1)
            return 0xF0322;   // md-laptop
        if (iconName.indexOf("camera") !== -1)
            return 0xF0100;   // md-camera
        if (iconName.indexOf("printer") !== -1)
            return 0xF042A;   // md-printer
        if (iconName.indexOf("display") !== -1 || iconName.indexOf("video") !== -1)
            return 0xF0379;   // md-monitor
        return 0xF00AF;
    }

    // Battery as 0..1 (BlueZ reports a fraction; tolerate a percentage).
    function batteryLevel(device) {
        return Math.max(0, Math.min(1, device.battery > 1 ? device.battery / 100 : device.battery));
    }

    // -- Header actions and visual tree -------------------------------------
    trailing: [
        Button {
            implicitWidth: Theme.px(28)
            implicitHeight: Theme.px(28)
            enabled: page.powered
            opacity: enabled ? 1 : Theme.dim(0.5)
            active: page.discovering
            onClicked: page.adapter.discovering = !page.adapter.discovering

            MdIcon {
                anchors.centerIn: parent
                id: radar
                property real pulse: 1
                codepoint: 0xF0437 // md-radar
                opacity: pulse
                SequentialAnimation {
                    running: page.discovering && !Theme.reduceMotion
                    loops: Animation.Infinite
                    onRunningChanged: if (!running) radar.pulse = 1
                    NumberAnimation { target: radar; property: "pulse"; to: 0.35; duration: Theme.dur(700); easing.type: Easing.InOutSine }
                    NumberAnimation { target: radar; property: "pulse"; to: 1; duration: Theme.dur(700); easing.type: Easing.InOutSine }
                }
            }
        },
        Switch {
            checked: page.powered
            enabled: page.adapter !== null && !page.powering
            onToggled: page.adapter.enabled = !page.adapter.enabled
        }
    ]

    QsEmpty {
        visible: page.adapter === null
        codepoint: 0xF00B2 // md-bluetooth_off
        title: "No Bluetooth adapter found"
        detail: "Is the bluetooth service running?"
    }

    QsEmpty {
        visible: page.adapter !== null && !page.powered
        busy: page.powering
        codepoint: 0xF00B2
        title: page.powering ? "Switching Bluetooth\u2026" : "Bluetooth is turned off"
        actionText: page.powering ? "" : "Turn on"
        onAction: page.adapter.enabled = true
    }

    QsEmpty {
        visible: page.powered && page.devices.length === 0
        busy: page.discovering
        codepoint: 0xF00AF
        title: page.discovering ? "Searching for devices\u2026" : "No devices found"
        detail: page.discovering ? "Put the device in pairing mode." : ""
        actionText: page.discovering ? "" : "Scan"
        onAction: page.adapter.discovering = true
    }

    QsList {
        id: list

        Layout.preferredHeight: Math.min(contentHeight, 320)
        visible: page.powered && count > 0
        model: ScriptModel {
            values: page.devices
            objectProp: "address"
        }

        onVisibleChanged: if (visible && page.shown) forceActiveFocus()
        onActivated: row => row.primary()


        delegate: ColumnLayout {
            id: entry

            required property var modelData
            required property int index
            readonly property var device: modelData
            readonly property bool busy: device.pairing || device.state === BluetoothDeviceState.Connecting || device.state === BluetoothDeviceState.Disconnecting
            readonly property bool firstOfGroup: index === 0 || page.deviceGroup(page.devices[index - 1]) !== page.deviceGroup(device)
            property bool connectAfterPair: false

            function primary() {
                if (device.pairing)
                    device.cancelPair();
                else if (busy)
                    return;
                else if (device.connected)
                    device.disconnect();
                else if (device.paired)
                    device.connect();
                else {
                    connectAfterPair = true;
                    device.pair();
                }
            }

            width: ListView.view.width
            spacing: 0

            Connections {
                target: entry.device
                function onPairedChanged() {
                    if (entry.connectAfterPair && entry.device.paired) {
                        entry.connectAfterPair = false;
                        entry.device.connect();
                    }
                }
            }

            StyledText {
                Layout.fillWidth: true
                Layout.topMargin: entry.index === 0 ? 0 : Theme.spacingS
                Layout.bottomMargin: Theme.px(2)
                Layout.leftMargin: Theme.spacingS
                visible: entry.firstOfGroup
                text: page.deviceGroup(entry.device) === 0 ? "My devices" : "Nearby devices"
                font.pixelSize: Theme.fontSmall
                font.weight: Font.DemiBold
                color: Theme.accent
            }

            QsRow {
                Layout.fillWidth: true
                codepoint: page.deviceGlyph(entry.device.icon)
                iconColor: entry.device.connected ? Theme.accent : Theme.textSurface
                title: entry.device.name !== "" ? entry.device.name : entry.device.address
                busy: entry.busy
                highlighted: entry.device.connected
                current: list.keyActive && list.activeFocus && list.cursor === entry.index
                subtitle: {
                    if (entry.device.pairing)
                        return "Pairing\u2026";
                    if (entry.device.state === BluetoothDeviceState.Connecting)
                        return "Connecting\u2026";
                    if (entry.device.state === BluetoothDeviceState.Disconnecting)
                        return "Disconnecting\u2026";
                    if (entry.device.connected)
                        return "Connected";
                    if (entry.device.paired)
                        return "Paired";
                    return "Click to pair";
                }
                onClicked: {
                    list.cursor = entry.index;
                    entry.primary();
                }
                onHoveredChanged: if (hovered) {
                    list.keyActive = false;
                    list.cursor = entry.index;
                }

                RowLayout {
                    visible: entry.device.batteryAvailable
                    spacing: Theme.px(2)

                    MdIcon {
                        codepoint: ShellState.batteryGlyph(page.batteryLevel(entry.device))
                        font.pixelSize: Theme.iconPx(14)
                        color: page.batteryLevel(entry.device) <= 0.15 ? Theme.error : Theme.textSurfaceVariant
                    }
                    StyledText {
                        text: Math.round(page.batteryLevel(entry.device) * 100) + "%"
                        font.pixelSize: Theme.fontSmall
                        color: Theme.textSurfaceVariant
                    }
                }
                IconButton {
                    visible: entry.device.paired && !entry.device.connected && !entry.busy
                    implicitWidth: Theme.px(26)
                    codepoint: 0xF09E7 // md-delete_outline
                    icon.font.pixelSize: Theme.iconPx(15)
                    icon.color: Theme.textSurfaceVariant
                    onClicked: entry.device.forget()
                }
                ActionButton {
                    visible: !entry.busy || entry.device.pairing
                    implicitHeight: Theme.px(26)
                    text: {
                        if (entry.device.pairing)
                            return "Cancel";
                        if (entry.device.connected)
                            return "Disconnect";
                        if (entry.device.paired)
                            return "Connect";
                        return "Pair";
                    }
                    filled: !entry.device.connected && !entry.device.pairing
                    onClicked: entry.primary()
                }
            }
        }
    }

    // -- Background objects -------------------------------------------------
    Connections {
        target: page.adapter
        function onEnabledChanged() {
            if (page.shown && page.adapter.enabled)
                page.adapter.discovering = true;
        }
    }
}
