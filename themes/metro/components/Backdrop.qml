import QtQuick
import qs

// Metro: the wallpaper as is, sharp and unblurred, with a flat dim; without
// a wallpaper the login screen is the solid Start-screen color (a deep tone
// of the accent). `control` is the generic Backdrop.
Rectangle {
    color: Theme.color("startScreen", Theme.surface)

    Image {
        anchors.fill: parent
        fillMode: Image.PreserveAspectCrop
        source: control.source
        asynchronous: true
    }

    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(0, 0, 0, 0.35)
    }
}
