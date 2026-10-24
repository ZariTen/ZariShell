import QtQuick
import qs

// Ink: a brush stroke that tapers off at both ends. `control` is the generic
// Divider.
Rectangle {
    id: look

    readonly property bool vertical: height > width
    readonly property color ink: control.strong ? Theme.dividerStrong : Theme.divider

    gradient: Gradient {
        orientation: look.vertical ? Gradient.Vertical : Gradient.Horizontal
        GradientStop { position: 0.0; color: Qt.rgba(look.ink.r, look.ink.g, look.ink.b, 0) }
        GradientStop { position: 0.12; color: look.ink }
        GradientStop { position: 0.88; color: look.ink }
        GradientStop { position: 1.0; color: Qt.rgba(look.ink.r, look.ink.g, look.ink.b, 0) }
    }
}
