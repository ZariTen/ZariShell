import QtQuick
import qs

// Neutral flat surface: solid translucent body and a 1px edge.
// `control` is the generic Surface.
Rectangle {
    radius: control.radius
    color: control.color
    border.width: 1
    border.color: Theme.borderLight
}
