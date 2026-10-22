import QtQuick
import qs

// Aero fill: glossy two-tone orb (bright top, dark middle). Badges use the
// theme's badgeTop color over the fill color.
Rectangle {
    readonly property bool badge: control.role === "badge"
    readonly property real lift: control.role === "orb" ? 1.2 : 1.3

    radius: control.radius
    border.width: control.bordered ? 1 : 0
    border.color: Theme.border
    gradient: badge ? badgeGradient : orbGradient

    Gradient {
        id: orbGradient
        GradientStop { position: 0.0; color: Qt.lighter(control.color, lift) }
        GradientStop { position: 0.5; color: Qt.darker(control.color, 1.6) }
        GradientStop { position: 1.0; color: control.color }
    }
    Gradient {
        id: badgeGradient
        GradientStop { position: 0.0; color: Theme.color("badgeTop", control.color) }
        GradientStop { position: 1.0; color: control.color }
    }
}
