import QtQuick
import qs

// Neutral backdrop: the wallpaper (or the plain surface color) under a scrim.
Rectangle {
    color: Theme.surface

    Image {
        anchors.fill: parent
        fillMode: Image.PreserveAspectCrop
        source: control.source
        asynchronous: true
    }

    Rectangle {
        anchors.fill: parent
        color: Theme.scrim
    }
}
