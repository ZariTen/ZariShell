import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Services.Greetd

// Logon screen driving greetd. Fills the whole cage output layout; every
// screen gets the wallpaper, only the detected main screen gets clock, card
// and bar. Layout mirrors LockSurface.qml; colors/fonts come from Theme.qml.
Item {
    id: root

    // ── Screens ─────────────────────────────────────────────────────────
    readonly property real originX: Math.min.apply(null, Quickshell.screens.map(s => s.x).concat([1e9])) % 1e9
    readonly property real originY: Math.min.apply(null, Quickshell.screens.map(s => s.y).concat([1e9])) % 1e9
    readonly property var mainScreen: pickMain(Quickshell.screens)

    function isInternal(s) { return /^(eDP|LVDS|DSI)/i.test(s.name || ""); }
    function pickMain(screens) {
        if (screens.length === 0) return null;
        if (GreeterConfig.mainMonitor !== "") {
            for (var i = 0; i < screens.length; i++)
                if (screens[i].name === GreeterConfig.mainMonitor) return screens[i];
        }
        var list = screens.slice();
        list.sort(function (a, b) {
            var ea = isInternal(a) ? 1 : 0, eb = isInternal(b) ? 1 : 0;
            if (ea !== eb) return ea - eb;                      // external first
            var pa = a.width * a.height * a.devicePixelRatio * a.devicePixelRatio;
            var pb = b.width * b.height * b.devicePixelRatio * b.devicePixelRatio;
            if (pa !== pb) return pb - pa;                      // most physical pixels
            var za = (a.x === 0 && a.y === 0) ? 0 : 1, zb = (b.x === 0 && b.y === 0) ? 0 : 1;
            if (za !== zb) return za - zb;                      // at 0,0
            return (a.x - b.x) || (a.y - b.y);                  // leftmost
        });
        return list[0];
    }

    // ── Users (from /etc/passwd) ────────────────────────────────────────
    property var users: []               // [{ name, real, home }]
    property string userName: ""
    property var currentUser: users.find(u => u.name === userName) || ({ name: userName, real: userName, home: "" })
    property bool pickingUser: false
    property bool typingUser: false
    property string savedUser: ""
    property string savedSession: ""

    FileView {
        path: "/etc/passwd"
        onLoaded: {
            var out = [];
            var lines = text().split("\n");
            for (var i = 0; i < lines.length; i++) {
                var f = lines[i].split(":");
                if (f.length < 7) continue;
                var uid = parseInt(f[2]);
                if (uid < GreeterConfig.minUid || uid > GreeterConfig.maxUid) continue;
                if (f[6] === "" || /(nologin|false)$/.test(f[6])) continue;
                out.push({ name: f[0], real: (f[4] || "").split(",")[0] || f[0], home: f[5] });
            }
            root.users = out;
            root.pickDefaultUser();
        }
    }
    // Last successful login, written just before launching the session.
    FileView {
        id: lastFile
        path: GreeterConfig.stateDir + "/last"
        blockWrites: true
        printErrors: false
        onLoaded: {
            try {
                var d = JSON.parse(text());
                root.savedUser = d.user || "";
                root.savedSession = d.session || "";
            } catch (e) {}
            root.pickDefaultUser();
            root.pickDefaultSession();
        }
        onLoadFailed: { root.pickDefaultUser(); root.pickDefaultSession(); }
    }
    function pickDefaultUser() {
        if (userName !== "") return;
        if (savedUser !== "" && (users.length === 0 || users.some(u => u.name === savedUser))) userName = savedUser;
        else if (users.length > 0) userName = users[0].name;
    }
    function cycleUser(step) {
        if (users.length === 0) return;
        var i = users.findIndex(u => u.name === userName);
        selectUser(users[((i < 0 ? 0 : i + step) % users.length + users.length) % users.length].name);
    }
    function selectUser(name) {
        if (name === userName) { pickingUser = false; typingUser = false; return; }
        if (Greetd.state !== GreetdState.Inactive) Greetd.cancelSession();
        resetAuth();
        errorText = "";
        userName = name;
        pickingUser = false;
        typingUser = false;
        password.forceActiveFocus();
    }

    // ── Sessions (wayland-sessions/*.desktop) ───────────────────────────
    property var sessions: []            // [{ name, exec: [argv] }]
    property int sessionIndex: -1
    readonly property var currentSession: sessionIndex >= 0 && sessionIndex < sessions.length
        ? sessions[sessionIndex]
        : ({ name: GreeterConfig.sessionName, exec: GreeterConfig.sessionCommand })

    Process {
        running: true
        command: ["sh", "-c", 'for f in "$1"/*.desktop; do [ -f "$f" ] || continue; '
            + 'while IFS= read -r l; do case "$l" in Name=*|Exec=*|NoDisplay=*|Hidden=*) printf "%s\\t%s\\n" "$f" "$l";; esac; done < "$f"; done',
            "sh", GreeterConfig.sessionsDir]
        stdout: StdioCollector {
            onStreamFinished: {
                var byFile = {};
                var order = [];
                text.split("\n").forEach(function (line) {
                    var t = line.indexOf("\t");
                    if (t < 0) return;
                    var file = line.slice(0, t), kv = line.slice(t + 1), eq = kv.indexOf("=");
                    var k = kv.slice(0, eq), v = kv.slice(eq + 1);
                    if (!byFile[file]) { byFile[file] = {}; order.push(file); }
                    if (byFile[file][k] === undefined) byFile[file][k] = v; // first (unlocalized) key wins
                });
                var out = [];
                order.forEach(function (file) {
                    var e = byFile[file];
                    if (!e.Exec || e.NoDisplay === "true" || e.Hidden === "true") return;
                    var argv = e.Exec.replace(/%[a-zA-Z]/g, "").trim().split(/\s+/);
                    out.push({ name: e.Name || file.split("/").pop(), exec: argv });
                });
                root.sessions = out;
                root.pickDefaultSession();
            }
        }
    }
    function pickDefaultSession() {
        if (sessions.length === 0) return;
        var want = savedSession;
        var idx = want !== "" ? sessions.findIndex(s => s.name === want) : -1;
        if (idx < 0) {
            var cmd = GreeterConfig.sessionCommand[0];
            idx = sessions.findIndex(s => s.exec[0] === cmd || s.exec[0].endsWith("/" + cmd));
        }
        if (idx < 0) idx = sessions.findIndex(s => s.name === GreeterConfig.sessionName);
        sessionIndex = idx;   // -1 keeps the GreeterConfig fallback
    }
    function cycleSession() {
        // -1 (the configured fallback) is part of the cycle only when nothing matched it.
        if (sessions.length === 0) return;
        sessionIndex = (sessionIndex + 1) % sessions.length;
    }

    // ── greetd flow ─────────────────────────────────────────────────────
    property string pendingPassword: ""
    property string errorText: ""
    property string infoText: ""
    property bool submitted: false      // login pressed, session in progress
    property bool responded: false      // first password prompt answered
    property bool awaitingPrompt: false // PAM asked a further question
    readonly property bool busy: submitted && !awaitingPrompt

    function resetAuth() {
        pendingPassword = "";
        submitted = false;
        responded = false;
        awaitingPrompt = false;
        infoText = "";
    }
    function login() {
        if (!Greetd.available) { fail("greetd is not running (preview mode)"); return; }
        if (userName === "") { fail("Choose a user"); return; }
        errorText = "";
        if (awaitingPrompt && Greetd.state === GreetdState.Authenticating) {
            awaitingPrompt = false;
            Greetd.respond(password.text);
            return;
        }
        resetAuth();
        pendingPassword = password.text;
        submitted = true;
        if (Greetd.state !== GreetdState.Inactive) Greetd.cancelSession();
        Greetd.createSession(userName);
    }
    function fail(msg) {
        resetAuth();
        errorText = msg || "Login failed";
        password.text = "";
        shakeAnim.restart();
        password.forceActiveFocus();
    }

    Connections {
        target: Greetd
        function onAuthMessage(message, error, responseRequired, echoResponse) {
            if (error) { root.errorText = message; return; }
            if (responseRequired) {
                if (!root.responded) {
                    root.responded = true;
                    var p = root.pendingPassword;
                    root.pendingPassword = "";
                    Greetd.respond(p);
                } else {
                    // Extra PAM prompt (e.g. OTP): reuse the password field.
                    root.awaitingPrompt = true;
                    root.infoText = message;
                    password.text = "";
                    password.forceActiveFocus();
                }
            } else if (message !== "") {
                root.infoText = message;
            }
        }
        function onAuthFailure(message) { root.fail(message || "Incorrect password"); }
        function onError(error) { root.fail(error); }
        function onReadyToLaunch() {
            root.infoText = "Welcome";
            lastFile.setText(JSON.stringify({ user: root.userName, session: root.currentSession.name }));
            Greetd.launch(root.currentSession.exec, GreeterConfig.sessionEnv);
        }
    }

    SystemClock { id: clock; precision: SystemClock.Seconds }

    // ── Background: one copy per screen ─────────────────────────────────
    Repeater {
        model: Quickshell.screens.length > 0 ? Quickshell.screens : [null]
        Item {
            required property var modelData
            x: modelData ? modelData.x - root.originX : 0
            y: modelData ? modelData.y - root.originY : 0
            width: modelData ? modelData.width : root.width
            height: modelData ? modelData.height : root.height
            clip: true

            Backdrop {
                anchors.fill: parent
                source: Theme.fileUrl(Wallpaper.path)
                role: "login"
            }
        }
    }

    // ── Main screen content ─────────────────────────────────────────────
    Item {
        id: main
        x: root.mainScreen ? root.mainScreen.x - root.originX : 0
        y: root.mainScreen ? root.mainScreen.y - root.originY : 0
        width: root.mainScreen ? Math.min(root.mainScreen.width, root.width - x) : root.width
        height: root.mainScreen ? Math.min(root.mainScreen.height, root.height - y) : root.height

        // Click outside the picker closes it.
        MouseArea {
            anchors.fill: parent
            enabled: root.pickingUser
            onClicked: root.pickingUser = false
        }

        // Clock
        Column {
            anchors.horizontalCenter: parent.horizontalCenter
            y: parent.height * 0.10
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
                color: Theme.textSurfaceVariant
                font.family: Theme.font
                font.pixelSize: Theme.fontHeadline
            }
        }

        // Logon card
        Item {
            id: card
            anchors.horizontalCenter: parent.horizontalCenter
            y: parent.height * 0.40
            width: 380
            height: col.implicitHeight + Theme.spacingXl * 2
            transform: Translate { id: shake }

            SequentialAnimation {
                id: shakeAnim
                NumberAnimation { target: shake; property: "x"; to: -14; duration: 50 }
                NumberAnimation { target: shake; property: "x"; to: 12; duration: 70 }
                NumberAnimation { target: shake; property: "x"; to: -8; duration: 60 }
                NumberAnimation { target: shake; property: "x"; to: 5; duration: 50 }
                NumberAnimation { target: shake; property: "x"; to: 0; duration: 40 }
            }

            Surface {
                anchors.fill: parent
                color: Theme.panel
                headerHeight: 60
            }

            ColumnLayout {
                id: col
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: Theme.spacingXl
                spacing: Theme.spacingM

                // Avatar with prev/next user arrows
                RowLayout {
                    Layout.alignment: Qt.AlignHCenter
                    spacing: Theme.spacingM
                    Button {
                        visible: root.users.length > 1
                        implicitWidth: 28; implicitHeight: 28; radius: Theme.radiusFull
                        onClicked: root.cycleUser(-1)
                        MdIcon { anchors.centerIn: parent; codepoint: 0xF0141 } // md-chevron_left
                    }
                    Avatar {
                        implicitWidth: 112; implicitHeight: 112
                        user: root.userName
                        home: root.currentUser.home
                    }
                    Button {
                        visible: root.users.length > 1
                        implicitWidth: 28; implicitHeight: 28; radius: Theme.radiusFull
                        onClicked: root.cycleUser(1)
                        MdIcon { anchors.centerIn: parent; codepoint: 0xF0142 } // md-chevron_right
                    }
                }

                // Name: click to open the user picker.
                Button {
                    Layout.alignment: Qt.AlignHCenter
                    visible: !root.typingUser
                    implicitWidth: nameRow.implicitWidth + Theme.spacingL * 2
                    implicitHeight: 34
                    onClicked: root.pickingUser = !root.pickingUser
                    RowLayout {
                        id: nameRow
                        anchors.centerIn: parent
                        spacing: Theme.spacingXs
                        StyledText {
                            text: root.currentUser.real || "Choose a user"
                            font.pixelSize: Theme.fontHeadline
                            font.weight: Font.Medium
                        }
                        MdIcon { codepoint: 0xF0140; color: Theme.textSurfaceVariant } // md-chevron_down
                    }
                }

                // Typed user name ("Other user…")
                Field {
                    Layout.fillWidth: true
                    visible: root.typingUser
                    prominent: true
                    input: userInput
                    TextInput {
                        id: userInput
                        anchors.fill: parent
                        anchors.leftMargin: Theme.spacingM
                        anchors.rightMargin: Theme.spacingM
                        verticalAlignment: TextInput.AlignVCenter
                        color: Theme.textSurface
                        font.family: Theme.font
                        font.pixelSize: Theme.fontBody
                        clip: true
                        onAccepted: if (text.trim() !== "") root.selectUser(text.trim())
                        Keys.onEscapePressed: { root.typingUser = false; password.forceActiveFocus(); }
                        StyledText {
                            anchors.fill: parent
                            visible: userInput.text === ""
                            text: "User name"
                            color: Theme.textSurfaceVariant
                            font.italic: true
                        }
                    }
                }

                StyledText {
                    Layout.alignment: Qt.AlignHCenter
                    Layout.topMargin: -Theme.spacingS
                    text: root.typingUser ? "Enter to confirm, Esc to cancel" : root.userName
                    color: Theme.textSurfaceVariant
                    font.pixelSize: Theme.fontSmall
                }

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
                            color: Theme.textSurface
                            font.family: Theme.font
                            font.pixelSize: Theme.fontBody
                            enabled: !root.busy
                            focus: true
                            clip: true
                            Component.onCompleted: forceActiveFocus()
                            onAccepted: root.login()
                            StyledText {
                                anchors.fill: parent
                                visible: password.text === ""
                                text: root.busy ? "Logging on…" : (root.awaitingPrompt ? root.infoText : "Password")
                                color: Theme.textSurfaceVariant
                                font.italic: true
                            }
                        }
                    }

                    Button {
                        implicitWidth: 34
                        implicitHeight: 34
                        radius: Theme.radiusFull
                        framed: true
                        active: password.text !== ""
                        onClicked: root.login()
                        Fill {
                            anchors.fill: parent
                            anchors.margins: 1
                            z: -1
                        }
                        MdIcon {
                            anchors.centerIn: parent
                            codepoint: root.busy ? 0xF0450 : 0xF0054 // md-refresh / md-arrow_right
                            font.pixelSize: 18
                            RotationAnimation on rotation {
                                running: root.busy; from: 0; to: 360; duration: 900; loops: Animation.Infinite
                            }
                        }
                    }
                }

                StyledText {
                    Layout.alignment: Qt.AlignHCenter
                    Layout.maximumWidth: card.width - Theme.spacingXl * 2
                    visible: text !== ""
                    text: root.errorText
                    color: Theme.error
                    wrapMode: Text.Wrap
                    horizontalAlignment: Text.AlignHCenter
                }
                StyledText {
                    Layout.alignment: Qt.AlignHCenter
                    visible: text !== "" && root.errorText === "" && !root.awaitingPrompt
                    text: root.infoText
                    color: Theme.textSurfaceVariant
                    font.pixelSize: Theme.fontSmall
                }
            }
        }

        // User picker popup (below the card's name button)
        Item {
            id: picker
            visible: root.pickingUser
            anchors.horizontalCenter: card.horizontalCenter
            y: card.y + 170
            width: 300
            height: pickCol.implicitHeight + Theme.spacingS * 2
            z: 10

            Surface { anchors.fill: parent; color: Theme.panel }
            MouseArea { anchors.fill: parent } // swallow clicks
            ColumnLayout {
                id: pickCol
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: Theme.spacingS
                spacing: 2
                Repeater {
                    model: root.users
                    Button {
                        required property var modelData
                        Layout.fillWidth: true
                        implicitHeight: 44
                        active: modelData.name === root.userName
                        onClicked: root.selectUser(modelData.name)
                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: Theme.spacingS
                            spacing: Theme.spacingM
                            Avatar {
                                implicitWidth: 36; implicitHeight: 36; frame: 3
                                user: modelData.name; home: modelData.home
                            }
                            ColumnLayout {
                                spacing: 0
                                StyledText { text: modelData.real; font.weight: Font.Medium }
                                StyledText { text: modelData.name; color: Theme.textSurfaceVariant; font.pixelSize: Theme.fontSmall }
                            }
                        }
                    }
                }
                Button {
                    Layout.fillWidth: true
                    implicitHeight: 36
                    onClicked: {
                        root.pickingUser = false;
                        root.typingUser = true;
                        userInput.text = "";
                        userInput.forceActiveFocus();
                    }
                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: Theme.spacingM
                        spacing: Theme.spacingM
                        MdIcon { codepoint: 0xF0014 } // md-account_plus
                        StyledText { text: "Other user…" }
                    }
                }
            }
        }

        // Bottom bar: branding, session selector, power
        Process { id: power }
        Surface {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            height: 44
            radius: Theme.barRadius
            shadow: false

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: Theme.spacingL
                anchors.rightMargin: Theme.spacingS
                spacing: Theme.spacingS

                MdIcon { codepoint: 0xF1105; color: Theme.accent; font.pixelSize: 20 }
                StyledText {
                    text: GreeterConfig.hostLabel
                    font.pixelSize: Theme.fontTitle
                    font.weight: Font.DemiBold
                }
                Item { Layout.fillWidth: true }

                // Session: click to cycle through detected sessions.
                Button {
                    implicitWidth: sRow.implicitWidth + Theme.spacingM * 2
                    implicitHeight: 32
                    onClicked: root.cycleSession()
                    RowLayout {
                        id: sRow
                        anchors.centerIn: parent
                        spacing: Theme.spacingXs
                        MdIcon { codepoint: 0xF0379; color: Theme.accent } // md-monitor
                        StyledText { text: root.currentSession.name }
                        MdIcon {
                            visible: root.sessions.length > 1
                            codepoint: 0xF04E6 // md-sync
                            color: Theme.textSurfaceVariant
                        }
                    }
                }
                Item { implicitWidth: Theme.spacingM }

                Repeater {
                    model: [
                        { icon: 0xF0709, label: "Restart", action: "reboot" },     // md-restart
                        { icon: 0xF0425, label: "Shut down", action: "poweroff" }  // md-power
                    ]
                    Button {
                        required property var modelData
                        implicitWidth: pRow.implicitWidth + Theme.spacingM * 2
                        implicitHeight: 32
                        onClicked: { power.command = ["systemctl", modelData.action]; power.running = true; }
                        RowLayout {
                            id: pRow
                            anchors.centerIn: parent
                            spacing: Theme.spacingXs
                            MdIcon {
                                codepoint: modelData.icon
                                color: modelData.action === "poweroff" ? Theme.error : Theme.accent
                            }
                            StyledText { text: modelData.label }
                        }
                    }
                }
            }
        }
    }
}
