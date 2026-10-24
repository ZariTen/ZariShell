import QtQuick
import qs

// Ink: a square ink-ruled box. Off: an ink block on the left. On: the box
// fills with ink and a paper block sits on the right. Keyboard focus adds an
// outer hairline. `control` is the generic Switch.
Item {
    id: look

    readonly property color ink: Theme.textSurface
    readonly property color paper: Theme.color("paper", "#f7f3ea")

    Rectangle {
        anchors.fill: parent
        anchors.margins: -3
        visible: control.activeFocus
        color: "transparent"
        border.width: 1
        border.color: Theme.outline
    }

    Rectangle {
        anchors.fill: parent
        color: control.checked ? look.ink : "transparent"
        border.width: 1.5
        border.color: look.ink
        Behavior on color { ColorAnimation { duration: Theme.durMedium } }
    }

    Rectangle {
        x: control.checked ? parent.width - width - 4 : 4
        anchors.verticalCenter: parent.verticalCenter
        width: parent.height - 8
        height: width
        color: control.checked ? look.paper : look.ink
        scale: control.pressed ? 0.85 : 1
        Behavior on x { NumberAnimation { duration: Theme.durMedium; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.emphasized } }
        Behavior on color { ColorAnimation { duration: Theme.durMedium } }
        Behavior on scale { NumberAnimation { duration: Theme.durShort } }
    }
}
