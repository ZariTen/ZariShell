import QtQuick
import QtQuick.Effects
import qs

// Liquid Glass switch: a clear glass capsule track that turns solid white
// when on, and a knob (white when off, gray on the white track) that
// stretches into a capsule while pressed and springs across. `control` is
// the generic Switch.
Item {
    id: look

    readonly property bool on: control.checked
    readonly property real knobInset: 2
    readonly property real knobHeight: height - knobInset * 2
    readonly property real knobWidth: control.pressed ? knobHeight * 1.4 : knobHeight

    Rectangle {
        anchors.fill: parent
        radius: height / 2
        color: look.on ? Theme.color("activeFill", "#ffffff") : Theme.color("glassFill", [1, 1, 1, 0.14])
        border.width: control.activeFocus ? 2 : 0
        border.color: Theme.outline
        Behavior on color { ColorAnimation { duration: Theme.durMedium } }
    }

    GlassEdge {
        anchors.fill: parent
        radius: height / 2
        recessed: true
        strength: look.on ? 0.4 : 0.8
    }

    RectangularShadow {
        anchors.fill: knob
        radius: knob.radius
        offset.y: 1
        blur: 6
        color: Qt.rgba(0, 0, 0, 0.3)
    }

    Rectangle {
        id: knob
        x: look.on ? look.width - width - look.knobInset : look.knobInset
        y: look.knobInset
        width: look.knobWidth
        height: look.knobHeight
        radius: height / 2
        color: look.on ? Theme.color("activeKnob", "#8e8e93") : "#ffffff"
        Behavior on color { ColorAnimation { duration: Theme.durMedium } }
        Behavior on x { NumberAnimation { duration: Theme.durMedium; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.emphasized } }
        Behavior on width { NumberAnimation { duration: Theme.durShort; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.emphasized } }
    }
}
