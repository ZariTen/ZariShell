import QtQuick
import qs

// Liquid Glass highlight: a rounded tint wash with a little light at the top,
// and a tinted edge when bordered. `control` is the generic Highlight.
Rectangle {
    id: look

    readonly property real strength: Math.min(1, control.level)

    radius: Math.min(width / 2, height / 2, Math.max(control.radius, Theme.radius))
    color: Qt.rgba(control.tint.r, control.tint.g, control.tint.b, 0.34 * look.strength)
    border.width: control.bordered ? 1 : 0
    border.color: Qt.rgba(control.tint.r, control.tint.g, control.tint.b, 0.7 * look.strength)

    Rectangle {
        anchors.fill: parent
        radius: parent.radius
        gradient: Gradient {
            GradientStop { position: 0.0; color: Qt.rgba(1, 1, 1, 0.1 * look.strength) }
            GradientStop { position: 0.5; color: "transparent" }
        }
    }
}
