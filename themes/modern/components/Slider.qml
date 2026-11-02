import QtQuick
import qs

// Modern: a thick rounded track with a solid fill (the highlight, or the
// state color) and a round knob ringed in the fill color. Meters are the
// rounded bar alone. `control` is the generic Slider.
Item {
    id: look

    readonly property color fill: Theme.toneColor(control.tone, Theme.highlight)

    Rectangle {
        anchors.fill: parent
        radius: height / 2
        color: Theme.surfaceContainerHighest
    }

    Rectangle {
        visible: control.shown > 0
        width: Math.max(height, parent.width * control.shown)
        height: parent.height
        radius: height / 2
        color: look.fill
        Behavior on width { enabled: !control.pressed; NumberAnimation { duration: Theme.durMedium; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.standard } }
    }

    Rectangle {
        visible: control.interactive
        readonly property real size: parent.height + Theme.px(8)
        width: size
        height: size
        radius: size / 2
        x: Math.max(0, Math.min(parent.width - width, parent.width * control.shown - width / 2))
        anchors.verticalCenter: parent.verticalCenter
        color: Theme.textSurface
        border.width: 3
        border.color: look.fill
    }
}
