import QtQuick
import qs

// Modern: a dark rounded island with a hairline edge. `control` is the
// generic Surface.
Rectangle {
    radius: Math.min(control.radius, height / 2)
    color: control.color
    border.width: 1
    border.color: Theme.border
}
