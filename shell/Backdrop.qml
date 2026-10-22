import QtQuick

// Full-screen background for the lock screen and the greeter. `source` is
// the wallpaper URL (may be empty); `role` is "lock" or "login" so a theme
// can treat them differently. Look: Theme.component("Backdrop").
Item {
    id: control

    property url source
    property string role: "lock"

    Loader {
        anchors.fill: parent
        source: Theme.component("Backdrop")
    }
}
