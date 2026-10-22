import QtQuick
import qs

// Neutral flat slider: rounded inset track, solid fill colored by `tone`,
// round thumb when interactive. `control` is the generic Slider.
Item {
    id: look

    readonly property color fill: control.tone === "critical" ? Theme.error
        : control.tone === "warning" ? Theme.warning
        : control.tone === "muted" ? Theme.outline : Theme.accent

    Rectangle {
        anchors.fill: parent
        radius: height / 2
        color: Theme.inset
    }

    Rectangle {
        width: Math.max(height, parent.width * control.shown)
        height: parent.height
        radius: height / 2
        visible: control.shown > 0
        color: look.fill
        Behavior on width { enabled: !control.pressed; NumberAnimation { duration: Theme.durMedium; easing.type: Easing.OutCubic } }
    }

    Rectangle {
        visible: control.interactive
        x: Math.max(0, Math.min(parent.width - width, parent.width * control.shown - width / 2))
        anchors.verticalCenter: parent.verticalCenter
        width: parent.height + 4
        height: width
        radius: width / 2
        color: Theme.textSurface
        scale: control.hovered || control.pressed ? 1.15 : 1
        Behavior on scale { NumberAnimation { duration: Theme.durShort } }
    }
}
