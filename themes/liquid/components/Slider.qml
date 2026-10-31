import QtQuick
import QtQuick.Effects
import qs

// Liquid Glass slider: a clear glass capsule track with a white fill (or the
// tone's color) and a white capsule thumb that grows while dragged. Meters
// are the track and fill alone. `control` is the generic Slider.
Item {
    id: look

    readonly property color fill: Theme.toneColor(control.tone, control.tone === "accent" ? Theme.highlight : Qt.rgba(1, 1, 1, 0.92))


    Rectangle {
        anchors.fill: parent
        radius: height / 2
        color: Theme.color("glassFill", [1, 1, 1, 0.12])
    }

    GlassEdge {
        anchors.fill: parent
        radius: height / 2
        recessed: true
        strength: 0.7
    }

    Rectangle {
        visible: control.shown > 0
        width: Math.max(height, parent.width * control.shown)
        height: parent.height
        radius: height / 2
        color: look.fill
        Behavior on width { enabled: !control.pressed; NumberAnimation { duration: Theme.durMedium; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.standard } }
    }

    RectangularShadow {
        visible: control.interactive
        anchors.fill: thumb
        radius: thumb.radius
        offset.y: 1
        blur: 6
        color: Qt.rgba(0, 0, 0, 0.3)
        scale: thumb.scale
    }

    Rectangle {
        id: thumb
        visible: control.interactive
        height: parent.height + Theme.px(8)
        width: height * 1.7
        radius: height / 2
        x: Math.max(0, Math.min(parent.width - width, parent.width * control.shown - width / 2))
        anchors.verticalCenter: parent.verticalCenter
        color: "#ffffff"
        scale: control.pressed ? 1.2 : (control.hovered ? 1.08 : 1)
        Behavior on scale { NumberAnimation { duration: Theme.durShort; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.emphasized } }
    }
}
