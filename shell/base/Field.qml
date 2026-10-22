import QtQuick
import qs

// Neutral flat text-field frame: inset well, accent edge when focused.
// `control` is the generic Field.
Rectangle {
    radius: Theme.radius
    color: Theme.inset
    border.width: control.focused && control.prominent ? 2 : 1
    border.color: control.focused ? Theme.accent : Theme.insetBorder
    Behavior on border.color { ColorAnimation { duration: Theme.durShort } }
}
