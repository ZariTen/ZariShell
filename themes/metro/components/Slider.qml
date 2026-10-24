import QtQuick
import qs

// Metro: a thin flat track (grey) with a solid fill in the accent or the
// state color and a narrow upright block for the thumb. Meters are a plain
// flat bar. `control` is the generic Slider.
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
    readonly property real trackHeight: control.interactive ? Math.max(2, Math.round(parent.height * 0.4)) : parent.height

    Rectangle {
        anchors.verticalCenter: parent.verticalCenter
        width: parent.width
        height: look.trackHeight
        color: control.hovered ? Theme.surfaceContainerHighest : Theme.surfaceContainerHigh
    }

    Rectangle {
        anchors.verticalCenter: parent.verticalCenter
        width: parent.width * control.shown
        height: look.trackHeight
        color: look.fill
        Behavior on width { enabled: !control.pressed; NumberAnimation { duration: Theme.durMedium; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.standard } }
    }

    Rectangle {
        visible: control.interactive
        x: Math.max(0, Math.min(parent.width - width, parent.width * control.shown - width / 2))
        anchors.verticalCenter: parent.verticalCenter
        width: Theme.px(8)
        height: parent.height + 8
        color: control.pressed ? Theme.textSurfaceVariant : Theme.textSurface
    }
}
