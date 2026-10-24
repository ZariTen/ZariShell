import QtQuick
import qs

// Ink: no fill at rest. Hover lays a faint ink wash and draws an ink
// underline out from the center; `active` keeps a full, heavier underline and
// an ink rule round framed buttons; press darkens the wash. `control` is the
// generic Button.
Item {
    id: look

    readonly property color ink: control.tint

    Rectangle {
        anchors.fill: parent
        radius: control.radius
        color: Qt.rgba(look.ink.r, look.ink.g, look.ink.b, control.pressed ? 0.16 : 0.09 * control.level)
        border.width: control.framed ? 1 : 0
        border.color: control.active ? Theme.border : Theme.outline
        Behavior on color { ColorAnimation { duration: Theme.durShort } }
    }

    // Ink underline: grows from the center on hover, full width when active.
    Rectangle {
        anchors.bottom: parent.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        width: parent.width * (control.active ? 1 : (control.hovered ? 0.6 : 0))
        height: control.active ? 3 : 2
        color: look.ink
        Behavior on width { NumberAnimation { duration: Theme.durMedium; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.standard } }
    }
}
