import QtQuick
import QtQuick.Effects
import qs

// Ink: the wallpaper as a faded monochrome print on warm paper, with the
// paper grain over it. Without a wallpaper it is plain paper. `control` is
// the generic Backdrop.
Item {
    id: look

    readonly property color paper: Theme.color("paper", "#f7f3ea")

    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            GradientStop { position: 0.0; color: look.paper }
            GradientStop { position: 1.0; color: Theme.surface }
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
        visible: wall.status === Image.Ready
        source: wall
        saturation: -1
        contrast: 0.2
        brightness: 0.1
        opacity: 0.3
    }

    Image {
        anchors.fill: parent
        source: Qt.resolvedUrl("../paper-grain.png")
        fillMode: Image.Tile
    }
}
