import QtQuick
import qs

// Aero: recessed text-field frame. `control` is the generic Field.
Item {
    Rectangle {
        anchors.fill: parent
        radius: Theme.radius
        color: control.prominent ? Qt.rgba(0, 0, 0, 0.55) : Theme.inset
        border.width: 1
        border.color: control.focused ? Theme.accent : Qt.rgba(1, 1, 1, control.prominent ? 0.3 : 0.25)
        Behavior on border.color { ColorAnimation { duration: Theme.durShort } }
    }
}
