import QtQuick
import QtQuick.Effects
import qs

// Aero glass: tinted translucent body (the compositor blurs behind it),
// glossy vertical gradient with a hard-edged sheen band (the header area, or
// the top half), a 1px light inner edge, a dark outer edge and a soft drop
// shadow. `control` is the generic Surface.
Item {
    id: look

    readonly property real sheen: control.headerHeight > 0 ? Math.min(0.48, control.headerHeight / Math.max(1, height)) : 0.48

    Rectangle {
        anchors.fill: parent
        radius: control.radius
        color: control.color
        border.width: 1
        border.color: Theme.border

        layer.enabled: control.shadow
        layer.effect: MultiEffect {
            shadowEnabled: true
            shadowColor: "#000000"
            shadowOpacity: 0.55
            shadowBlur: 0.8
            shadowVerticalOffset: 3
            blurMax: 24
        }
    }

    // Gloss: bright top band with a hard edge, gentle darkening at the bottom.
    Rectangle {
        anchors.fill: parent
        anchors.margins: 1
        radius: Math.max(0, control.radius - 1)
        border.width: 1
        border.color: Theme.borderLight
        gradient: Gradient {
            GradientStop { position: 0.0; color: Theme.color("sheenTop", [1, 1, 1, 0.20]) }
            GradientStop { position: look.sheen; color: Theme.color("sheenMid", [1, 1, 1, 0.07]) }
            GradientStop { position: look.sheen + 0.001; color: Qt.rgba(1, 1, 1, 0.0) }
            GradientStop { position: 1.0; color: Qt.rgba(0, 0, 0, 0.10) }
        }
    }
}
