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

    readonly property var adapter: Bluetooth.defaultAdapter
    readonly property bool powered: adapter !== null && adapter.enabled
    readonly property bool powering: adapter !== null && (adapter.state === BluetoothAdapterState.Enabling || adapter.state === BluetoothAdapterState.Disabling)
    readonly property bool discovering: adapter !== null && adapter.discovering
    readonly property var devices: {
        if (!adapter)
            return [];
        // Unnamed nearby devices only show their address; hide that noise.
        var addr = /^([0-9a-f]{2}[:-]){5}[0-9a-f]{2}$/i;
        var all = adapter.devices.values.filter(d => d.paired || d.connected || (d.name !== "" && !addr.test(d.name)));
        return all.sort((a, b) => page.rank(b) - page.rank(a) || a.name.localeCompare(b.name));
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

    Connections {
        target: page.adapter
        function onEnabledChanged() {
            if (page.shown && page.adapter.enabled)
                page.adapter.discovering = true;
        }
    }

    function rank(d) {
        return d.connected ? 2 : (d.paired ? 1 : 0);
    }

    function group(d) {
        return d.paired || d.connected ? 0 : 1;
    }

    // BlueZ icon name -> Material glyph.
    function glyph(icon) {
        if (icon.indexOf("headset") !== -1)
            return 0xF02CE;   // md-headset
        if (icon.indexOf("headphones") !== -1)
            return 0xF02CB;   // md-headphones
        if (icon.indexOf("audio") !== -1)
            return 0xF04C3;   // md-speaker
        if (icon.indexOf("keyboard") !== -1)
            return 0xF030C;   // md-keyboard
        if (icon.indexOf("mouse") !== -1)
            return 0xF037D;   // md-mouse
        if (icon.indexOf("gaming") !== -1)
            return 0xF0297;   // md-gamepad_variant
        if (icon.indexOf("phone") !== -1)
            return 0xF011C;   // md-cellphone
        if (icon.indexOf("computer") !== -1)
            return 0xF0322;   // md-laptop
        if (icon.indexOf("camera") !== -1)
            return 0xF0100;   // md-camera
        if (icon.indexOf("printer") !== -1)
            return 0xF042A;   // md-printer
        if (icon.indexOf("display") !== -1 || icon.indexOf("video") !== -1)
            return 0xF0379;   // md-monitor
        return 0xF00AF;
    }

    // Battery as 0..1 (BlueZ reports a fraction; tolerate a percentage).
    function level(d) {
        return Math.max(0, Math.min(1, d.battery > 1 ? d.battery / 100 : d.battery));
    }

    function batteryGlyph(d) {
        var l = Math.floor(level(d) * 10);
        return l >= 10 ? 0xF0079 : (l < 1 ? 0xF008E : 0xF007A + l - 1);
    }

    trailing: [
        AeroButton {
            implicitWidth: 28
            implicitHeight: 28
            enabled: page.powered
            opacity: enabled ? 1 : 0.5
            active: page.discovering
            onClicked: page.adapter.discovering = !page.adapter.discovering

            MdIcon {
                anchors.centerIn: parent
                id: radar
                property real pulse: 1
                codepoint: 0xF0437 // md-radar
                opacity: pulse
                SequentialAnimation {
                    running: page.discovering
                    loops: Animation.Infinite
                    onRunningChanged: if (!running) radar.pulse = 1
                    NumberAnimation { target: radar; property: "pulse"; to: 0.35; duration: 700; easing.type: Easing.InOutSine }
                    NumberAnimation { target: radar; property: "pulse"; to: 1; duration: 700; easing.type: Easing.InOutSine }
                }
            }
        },
        AeroSwitch {
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
        title: page.powering ? "Switching Bluetooth…" : "Bluetooth is turned off"
        actionText: page.powering ? "" : "Turn on"
        onAction: page.adapter.enabled = true
    }

    QsEmpty {
        visible: page.powered && page.devices.length === 0
        busy: page.discovering
        codepoint: 0xF00AF
        title: page.discovering ? "Searching for devices…" : "No devices found"
        detail: page.discovering ? "Put the device in pairing mode." : ""
        actionText: page.discovering ? "" : "Scan"
        onAction: page.adapter.discovering = true
    }

    ListView {
        id: list

        property bool keyActive: false
        property int cursor: -1   // row under the mouse or keyboard

        Layout.fillWidth: true
        Layout.preferredHeight: Math.min(contentHeight, 320)
        visible: page.powered && count > 0
        clip: true
        spacing: 2
        boundsBehavior: Flickable.StopAtBounds
        model: ScriptModel {
            values: page.devices
            objectProp: "address"
        }

        function step(by) {
            keyActive = true;
            cursor = Math.max(0, Math.min(count - 1, cursor + by));
            positionViewAtIndex(cursor, ListView.Contain);
        }

        onVisibleChanged: if (visible && page.shown) forceActiveFocus()
        Keys.onUpPressed: step(-1)
        Keys.onDownPressed: step(1)
        Keys.onReturnPressed: if (itemAtIndex(cursor)) itemAtIndex(cursor).primary()
        Keys.onEnterPressed: if (itemAtIndex(cursor)) itemAtIndex(cursor).primary()

        add: Transition {
            NumberAnimation { property: "opacity"; from: 0; to: 1; duration: Theme.durMedium }
        }
        remove: Transition {
            NumberAnimation { property: "opacity"; to: 0; duration: Theme.durShort }
        }
        displaced: Transition {
            NumberAnimation { property: "y"; duration: Theme.durMedium; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.emphasized }
        }

        delegate: ColumnLayout {
            id: entry

            required property var modelData
            required property int index
            readonly property var dev: modelData
            readonly property bool busy: dev.pairing || dev.state === BluetoothDeviceState.Connecting || dev.state === BluetoothDeviceState.Disconnecting
            readonly property bool firstOfGroup: index === 0 || page.group(page.devices[index - 1]) !== page.group(dev)
            property bool connectAfterPair: false

            function primary() {
                if (dev.pairing)
                    dev.cancelPair();
                else if (busy)
                    return;
                else if (dev.connected)
                    dev.disconnect();
                else if (dev.paired)
                    dev.connect();
                else {
                    connectAfterPair = true;
                    dev.pair();
                }
            }

            width: ListView.view.width
            spacing: 0

            Connections {
                target: entry.dev
                function onPairedChanged() {
                    if (entry.connectAfterPair && entry.dev.paired) {
                        entry.connectAfterPair = false;
                        entry.dev.connect();
                    }
                }
            }

            StyledText {
                Layout.fillWidth: true
                Layout.topMargin: entry.index === 0 ? 0 : Theme.spacingS
                Layout.bottomMargin: 2
                Layout.leftMargin: Theme.spacingS
                visible: entry.firstOfGroup
                text: page.group(entry.dev) === 0 ? "My devices" : "Nearby devices"
                font.pixelSize: Theme.fontSmall
                font.weight: Font.DemiBold
                color: Theme.glow
            }

            QsRow {
                Layout.fillWidth: true
                codepoint: page.glyph(entry.dev.icon)
                iconColor: entry.dev.connected ? Theme.glow : Theme.textSurface
                title: entry.dev.name !== "" ? entry.dev.name : entry.dev.address
                busy: entry.busy
                highlighted: entry.dev.connected
                current: list.keyActive && list.activeFocus && list.cursor === entry.index
                subtitle: {
                    if (entry.dev.pairing)
                        return "Pairing…";
                    if (entry.dev.state === BluetoothDeviceState.Connecting)
                        return "Connecting…";
                    if (entry.dev.state === BluetoothDeviceState.Disconnecting)
                        return "Disconnecting…";
                    return entry.dev.connected ? "Connected" : (entry.dev.paired ? "Paired" : "Click to pair");
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
                    visible: entry.dev.batteryAvailable
                    spacing: 2

                    MdIcon {
                        codepoint: page.batteryGlyph(entry.dev)
                        font.pixelSize: 14
                        color: page.level(entry.dev) <= 0.15 ? Theme.error : Theme.textSurfaceVariant
                    }
                    StyledText {
                        text: Math.round(page.level(entry.dev) * 100) + "%"
                        font.pixelSize: Theme.fontSmall
                        color: Theme.textSurfaceVariant
                    }
                }
                AeroButton {
                    visible: entry.dev.paired && !entry.dev.connected && !entry.busy
                    implicitWidth: 26
                    implicitHeight: 26
                    onClicked: entry.dev.forget()
                    MdIcon {
                        anchors.centerIn: parent
                        codepoint: 0xF09E7 // md-delete_outline
                        font.pixelSize: 15
                        color: Theme.textSurfaceVariant
                    }
                }
                ActionButton {
                    visible: !entry.busy || entry.dev.pairing
                    implicitHeight: 26
                    text: entry.dev.pairing ? "Cancel" : (entry.dev.connected ? "Disconnect" : (entry.dev.paired ? "Connect" : "Pair"))
                    filled: !entry.dev.connected && !entry.dev.pairing
                    onClicked: entry.primary()
                }
            }
        }
    }
}
