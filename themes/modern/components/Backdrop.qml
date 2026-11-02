import QtQuick
import QtQuick.Effects
import qs

// Modern: the wallpaper, blurred and dimmed, over the plain backdrop color.
// The login screen is a little brighter than the lock. `control` is the
// generic Backdrop.
Rectangle {
    id: look

    readonly property bool login: control.role === "login"

    color: Theme.backdrop

    Image {
        id: wall
        anchors.fill: parent
        fillMode: Image.PreserveAspectCrop
        source: control.source
        asynchronous: true
        visible: false
    }

    MultiEffect {
        anchors.fill: parent
        source: wall
        visible: wall.status === Image.Ready
        autoPaddingEnabled: false
        blurEnabled: true
        blur: 1
        blurMax: 48
        saturation: 0.15
        brightness: look.login ? -0.25 : -0.35
    }
}
