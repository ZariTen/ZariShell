import QtQuick
import qs

// Modern: a thick rounded track with a gradient fill (deep to bright accent,
// or the state color) and a round knob with a glowing accent ring. Meters are
// the rounded bar alone. `control` is the generic Slider.
Item {
    id: look

    readonly property color fill: {
        if (control.tone === "critical")
            return Theme.error;
        if (control.tone === "warning")
            return Theme.warning;
        if (control.tone === "muted")
            return Theme.outline;
        return Theme.highlight;
    }
    readonly property real fillWidth: Math.max(height, width * control.shown)

    Rectangle {
        anchors.fill: parent
        radius: height / 2
        color: Theme.surfaceContainerHighest
    }

    Rectangle {
        visible: control.shown > 0
        width: look.fillWidth
        height: parent.height
        radius: height / 2
        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0.0; color: Qt.darker(look.fill, 1.35) }
            GradientStop { position: 1.0; color: look.fill }
        }
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
        scale: control.pressed ? 1.15 : (control.hovered ? 1.07 : 1)
        Behavior on scale { NumberAnimation { duration: Theme.durShort; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.emphasized } }
    }
}
