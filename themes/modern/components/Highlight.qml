import QtQuick
import qs

// Modern: a rounded, even tint wash with a tinted edge when bordered.
// `control` is the generic Highlight.
Rectangle {
    readonly property real strength: Math.min(1, control.level)

    radius: Math.max(control.radius, Theme.radius)
    color: Qt.rgba(control.tint.r, control.tint.g, control.tint.b, 0.2 * strength)
    border.width: control.bordered ? 1 : 0
    border.color: Qt.rgba(control.tint.r, control.tint.g, control.tint.b, 0.5 * strength)
}
