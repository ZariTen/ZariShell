import QtQuick
import QtQuick.Effects
import qs

// Liquid Glass backdrop: the wallpaper, heavily blurred but kept vivid, with
// a light dim toward the bottom bar; without a wallpaper a deep gradient in
// the accent hue. The login screen is a little brighter than the lock.
// `control` is the generic Backdrop.
Item {
    id: look

    readonly property bool login: control.role === "login"

    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            GradientStop { position: 0.0; color: Theme.color("primaryContainer", "#30405a") }
            GradientStop { position: 1.0; color: Theme.surface }
        }
    }

    Image {
        id: wallpaper
        anchors.fill: parent
        fillMode: Image.PreserveAspectCrop
        source: control.source
        asynchronous: true
        visible: false
    }

    MultiEffect {
        anchors.fill: parent
        source: wallpaper
        visible: wallpaper.status === Image.Ready
        autoPaddingEnabled: false
        blurEnabled: true
        blur: 1
        blurMax: 64
        saturation: 0.25
        brightness: look.login ? -0.04 : -0.1
    }

    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            GradientStop { position: 0.0; color: Qt.rgba(0, 0, 0, 0.12) }
            GradientStop { position: 0.6; color: Qt.rgba(0, 0, 0, 0.18) }
            GradientStop { position: 1.0; color: Qt.rgba(0, 0, 0, 0.45) }
        }
    }
}
