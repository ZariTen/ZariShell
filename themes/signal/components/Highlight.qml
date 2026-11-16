import QtQuick
import qs

Rectangle {
    readonly property real strength: Math.min(1, control.level)
    radius: control.radius
    color: Qt.rgba(control.tint.r, control.tint.g, control.tint.b, 0.15 * strength)
    border.width: control.bordered ? 1 : 0
    border.color: Qt.rgba(control.tint.r, control.tint.g, control.tint.b, 0.7 * strength)
}
