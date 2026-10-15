import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

// Wi-Fi picker for quick settings, driven by nmcli: lists nearby networks,
// connects (saved profiles directly, new secured ones with an inline password
// field), disconnects, rescans and toggles the radio. Every nmcli call gets
// its arguments as list entries (no shell), and LC_ALL=C so output parsing
// doesn't depend on the user's locale.
QsPage {
    id: page

    // Status; also feeds the Wi-Fi tile.
    property bool radioOn: false
    property bool radioKnown: false
    property string device: ""         // wifi interface, "" when there is none
    property string wired: ""          // connected ethernet profile, if any
    property string activeSsid: ""
    property int activeSignal: 0
    property var networks: []
    property var held: null            // list received while typing a password
    property var saved: []             // saved Wi-Fi profile names
    property bool scanning: false
    property string connecting: ""     // SSID being connected
    property string askSsid: ""        // SSID whose password field is open
    property string error: ""
    property bool wantRescan: false
    readonly property bool hasDevice: device !== ""
    readonly property var sorted: {
        var list = networks.slice();
        list.sort((a, b) => {
            if (a.inUse !== b.inUse)
                return a.inUse ? -1 : 1;
            var ka = saved.indexOf(a.ssid) !== -1;
            var kb = saved.indexOf(b.ssid) !== -1;
            if (ka !== kb)
                return ka ? -1 : 1;
            return b.signal - a.signal || a.ssid.localeCompare(b.ssid);
        });
        return list;
    }
    signal networkChanged

    codepoint: 0xF05A9 // md-wifi
    title: "Wi-Fi"

    onShownChanged: {
        askSsid = "";
        error = "";
        if (shown) {
            refresh(true);
            list.forceActiveFocus();
        }
    }
    onAskSsidChanged: if (askSsid === "" && held !== null) {
        networks = held;
        held = null;
    }

    // nmcli -t escapes ':' and '\' with a backslash.
    function splitTerse(line) {
        var out = [];
        var cur = "";
        for (var i = 0; i < line.length; i++) {
            var c = line.charAt(i);
            if (c === "\\" && i + 1 < line.length)
                cur += line.charAt(++i);
            else if (c === ":") {
                out.push(cur);
                cur = "";
            } else
                cur += c;
        }
        out.push(cur);
        return out;
    }

    function signalIcon(s) {
        return s < 25 ? 0xF091F : (s < 50 ? 0xF0922 : (s < 75 ? 0xF0925 : 0xF0928));
    }

    function isSaved(ssid) {
        return saved.indexOf(ssid) !== -1;
    }

    // Radio state, device, saved profiles and the cached scan; optionally
    // followed by a fresh scan.
    function refresh(rescan) {
        wantRescan = rescan;
        radioQuery.running = true;
    }

    function scan(mode) {
        if (listQuery.running || !radioOn)
            return;
        scanning = mode !== "no";
        listQuery.mode = mode;
        listQuery.running = true;
    }

    function parseList(text) {
        if (text.trim() === "" && listQuery.mode !== "no")
            return;
        var best = {};
        var active = "";
        text.split("\n").forEach(l => {
            if (l === "")
                return;
            var f = page.splitTerse(l);
            var ssid = f[1] || "";
            if (ssid === "")
                return;
            var sec = f[3] || "";
            var net = {
                ssid: ssid,
                signal: parseInt(f[2]) || 0,
                security: sec,
                secured: sec !== "" && sec !== "--",
                enterprise: sec.indexOf("802.1X") !== -1,
                inUse: f[0] === "*"
            };
            if (net.inUse)
                active = ssid;
            var prev = best[ssid];
            if (prev) {
                var inUse = prev.inUse || net.inUse;
                net = net.signal >= prev.signal ? net : prev;
                net.inUse = inUse;
            }
            best[ssid] = net;
        });
        var result = Object.keys(best).map(k => best[k]);
        activeSsid = active;
        activeSignal = best[active] ? best[active].signal : 0;
        // Don't rebuild rows under a half-typed password.
        if (askSsid !== "")
            held = result;
        else
            networks = result;
    }

    function setRadio() {
        if (radioToggle.running)
            return;
        var next = !radioOn;
        radioToggle.command = ["nmcli", "radio", "wifi", next ? "on" : "off"];
        radioOn = next;
        radioKnown = true;
        if (!next) {
            networks = [];
            activeSsid = "";
            askSsid = "";
            connecting = "";
        }
        error = "";
        radioToggle.running = true;
    }

    function connectTo(net, password) {
        if (connectProc.running || connecting !== "")
            return;
        if (net.ssid.charAt(0) === "-") {
            error = "Can't connect to a network whose name starts with \"-\".";
            return;
        }
        var cmd = ["nmcli", "dev", "wifi", "connect", net.ssid];
        if (password !== "")
            cmd.push("password", password);
        error = "";
        connectProc.errText = "";
        connectProc.net = net;
        connectProc.usedPassword = password !== "";
        connectProc.wasSaved = isSaved(net.ssid);
        connecting = net.ssid;
        askSsid = "";
        connectProc.command = cmd;
        connectProc.running = true;
        connectGuard.restart();
    }

    function activate(net) {
        if (connecting !== "" || net.inUse)
            return;
        if (askSsid === net.ssid) {
            askSsid = "";
        } else if (!net.secured || isSaved(net.ssid)) {
            connectTo(net, "");
        } else if (net.enterprise) {
            error = "Enterprise (802.1X) networks need a saved profile (nm-connection-editor).";
        } else {
            error = "";
            askSsid = net.ssid;
        }
    }

    function disconnect() {
        if (device === "" || discProc.running)
            return;
        discProc.command = ["nmcli", "dev", "disconnect", device];
        discProc.running = true;
    }

    function finishConnect() {
        connectGuard.stop();
        var net = connectProc.net;
        var text = connectProc.errText;
        connecting = "";
        if (connectProc.code === 0) {
            error = "";
            refresh(false);
            networkChanged();
            return;
        }
        var line = text.split("\n").filter(l => l.trim() !== "")[0] || "Couldn't connect.";
        line = line.replace(/^Error:\s*/, "").replace(/^Connection activation failed:\s*(\(\d+\)\s*)?/, "");
        if (/secrets were required|no secrets|password/i.test(line) && net && net.secured && !net.enterprise) {
            error = connectProc.usedPassword ? "Wrong password, try again." : "A password is required.";
            askSsid = net.ssid;
        } else {
            error = line;
        }
        // A failed attempt with a new password leaves a broken profile behind; drop it.
        if (connectProc.usedPassword && !connectProc.wasSaved && net) {
            delProc.command = ["nmcli", "connection", "delete", "id", net.ssid];
            delProc.running = true;
        } else {
            refresh(false);
        }
    }

    Timer {
        // Re-scan while the page is open.
        interval: 15000
        running: page.shown && page.radioOn
        repeat: true
        onTriggered: page.scan("auto")
    }

    Timer {
        id: afterEnable
        interval: 1800
        onTriggered: page.refresh(true)
    }

    Timer {
        // Never leave the row spinning if nmcli hangs.
        id: connectGuard
        interval: 60000
        onTriggered: page.connecting = ""
    }

    Timer {
        // stderr is read on its own stream; give it a moment after exit.
        id: finishTimer
        interval: 250
        onTriggered: page.finishConnect()
    }

    // "enabled" / "disabled"
    Process {
        id: radioQuery
        command: ["nmcli", "-t", "-f", "WIFI", "g"]
        environment: ({ LC_ALL: "C" })
        stdout: StdioCollector {
            onStreamFinished: {
                page.radioOn = text.trim() === "enabled";
                page.radioKnown = true;
                if (!page.radioOn) {
                    page.networks = [];
                    page.activeSsid = "";
                }
                devQuery.running = true;
                savedQuery.running = true;
                if (page.radioOn) {
                    page.scan("no");
                }
            }
        }
    }

    // DEVICE:TYPE:STATE:CONNECTION per interface
    Process {
        id: devQuery
        command: ["nmcli", "-t", "-f", "DEVICE,TYPE,STATE,CONNECTION", "dev"]
        environment: ({ LC_ALL: "C" })
        stdout: StdioCollector {
            onStreamFinished: {
                var dev = "";
                var wired = "";
                text.split("\n").forEach(l => {
                    var f = page.splitTerse(l);
                    if (f[1] === "wifi" && dev === "")
                        dev = f[0];
                    else if (f[1] === "ethernet" && f[2] === "connected" && wired === "")
                        wired = f[3] || f[0];
                });
                page.device = dev;
                page.wired = wired;
            }
        }
    }

    // NAME:TYPE per saved profile
    Process {
        id: savedQuery
        command: ["nmcli", "-t", "-f", "NAME,TYPE", "connection", "show"]
        environment: ({ LC_ALL: "C" })
        stdout: StdioCollector {
            onStreamFinished: {
                var names = [];
                text.split("\n").forEach(l => {
                    var f = page.splitTerse(l);
                    if (f.length >= 2 && (f[f.length - 1] === "802-11-wireless" || f[f.length - 1] === "wifi"))
                        names.push(f.slice(0, f.length - 1).join(":"));
                });
                page.saved = names;
            }
        }
    }

    // IN-USE:SSID:SIGNAL:SECURITY per access point
    Process {
        id: listQuery

        property string mode: "no"

        command: ["nmcli", "-t", "-f", "IN-USE,SSID,SIGNAL,SECURITY", "dev", "wifi", "list", "--rescan", mode]
        environment: ({ LC_ALL: "C" })
        stdout: StdioCollector {
            onStreamFinished: page.parseList(text)
        }
        onExited: (exitCode, exitStatus) => {
            page.scanning = false;
            if (exitCode !== 0 && mode !== "no")
                Qt.callLater(page.scan, "no");   // forced rescan refused: show the cached list instead
            else if (mode === "no" && page.wantRescan) {
                page.wantRescan = false;
                Qt.callLater(page.scan, "auto");
            }
        }
    }

    Process {
        id: radioToggle
        environment: ({ LC_ALL: "C" })
        onExited: {
            page.networkChanged();
            if (page.radioOn)
                afterEnable.restart();
            else
                page.refresh(false);
        }
    }

    Process {
        id: connectProc

        property var net: null
        property bool usedPassword: false
        property bool wasSaved: false
        property int code: 0
        property string errText: ""

        environment: ({ LC_ALL: "C" })
        stderr: StdioCollector {
            onStreamFinished: connectProc.errText = text
        }
        onExited: (exitCode, exitStatus) => {
            connectProc.code = exitCode;
            finishTimer.restart();
        }
    }

    Process {
        id: delProc
        environment: ({ LC_ALL: "C" })
        onExited: page.refresh(false)
    }

    Process {
        id: discProc
        environment: ({ LC_ALL: "C" })
        onExited: {
            page.refresh(false);
            page.networkChanged();
        }
    }

    trailing: [
        AeroButton {
            implicitWidth: 30
            implicitHeight: 28
            enabled: page.radioOn && !page.scanning
            opacity: enabled ? 1 : 0.5
            onClicked: page.scan("yes")

            Spinner {
                anchors.centerIn: parent
                running: page.scanning
                codepoint: 0xF0450 // md-refresh
            }
            MdIcon {
                anchors.centerIn: parent
                visible: !page.scanning
                codepoint: 0xF0450 // md-refresh
            }
        },
        AeroSwitch {
            checked: page.radioOn
            enabled: page.radioKnown && !radioToggle.running
            onToggled: page.setRadio()
        }
    ]

    // Error banner; click to dismiss.
    Rectangle {
        id: banner
        Layout.fillWidth: true
        visible: page.error !== ""
        implicitHeight: bannerRow.implicitHeight + Theme.spacingS * 2
        radius: Theme.radius
        color: Qt.rgba(Theme.error.r, Theme.error.g, Theme.error.b, 0.22)
        border.width: 1
        border.color: Qt.rgba(Theme.error.r, Theme.error.g, Theme.error.b, 0.6)

        RowLayout {
            id: bannerRow
            anchors.fill: parent
            anchors.margins: Theme.spacingS
            spacing: Theme.spacingS

            MdIcon {
                codepoint: 0xF05D6 // md-alert_circle_outline
                color: Theme.error
            }
            StyledText {
                Layout.fillWidth: true
                text: page.error
                wrapMode: Text.WordWrap
                maximumLineCount: 3
                font.pixelSize: Theme.fontSmall
            }
            MdIcon {
                codepoint: 0xF0156 // md-close
                font.pixelSize: 14
                color: Theme.textSurfaceVariant
            }
        }
        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: page.error = ""
        }
    }

    QsEmpty {
        visible: page.radioKnown && !page.radioOn
        codepoint: 0xF05AA // md-wifi_off
        title: "Wi-Fi is turned off"
        detail: page.wired !== "" ? "Connected by cable: " + page.wired : ""
        actionText: "Turn on"
        onAction: page.setRadio()
    }

    QsEmpty {
        visible: page.radioOn && !page.hasDevice && !radioQuery.running && !devQuery.running
        codepoint: 0xF05AA
        title: "No Wi-Fi adapter found"
        detail: "NetworkManager reports no wireless device."
    }

    QsEmpty {
        visible: page.radioOn && page.hasDevice && page.sorted.length === 0
        busy: page.scanning || listQuery.running
        codepoint: 0xF0928
        title: busy ? "Looking for networks…" : "No networks found"
        actionText: busy ? "" : "Scan again"
        onAction: page.scan("yes")
    }

    ListView {
        id: list

        property bool keyActive: false
        property int cursor: -1   // row under the mouse or keyboard

        Layout.fillWidth: true
        Layout.preferredHeight: Math.min(contentHeight, 304)
        visible: page.radioOn && count > 0
        clip: true
        spacing: 2
        boundsBehavior: Flickable.StopAtBounds
        model: ScriptModel {
            values: page.sorted
            objectProp: "ssid"
        }

        function step(by) {
            keyActive = true;
            cursor = Math.max(0, Math.min(count - 1, cursor + by));
            positionViewAtIndex(cursor, ListView.Contain);
        }

        onVisibleChanged: if (visible && page.shown) forceActiveFocus()
        Keys.onUpPressed: step(-1)
        Keys.onDownPressed: step(1)
        Keys.onReturnPressed: if (itemAtIndex(cursor)) page.activate(itemAtIndex(cursor).net)
        Keys.onEnterPressed: if (itemAtIndex(cursor)) page.activate(itemAtIndex(cursor).net)

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
            readonly property var net: modelData
            readonly property bool known: page.isSaved(net.ssid)
            readonly property bool busy: page.connecting === net.ssid
            readonly property bool asking: page.askSsid === net.ssid
            property real reveal: asking ? 1 : 0

            width: ListView.view.width
            spacing: 0
            Behavior on reveal { NumberAnimation { duration: Theme.durMedium; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.emphasized } }
            onAskingChanged: if (asking) {
                pw.text = "";
                pw.forceActiveFocus();
            }

            QsRow {
                Layout.fillWidth: true
                codepoint: page.signalIcon(entry.net.signal)
                iconColor: entry.net.inUse ? Theme.glow : Theme.textSurface
                title: entry.net.ssid
                busy: entry.busy
                highlighted: entry.net.inUse
                current: list.keyActive && list.activeFocus && list.cursor === entry.index
                subtitle: {
                    if (entry.busy)
                        return "Connecting…";
                    var parts = [];
                    parts.push(entry.net.inUse ? "Connected" : (entry.known ? "Saved" : (entry.net.secured ? "Secured" : "Open")));
                    if (entry.net.secured && entry.net.security !== "")
                        parts.push(entry.net.security);
                    parts.push(entry.net.signal + "%");
                    return parts.join(" · ");
                }
                onClicked: {
                    list.cursor = entry.index;
                    page.activate(entry.net);
                }
                onHoveredChanged: if (hovered) {
                    list.keyActive = false;
                    list.cursor = entry.index;
                }

                MdIcon {
                    visible: entry.net.secured
                    codepoint: 0xF033E // md-lock
                    font.pixelSize: 14
                    color: Theme.textSurfaceVariant
                }
                ActionButton {
                    visible: entry.net.inUse
                    implicitHeight: 26
                    text: "Disconnect"
                    onClicked: page.disconnect()
                }
            }

            // Inline password prompt for new secured networks.
            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: 42 * entry.reveal
                visible: entry.reveal > 0.01
                clip: true
                opacity: entry.reveal

                RowLayout {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.leftMargin: Theme.spacingS + 26 + Theme.spacingS
                    anchors.rightMargin: Theme.spacingS
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: Theme.spacingS

                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: 32
                        radius: Theme.radius
                        color: Theme.inset
                        border.width: 1
                        border.color: pw.activeFocus ? Theme.glow : Qt.rgba(1, 1, 1, 0.25)
                        Behavior on border.color { ColorAnimation { duration: Theme.durShort } }

                        StyledText {
                            anchors.left: parent.left
                            anchors.leftMargin: Theme.spacingS
                            anchors.verticalCenter: parent.verticalCenter
                            visible: pw.text === ""
                            text: "Password"
                            color: Theme.outline
                        }
                        TextInput {
                            id: pw
                            anchors.left: parent.left
                            anchors.right: eye.left
                            anchors.leftMargin: Theme.spacingS
                            anchors.rightMargin: Theme.spacingXs
                            anchors.verticalCenter: parent.verticalCenter
                            clip: true
                            color: Theme.textSurface
                            selectionColor: Theme.primary
                            selectedTextColor: "#ffffff"
                            font.family: Theme.font
                            font.pixelSize: Theme.fontBody
                            echoMode: eye.reveal ? TextInput.Normal : TextInput.Password
                            passwordCharacter: "•"
                            selectByMouse: true
                            onAccepted: if (text !== "") page.connectTo(entry.net, text)
                            Keys.onEscapePressed: event => {
                                page.askSsid = "";
                                list.forceActiveFocus();
                                event.accepted = true;
                            }
                        }
                        AeroButton {
                            id: eye

                            property bool reveal: false

                            anchors.right: parent.right
                            anchors.rightMargin: 3
                            anchors.verticalCenter: parent.verticalCenter
                            implicitWidth: 24
                            implicitHeight: 24
                            onClicked: reveal = !reveal
                            MdIcon {
                                anchors.centerIn: parent
                                codepoint: eye.reveal ? 0xF0209 : 0xF0208 // md-eye_off / md-eye
                                font.pixelSize: 14
                            }
                        }
                    }

                    ActionButton {
                        implicitWidth: 78
                        implicitHeight: 30
                        text: "Connect"
                        filled: true
                        opacity: pw.text !== "" ? 1 : 0.5
                        onClicked: if (pw.text !== "") page.connectTo(entry.net, pw.text)
                    }
                }
            }
        }
    }
}
