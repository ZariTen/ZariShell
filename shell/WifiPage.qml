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

    // -- Public status and state (also feeds the Wi-Fi tile) ----------------
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
        list.sort((firstNet, secondNet) => {
            if (firstNet.inUse !== secondNet.inUse)
                return firstNet.inUse ? -1 : 1;
            var firstSaved = saved.indexOf(firstNet.ssid) !== -1;
            var secondSaved = saved.indexOf(secondNet.ssid) !== -1;
            if (firstSaved !== secondSaved)
                return firstSaved ? -1 : 1;
            return secondNet.signal - firstNet.signal || firstNet.ssid.localeCompare(secondNet.ssid);
        });
        return list;
    }

    // -- Signals ------------------------------------------------------------
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

    // -- Helper functions ---------------------------------------------------
    // nmcli -t escapes ':' and '\' with a backslash.
    function splitTerse(line) {
        var fields = [];
        var currentField = "";
        for (var i = 0; i < line.length; i++) {
            var ch = line.charAt(i);
            if (ch === "\\" && i + 1 < line.length)
                currentField += line.charAt(++i);
            else if (ch === ":") {
                fields.push(currentField);
                currentField = "";
            } else {
                currentField += ch;
            }
        }
        fields.push(currentField);
        return fields;
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
        var bestBySsid = {};
        var connectedSsid = "";
        text.split("\n").forEach(line => {
            if (line === "")
                return;
            var fields = page.splitTerse(line);
            var ssid = fields[1] || "";
            if (ssid === "")
                return;
            var securityText = fields[3] || "";
            var networkEntry = {
                ssid: ssid,
                signal: parseInt(fields[2]) || 0,
                security: securityText,
                secured: securityText !== "" && securityText !== "--",
                enterprise: securityText.indexOf("802.1X") !== -1,
                inUse: fields[0] === "*"
            };
            if (networkEntry.inUse)
                connectedSsid = ssid;
            var existingEntry = bestBySsid[ssid];
            if (existingEntry) {
                var inUse = existingEntry.inUse || networkEntry.inUse;
                networkEntry = networkEntry.signal >= existingEntry.signal ? networkEntry : existingEntry;
                networkEntry.inUse = inUse;
            }
            bestBySsid[ssid] = networkEntry;
        });
        var result = Object.keys(bestBySsid).map(ssidKey => bestBySsid[ssidKey]);
        activeSsid = connectedSsid;
        activeSignal = bestBySsid[connectedSsid] ? bestBySsid[connectedSsid].signal : 0;
        // Don't rebuild rows under a half-typed password.
        if (askSsid !== "")
            held = result;
        else
            networks = result;
    }

    function setRadio() {
        if (radioToggle.running)
            return;
        var nextRadioState = !radioOn;
        radioToggle.command = ["nmcli", "radio", "wifi", nextRadioState ? "on" : "off"];
        radioOn = nextRadioState;
        radioKnown = true;
        if (!nextRadioState) {
            networks = [];
            activeSsid = "";
            askSsid = "";
            connecting = "";
        }
        error = "";
        radioToggle.running = true;
    }

    function connectTo(networkEntry, password) {
        if (connectProcess.running || connecting !== "")
            return;
        if (networkEntry.ssid.charAt(0) === "-") {
            error = "Can't connect to a network whose name starts with \"-\".";
            return;
        }
        var cmd = ["nmcli", "dev", "wifi", "connect", networkEntry.ssid];
        if (password !== "")
            cmd.push("password", password);
        error = "";
        connectProcess.errText = "";
        connectProcess.networkEntry = networkEntry;
        connectProcess.usedPassword = password !== "";
        connectProcess.wasSaved = isSaved(networkEntry.ssid);
        connecting = networkEntry.ssid;
        askSsid = "";
        connectProcess.command = cmd;
        connectProcess.running = true;
        connectGuard.restart();
    }

    function activate(networkEntry) {
        if (connecting !== "" || networkEntry.inUse)
            return;
        if (askSsid === networkEntry.ssid) {
            askSsid = "";
        } else if (!networkEntry.secured || isSaved(networkEntry.ssid)) {
            connectTo(networkEntry, "");
        } else if (networkEntry.enterprise) {
            error = "Enterprise (802.1X) networks need a saved profile (nm-connection-editor).";
        } else {
            error = "";
            askSsid = networkEntry.ssid;
        }
    }

    function disconnect() {
        if (device === "" || disconnectProcess.running)
            return;
        disconnectProcess.command = ["nmcli", "dev", "disconnect", device];
        disconnectProcess.running = true;
    }

    function finishConnect() {
        connectGuard.stop();
        var networkEntry = connectProcess.networkEntry;
        var stderrText = connectProcess.errText;
        connecting = "";
        if (connectProcess.code === 0) {
            error = "";
            refresh(false);
            networkChanged();
            return;
        }
        var errorLine = stderrText.split("\n").filter(line => line.trim() !== "")[0] || "Couldn't connect.";
        errorLine = errorLine.replace(/^Error:\s*/, "").replace(/^Connection activation failed:\s*(\(\d+\)\s*)?/, "");
        if (/secrets were required|no secrets|password/i.test(errorLine) && networkEntry && networkEntry.secured && !networkEntry.enterprise) {
            error = connectProcess.usedPassword ? "Wrong password, try again." : "A password is required.";
            askSsid = networkEntry.ssid;
        } else {
            error = errorLine;
        }
        // A failed attempt with a new password leaves a broken profile behind; drop it.
        if (connectProcess.usedPassword && !connectProcess.wasSaved && networkEntry) {
            deleteProfileProcess.command = ["nmcli", "connection", "delete", "id", networkEntry.ssid];
            deleteProfileProcess.running = true;
        } else {
            refresh(false);
        }
    }

    // -- Header actions and visual tree -------------------------------------
    trailing: [
        Button {
            implicitWidth: Theme.px(28)
            implicitHeight: Theme.px(28)
            enabled: page.radioOn && !page.scanning
            opacity: enabled ? 1 : Theme.dim(0.5)
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
        Switch {
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
        color: Theme.errorContainer
        border.width: 1
        border.color: Theme.errorOutline

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
                font.pixelSize: Theme.iconPx(14)
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
        title: busy ? "Looking for networks\u2026" : "No networks found"
        actionText: busy ? "" : "Scan again"
        onAction: page.scan("yes")
    }

    QsList {
        id: list

        Layout.preferredHeight: Math.min(contentHeight, 304)
        visible: page.radioOn && count > 0
        model: ScriptModel {
            values: page.sorted
            objectProp: "ssid"
        }

        onVisibleChanged: if (visible && page.shown) forceActiveFocus()
        onActivated: row => page.activate(row.networkEntry)

        delegate: ColumnLayout {
            id: entry

            required property var modelData
            required property int index
            readonly property var networkEntry: modelData
            readonly property bool known: page.isSaved(networkEntry.ssid)
            readonly property bool busy: page.connecting === networkEntry.ssid
            readonly property bool asking: page.askSsid === networkEntry.ssid
            property real reveal: asking ? 1 : 0

            width: ListView.view.width
            spacing: 0
            Behavior on reveal { NumberAnimation { duration: Theme.durMedium; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.emphasized } }
            onAskingChanged: if (asking) {
                passwordInput.text = "";
                passwordInput.forceActiveFocus();
            }

            QsRow {
                Layout.fillWidth: true
                codepoint: ShellState.wifiGlyph(entry.networkEntry.signal / 100)
                iconColor: entry.networkEntry.inUse ? Theme.accent : Theme.textSurface
                title: entry.networkEntry.ssid
                busy: entry.busy
                highlighted: entry.networkEntry.inUse
                current: list.keyActive && list.activeFocus && list.cursor === entry.index
                subtitle: {
                    if (entry.busy)
                        return "Connecting\u2026";
                    var parts = [];
                    if (entry.networkEntry.inUse)
                        parts.push("Connected");
                    else if (entry.known)
                        parts.push("Saved");
                    else if (entry.networkEntry.secured)
                        parts.push("Secured");
                    else
                        parts.push("Open");
                    if (entry.networkEntry.secured && entry.networkEntry.security !== "")
                        parts.push(entry.networkEntry.security);
                    parts.push(entry.networkEntry.signal + "%");
                    return parts.join(" \u00b7 ");
                }
                onClicked: {
                    list.cursor = entry.index;
                    page.activate(entry.networkEntry);
                }
                onHoveredChanged: if (hovered) {
                    list.keyActive = false;
                    list.cursor = entry.index;
                }

                MdIcon {
                    visible: entry.networkEntry.secured
                    codepoint: 0xF033E // md-lock
                    font.pixelSize: Theme.iconPx(14)
                    color: Theme.textSurfaceVariant
                }
                ActionButton {
                    visible: entry.networkEntry.inUse
                    implicitHeight: Theme.px(26)
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

                    Field {
                        Layout.fillWidth: true
                        implicitHeight: Theme.px(32)
                        input: passwordInput

                        StyledText {
                            anchors.left: parent.left
                            anchors.leftMargin: Theme.spacingS
                            anchors.verticalCenter: parent.verticalCenter
                            visible: passwordInput.text === ""
                            text: "Password"
                            color: Theme.outline
                        }
                        TextInput {
                            id: passwordInput
                            anchors.left: parent.left
                            anchors.right: eye.left
                            anchors.leftMargin: Theme.spacingS
                            anchors.rightMargin: Theme.spacingXs
                            anchors.verticalCenter: parent.verticalCenter
                            clip: true
                            color: Theme.textSurface
                            selectionColor: Theme.primary
                            selectedTextColor: Theme.textPrimary
                            font.family: Theme.font
                            font.pixelSize: Theme.fontBody
                            echoMode: eye.reveal ? TextInput.Normal : TextInput.Password
                            passwordCharacter: "\u2022"
                            selectByMouse: true
                            onAccepted: if (text !== "") page.connectTo(entry.networkEntry, text)
                            Keys.onEscapePressed: event => {
                                page.askSsid = "";
                                list.forceActiveFocus();
                                event.accepted = true;
                            }
                        }
                        IconButton {
                            id: eye

                            property bool reveal: false

                            anchors.right: parent.right
                            anchors.rightMargin: Theme.spacingXs
                            anchors.verticalCenter: parent.verticalCenter
                            implicitWidth: Theme.px(24)
                            codepoint: reveal ? 0xF0209 : 0xF0208 // md-eye_off / md-eye
                            icon.font.pixelSize: Theme.iconPx(14)
                            onClicked: reveal = !reveal
                        }

                    }

                    ActionButton {
                        implicitWidth: Theme.px(78)
                        implicitHeight: Theme.px(30)
                        text: "Connect"
                        filled: true
                        opacity: passwordInput.text !== "" ? 1 : Theme.dim(0.5)
                        onClicked: if (passwordInput.text !== "") page.connectTo(entry.networkEntry, passwordInput.text)
                    }
                }
            }
        }
    }

    // -- Background objects -------------------------------------------------
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
                var wifiDevice = "";
                var wiredConnection = "";
                text.split("\n").forEach(line => {
                    var fields = page.splitTerse(line);
                    if (fields[1] === "wifi" && wifiDevice === "")
                        wifiDevice = fields[0];
                    else if (fields[1] === "ethernet" && fields[2] === "connected" && wiredConnection === "")
                        wiredConnection = fields[3] || fields[0];
                });
                page.device = wifiDevice;
                page.wired = wiredConnection;
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
                var profileNames = [];
                text.split("\n").forEach(line => {
                    var fields = page.splitTerse(line);
                    if (fields.length >= 2 && (fields[fields.length - 1] === "802-11-wireless" || fields[fields.length - 1] === "wifi"))
                        profileNames.push(fields.slice(0, fields.length - 1).join(":"));
                });
                page.saved = profileNames;
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
        id: connectProcess

        property var networkEntry: null
        property bool usedPassword: false
        property bool wasSaved: false
        property int code: 0
        property string errText: ""

        environment: ({ LC_ALL: "C" })
        stderr: StdioCollector {
            onStreamFinished: connectProcess.errText = text
        }
        onExited: (exitCode, exitStatus) => {
            connectProcess.code = exitCode;
            finishTimer.restart();
        }
    }

    Process {
        id: deleteProfileProcess
        environment: ({ LC_ALL: "C" })
        onExited: page.refresh(false)
    }

    Process {
        id: disconnectProcess
        environment: ({ LC_ALL: "C" })
        onExited: {
            page.refresh(false);
            page.networkChanged();
        }
    }
}
