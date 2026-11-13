pragma Singleton
import QtQuick
import Quickshell
import "Command.js" as Command
import "UserAccounts.js" as UserAccounts

// Greeter behaviour knobs. Colors and fonts live in Theme.qml (shared with
// the desktop shell); this file only holds greeter-specific settings.
QtObject {
    // Output that gets the login card, e.g. "DP-1". Empty = auto-detect
    // (external over internal, then most pixels, then the one at 0,0).
    readonly property string mainMonitor: Quickshell.env("QS_GREETER_MAIN_MONITOR") || ""

    // Users shown in the picker: uid range + any login shell (not nologin/false).
    readonly property var uidRange: UserAccounts.uidRange(Quickshell.env("QS_GREETER_MIN_UID"), Quickshell.env("QS_GREETER_MAX_UID"))
    readonly property real minUid: uidRange[0]
    readonly property real maxUid: uidRange[1]

    // Fallback/default session when no .desktop matches (or none are found).
    // A detected session whose Exec ends in this command is preselected.
    readonly property var sessionCommand: Command.parse(Quickshell.env("QS_GREETER_SESSION_COMMAND") || "start-hyprland", false)
    readonly property string sessionName: Quickshell.env("QS_GREETER_SESSION_NAME") || "Hyprland"
    readonly property var sessionEnv: ["XDG_SESSION_TYPE=wayland"]
    // Where wayland-sessions/*.desktop live (set by the Nix wrapper).
    readonly property string sessionsDir: Quickshell.env("QS_GREETER_SESSIONS")
        || "/run/current-system/sw/share/wayland-sessions"

    // Writable by the greeter user; remembers the last user + session.
    readonly property string stateDir: Quickshell.env("QS_GREETER_STATE") || "/var/lib/qs-greeter"

    readonly property string hostLabel: Quickshell.env("QS_GREETER_HOST_LABEL") || "NixOS"
}
