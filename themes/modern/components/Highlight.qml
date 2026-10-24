import QtQuick
import qs

// Modern: a rounded tint wash that brightens toward the top, with a soft
// tinted edge when bordered. `control` is the generic Highlight.
Rectangle {
    readonly property real strength: Math.min(1, control.level)

    radius: Math.max(control.radius, Theme.radius)
    gradient: Gradient {
        GradientStop { position: 0.0; color: Qt.rgba(control.tint.r, control.tint.g, control.tint.b, 0.26 * strength) }
        GradientStop { position: 1.0; color: Qt.rgba(control.tint.r, control.tint.g, control.tint.b, 0.14 * strength) }
    }
    border.width: control.bordered ? 1 : 0
    border.color: Qt.rgba(control.tint.r, control.tint.g, control.tint.b, 0.6 * strength)
}
