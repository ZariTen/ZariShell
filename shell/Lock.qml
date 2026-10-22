import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pam
import Quickshell.Wayland

// Session lock (ext-session-lock) with PAM auth via the existing "hyprlock"
// PAM service. `ipc call lock lock` locks; a successful auth unlocks.
// Set QS_LOCK_PREVIEW=1 to show a harmless, non-locking preview window.
Scope {
    id: root

    property bool locked: false
    property bool busy: false
    property string errorText: ""
    property string pending: ""
    readonly property bool preview: Quickshell.env("QS_LOCK_PREVIEW") === "1"
    signal failed

    function lock() {
        errorText = "";
        ShellState.close();
        locked = true;
    }

    function tryUnlock(password) {
        if (preview) {
            errorText = "Incorrect password";
            failed();
            return;
        }
        if (busy || password === "")
            return;
        pending = password;
        busy = true;
        errorText = "";
        if (!pam.start()) {
            busy = false;
            pending = "";
            errorText = "Authentication unavailable";
            failed();
        }
    }

    PamContext {
        id: pam
        config: "hyprlock"

        onPamMessage: {
            if (pam.responseRequired) {
                pam.respond(root.pending);
                root.pending = "";
            } else if (pam.messageIsError) {
                root.errorText = pam.message;
            }
        }

        onCompleted: result => {
            root.busy = false;
            root.pending = "";
            if (result === PamResult.Success) {
                root.errorText = "";
                root.locked = false;
            } else {
                root.errorText = "Incorrect password";
                root.failed();
            }
        }

        onError: error => {
            root.busy = false;
            root.pending = "";
            root.errorText = "Authentication error";
            root.failed();
        }
    }

    WlSessionLock {
        locked: root.locked

        WlSessionLockSurface {
            color: Theme.backdrop

            LockSurface {
                anchors.fill: parent
                lock: root
            }
        }
    }

    Connections {
        target: ShellState
        function onLockRequested() {
            root.lock();
        }
    }

    IpcHandler {
        target: "lock"

        function lock(): void {
            root.lock();
        }
    }

    // Preview (testing only): same UI in an ordinary overlay, no real lock.
    LazyLoader {
        active: root.preview

        PanelWindow {
            screen: Quickshell.screens[0]
            color: Theme.backdrop
            aboveWindows: true
            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.namespace: "shell-lock-preview"

            anchors {
                top: true
                bottom: true
                left: true
                right: true
            }

            LockSurface {
                anchors.fill: parent
                lock: root
            }
        }
    }
}
