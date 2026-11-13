import QtQuick
import qs

// Aero: Win7 progress-bar style glossy slider with a round thumb. `tone`
// maps to the Win7 bar states (green / amber / red) or the accent.
// `control` is the generic Slider.
Rectangle {
    id: look

    readonly property color fill: Theme.toneColor(control.tone, control.tone === "accent" ? Theme.accent : Theme.success)
    readonly property var stops: [Qt.lighter(fill, 1.35), fill, Qt.darker(fill, 1.5), Qt.lighter(fill, 1.08)]

    radius: 2
    color: Theme.inset
    border.width: 1
    border.color: Qt.rgba(1, 1, 1, 0.25)

    Rectangle {
        x: 1
        y: 1
        width: (parent.width - 2) * control.shown
        height: parent.height - 2
        radius: 1
        Behavior on width { enabled: !control.pressed; NumberAnimation { duration: Theme.durMedium; easing.type: Easing.OutCubic } }
        gradient: Gradient {
            GradientStop { position: 0.0; color: look.stops[0] }
            GradientStop { position: 0.45; color: look.stops[1] }
            GradientStop { position: 0.5; color: look.stops[2] }
            GradientStop { position: 1.0; color: look.stops[3] }
        }
    }

    Rectangle {
        visible: control.interactive
        x: Math.max(0, Math.min(parent.width - width, (parent.width - 2) * control.shown - width / 2))
        anchors.verticalCenter: parent.verticalCenter
        width: parent.height + 2
        height: width
        radius: width / 2
        border.width: 1
        border.color: Theme.border
        scale: control.hovered || control.pressed ? 1.15 : 1
        Behavior on scale { NumberAnimation { duration: Theme.durShort } }
        gradient: Gradient {
            GradientStop { position: 0.0; color: "#ffffff" }
            GradientStop { position: 1.0; color: "#9fb7c9" }
        }
    }
}
