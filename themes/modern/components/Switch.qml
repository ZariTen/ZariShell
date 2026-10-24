import QtQuick
import qs

// Modern: a pill track that fills with the accent when on, and a round knob
// that springs across (the emphasized curve overshoots). `control` is the
// generic Switch.
Rectangle {
    id: look

    readonly property int knobInset: 3

    radius: height / 2
    color: control.checked ? Theme.highlight : Theme.surfaceContainerHighest
    border.width: control.activeFocus ? 2 : 1
    border.color: control.activeFocus ? Theme.accent : (control.checked ? "transparent" : Theme.outlineVariant)
    Behavior on color { ColorAnimation { duration: Theme.durMedium } }

    Rectangle {
        y: look.knobInset
        x: control.checked ? look.width - width - look.knobInset : look.knobInset
        width: look.height - look.knobInset * 2
        height: width
        radius: width / 2
        color: control.checked ? Theme.surface : Theme.textSurfaceVariant
        scale: control.pressed ? 0.85 : (control.hovered ? 1.08 : 1)
        Behavior on x { NumberAnimation { duration: Theme.durMedium; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.emphasized } }
        Behavior on scale { NumberAnimation { duration: Theme.durShort } }
    }
}
