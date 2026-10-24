import QtQuick
import qs

// Ink: a writing line. The field is bare paper with an ink rule underneath
// that thickens when focused; the prominent (password) field also gets a
// faint hairline box. `control` is the generic Field.
Item {
    Rectangle {
        anchors.fill: parent
        radius: Theme.radius
        color: control.prominent ? Theme.color("paper", "#f7f3ea") : Theme.inset
        border.width: control.prominent ? 1 : 0
        border.color: Theme.outlineVariant
    }

    Rectangle {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        height: control.focused ? 2 : 1
        color: control.focused ? Theme.textSurface : Theme.outline
        Behavior on color { ColorAnimation { duration: Theme.durShort } }
    }
}
