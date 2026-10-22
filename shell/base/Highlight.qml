import QtQuick
import qs

// Neutral flat highlight: an even tint wash, optional tinted edge.
// `control` is the generic Highlight.
Rectangle {
    radius: control.radius
    color: Qt.rgba(control.tint.r, control.tint.g, control.tint.b, 0.22 * Math.min(1, control.level))
    border.width: control.bordered ? 1 : 0
    border.color: Qt.rgba(control.tint.r, control.tint.g, control.tint.b, 0.5 * Math.min(1, control.level))
}
