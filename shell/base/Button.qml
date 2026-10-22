import QtQuick
import qs

// Neutral flat button face: a faint fill when framed, a tint wash on hover /
// active, darker on press. `control` is the generic Button.
Rectangle {
    radius: control.radius
    color: control.framed ? Theme.surfaceContainer : "transparent"
    border.width: control.framed || control.lit ? 1 : 0
    border.color: control.lit ? Qt.rgba(control.tint.r, control.tint.g, control.tint.b, 0.5) : Theme.borderLight

    Rectangle {
        anchors.fill: parent
        radius: parent.radius
        color: control.pressed ? Theme.inset : Qt.rgba(control.tint.r, control.tint.g, control.tint.b, 0.28 * control.level)
        Behavior on color { ColorAnimation { duration: Theme.durShort } }
    }
}
