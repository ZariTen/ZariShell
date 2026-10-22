import QtQuick
import qs

// Neutral flat switch: pill track filled with the highlight when on, round
// thumb. `control` is the generic Switch.
Item {
    Rectangle {
        anchors.fill: parent
        radius: height / 2
        color: control.checked ? Theme.highlight : Theme.inset
        border.width: 1
        border.color: control.activeFocus ? Theme.accent : (control.checked ? Theme.highlight : Theme.insetBorder)
        Behavior on color { ColorAnimation { duration: Theme.durMedium } }
    }

    Rectangle {
        x: control.checked ? parent.width - width - 3 : 3
        anchors.verticalCenter: parent.verticalCenter
        width: parent.height - 6
        height: width
        radius: width / 2
        color: Theme.textSurface
        scale: control.pressed ? 0.92 : (control.hovered ? 1.08 : 1)
        Behavior on x { NumberAnimation { duration: Theme.durMedium; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.emphasized } }
        Behavior on scale { NumberAnimation { duration: Theme.durShort } }
    }
}
