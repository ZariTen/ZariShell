import QtQuick
import qs

// Liquid Glass button: a glass capsule, or a circle when it is square. Clear
// at rest unless framed; hover fades the glass in, `active` fills it with the
// tint like a lit Control Center toggle, press dims it. `control` is the
// generic Button.
Item {
    id: look

    readonly property real cornerRadius: Math.min(width / 2, height / 2, Math.max(control.radius, Theme.radiusLarge))
    readonly property bool resting: control.framed || control.active

    opacity: look.resting ? 1 : Math.min(1, control.level / 0.6)
    Behavior on opacity { NumberAnimation { duration: Theme.durShort } }

    Rectangle {
        anchors.fill: parent
        radius: look.cornerRadius
        color: control.active
            ? Qt.rgba(control.tint.r, control.tint.g, control.tint.b, 0.62)
            : Theme.color("glassFill", [1, 1, 1, 0.12])
        Behavior on color { ColorAnimation { duration: Theme.durMedium } }
    }

    // Hover brightens the glass, press dims it.
    Rectangle {
        anchors.fill: parent
        radius: look.cornerRadius
        color: control.pressed ? Qt.rgba(0, 0, 0, 0.08) : Qt.rgba(1, 1, 1, control.hovered ? 0.08 : 0)
        Behavior on color { ColorAnimation { duration: Theme.durShort } }
    }

    GlassEdge {
        anchors.fill: parent
        radius: look.cornerRadius
        strength: look.resting ? 1 : 0.7
    }
}
