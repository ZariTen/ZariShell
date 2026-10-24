import QtQuick
import qs

// Ink: a ruler. A hairline with quarter ticks, the value drawn over it as a
// firm ink stroke, and a paper diamond for the thumb (filled with ink while
// dragged). Meters drop the ticks and the thumb. `tone` switches the stroke
// to the error / warning / muted ink. `control` is the generic Slider.
Item {
    id: look

    readonly property color stroke: {
        if (control.tone === "critical")
            return Theme.error;
        if (control.tone === "warning")
            return Theme.warning;
        if (control.tone === "muted")
            return Theme.outline;
        return Theme.textSurface;
    }

    Rectangle {
        anchors.verticalCenter: parent.verticalCenter
        width: parent.width
        height: 1
        color: Theme.outline
    }

    Repeater {
        model: control.interactive ? 5 : 0

        Rectangle {
            required property int index
            x: Math.round((parent.width - 1) * index / 4)
            anchors.verticalCenter: parent.verticalCenter
            width: 1
            height: parent.height * 0.7
            color: Theme.outline
        }
    }

    Rectangle {
        anchors.verticalCenter: parent.verticalCenter
        width: parent.width * control.shown
        height: control.interactive ? 3 : 4
        color: look.stroke
        Behavior on width { enabled: !control.pressed; NumberAnimation { duration: Theme.durMedium; easing.type: Easing.OutCubic } }
    }

    Rectangle {
        visible: control.interactive
        x: Math.max(0, Math.min(parent.width - width, parent.width * control.shown - width / 2))
        anchors.verticalCenter: parent.verticalCenter
        width: parent.height + 2
        height: width
        rotation: 45
        color: control.pressed ? look.stroke : Theme.color("paper", "#f7f3ea")
        border.width: 1.5
        border.color: look.stroke
        scale: control.hovered || control.pressed ? 1.15 : 1
        Behavior on scale { NumberAnimation { duration: Theme.durShort } }
    }
}
