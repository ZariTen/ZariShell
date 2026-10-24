import QtQuick
import qs

// Modern: a rounded inset pill; focus draws an accent ring with a faint
// outer halo. `control` is the generic Field.
Rectangle {
    radius: Math.min(height / 2, Theme.radiusLarge)
    color: control.prominent ? Theme.surfaceContainer : Theme.inset
    border.width: control.focused ? 2 : 1
    border.color: control.focused ? Theme.highlight : Theme.outlineVariant
    Behavior on border.color { ColorAnimation { duration: Theme.durShort } }

    Rectangle {
        visible: control.focused
        anchors.fill: parent
        anchors.margins: -3
        radius: parent.radius + 3
        color: "transparent"
        border.width: 3
        border.color: Qt.rgba(Theme.highlight.r, Theme.highlight.g, Theme.highlight.b, 0.15)
    }
}
