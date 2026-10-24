import QtQuick
import qs

// Metro: a flat dark box with a 2px edge that turns accent when focused.
// `control` is the generic Field.
Rectangle {
    radius: Theme.radius
    color: Theme.inset
    border.width: 2
    border.color: control.focused ? Theme.highlight : Theme.insetBorder
    Behavior on border.color { ColorAnimation { duration: Theme.durShort } }
}
