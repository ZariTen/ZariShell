import QtQuick
import QtQuick.Effects
import qs

// Modern: the wallpaper, blurred and dimmed, with a dark vignette; without a
// wallpaper a deep gradient in the accent hue. The login screen is a little
// brighter than the lock. `control` is the generic Backdrop.
Item {
    id: look

    readonly property bool login: control.role === "login"

    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            GradientStop { position: 0.0; color: Theme.color("primaryContainer", "#202030") }
            GradientStop { position: 1.0; color: Theme.backdrop }
        }
    }

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
        brightness: look.login ? -0.12 : -0.2
    }

    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            GradientStop { position: 0.0; color: Qt.rgba(0, 0, 0, 0.15) }
            GradientStop { position: 0.55; color: Qt.rgba(0, 0, 0, 0.3) }
            GradientStop { position: 1.0; color: Qt.rgba(0, 0, 0, 0.7) }
        }
    }
}
