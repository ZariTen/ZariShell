import QtQuick
import qs

Rectangle {
    color: Theme.backdrop
    gradient: Gradient {
        GradientStop { position: 0; color: Theme.surfaceContainer }
        GradientStop { position: 0.55; color: Theme.backdrop }
        GradientStop { position: 1; color: Theme.inset }
    }

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
