import QtQuick
import QtQuick.Effects
import qs

// Liquid Glass surface: a lightly tinted pane (the compositor blurs what is
// behind it; see the README), light caught in the top of the glass, the
// specular GlassEdge rim and a soft drop shadow. `control` is the generic
// Surface.
Item {
    id: look

    readonly property real cornerRadius: Math.min(control.radius, width / 2, height / 2)
    // The sheen fades out by the end of the title area when there is one.
    readonly property real sheenEnd: control.headerHeight > 0 ? Math.min(0.6, control.headerHeight / Math.max(1, height)) : 0.4

    RectangularShadow {
        visible: control.shadow
        anchors.fill: parent
        radius: look.cornerRadius
        offset.y: 6
        blur: 24
        color: Theme.color("glassShadow", [0, 0, 0, 0.22])
    }

    Rectangle {
        anchors.fill: parent
        radius: look.cornerRadius
        color: control.color
    }

    Rectangle {
        anchors.fill: parent
        radius: look.cornerRadius
        gradient: Gradient {
            GradientStop { position: 0.0; color: Theme.color("sheenTop", [1, 1, 1, 0.1]) }
            GradientStop { position: look.sheenEnd; color: "transparent" }
            GradientStop { position: 1.0; color: Theme.color("sheenBottom", [1, 1, 1, 0.03]) }
        }
    }

    GlassEdge {
        anchors.fill: parent
        radius: look.cornerRadius
    }
}
