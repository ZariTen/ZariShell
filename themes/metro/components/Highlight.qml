import QtQuick
import qs

// Metro: a flat, opaque-looking tint block; `bordered` adds a 2px edge in
// the tint, the Windows 8 keyboard / selection outline. `control` is the
// generic Highlight.
Rectangle {
    readonly property real strength: Math.min(1, control.level)

    radius: control.radius
    color: Qt.rgba(control.tint.r, control.tint.g, control.tint.b, 0.3 * strength)
    border.width: control.bordered ? 2 : 0
    border.color: Qt.rgba(control.tint.r, control.tint.g, control.tint.b, strength)
}
