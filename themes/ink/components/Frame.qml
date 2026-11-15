import QtQuick
import qs

// Ink: the picture is printed on the paper. A faint paper veil softens it and
// a hairline ink rule frames it. `control` is the generic Frame.
Rectangle {
    color: Theme.color("inkWash", Qt.rgba(0.933, 0.898, 0.827, 0.07))
    border.width: 1
    border.color: Theme.borderLight
}
