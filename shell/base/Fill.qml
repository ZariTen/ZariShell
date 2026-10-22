import QtQuick
import qs

// Neutral fill: a solid shape.
Rectangle {
    radius: control.radius
    color: control.color
    border.width: control.bordered ? 1 : 0
    border.color: Theme.border
}
