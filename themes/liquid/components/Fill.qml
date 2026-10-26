import QtQuick
import QtQuick.Effects
import qs

// Liquid Glass fill: a tinted glass drop, lighter at the top, with the
// specular rim as its only edge (also when bordered) and a soft shadow.
// Badges are a plain capsule with a fainter rim. `control` is the generic Fill.
Item {
    id: look

    readonly property bool badge: control.role === "badge"
    readonly property real cornerRadius: Math.min(control.radius, width / 2, height / 2)

    RectangularShadow {
        visible: !look.badge
        anchors.fill: parent
        radius: look.cornerRadius
        offset.y: 3
        blur: 12
        color: Theme.color("glassShadow", [0, 0, 0, 0.22])
    }

    Rectangle {
        anchors.fill: parent
        radius: look.cornerRadius
        gradient: Gradient {
            GradientStop { position: 0.0; color: Qt.lighter(control.color, 1.18) }
            GradientStop { position: 1.0; color: control.color }
        }    }

    GlassEdge {
        anchors.fill: parent
        radius: look.cornerRadius
        strength: look.badge ? 0.5 : 1
    }
}
