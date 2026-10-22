import QtQuick
import qs

// Aero: a soft tint rising from the bottom edge, with an optional 1px tinted
// border. Everything stays inside its own rounded rect (no blur).
// `control` is the generic Highlight.
Rectangle {
    radius: control.radius
    color: "transparent"
    border.width: control.bordered ? 1 : 0
    border.color: Qt.rgba(control.tint.r, control.tint.g, control.tint.b, 0.5 * Math.min(1, control.level))
    gradient: Gradient {
        GradientStop { position: 0.0; color: Qt.rgba(control.tint.r, control.tint.g, control.tint.b, 0.10 * control.level) }
        GradientStop { position: 0.55; color: Qt.rgba(control.tint.r, control.tint.g, control.tint.b, 0.14 * control.level) }
        GradientStop { position: 1.0; color: Qt.rgba(control.tint.r, control.tint.g, control.tint.b, 0.42 * control.level) }
    }
}
