import QtQuick
import QtQuick.Effects
import qs

// Aero backdrop: blurred, darkened wallpaper under a vertical dim. Without a
// wallpaper the login screen shows a surface-tinted gradient.
Item {
    readonly property bool login: control.role === "login"

    Rectangle {
        anchors.fill: parent
        visible: login
        gradient: Gradient {
            GradientStop { position: 0.0; color: Qt.lighter(Theme.surface, 2.6) }
            GradientStop { position: 0.55; color: Theme.surface }
            GradientStop { position: 1.0; color: "#000000" }
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
        visible: !login || wall.status === Image.Ready
        source: wall
        blurEnabled: true
        blur: 1
        blurMax: 64
        brightness: -0.25
        saturation: -0.1
    }
    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            GradientStop { position: 0.0; color: Qt.rgba(0, 0, 0, login ? 0.30 : 0.35) }
            GradientStop { position: 0.6; color: Qt.rgba(0, 0, 0, login ? 0.50 : 0.55) }
            GradientStop { position: 1.0; color: Qt.rgba(0, 0, 0, login ? 0.78 : 0.8) }
        }
    }
}
