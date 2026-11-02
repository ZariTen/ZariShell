import QtQuick
import qs

// Modern: a rounded inset pill with an accent edge when focused. `control`
// is the generic Field.
Rectangle {
    radius: Math.min(height / 2, Theme.radiusLarge)
    color: control.prominent ? Theme.surfaceContainer : Theme.inset
    border.width: control.focused ? 2 : 1
    border.color: control.focused ? Theme.highlight : Theme.outlineVariant
    Behavior on border.color { ColorAnimation { duration: Theme.durShort } }
}
