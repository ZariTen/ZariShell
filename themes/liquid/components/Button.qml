import QtQuick
import qs

// Liquid Glass button: a glass capsule, or a circle when it is square. Clear
// at rest unless framed; hover fades the glass in. `active` turns it into a
// solid white face (ActiveContent darkens its glyphs), or a bright frosted
// one when the content keeps its own colors. Press dims it. `control` is the
// generic Button.
Item {
    id: look

    readonly property real cornerRadius: Math.min(width / 2, height / 2, Math.max(control.radius, Theme.radiusLarge))
    readonly property bool resting: control.framed || control.active
    readonly property bool solid: control.active && control.restyleContent

    opacity: look.resting ? 1 : Math.min(1, control.level / 0.6)
    Behavior on opacity { NumberAnimation { duration: Theme.durShort } }

    Rectangle {
        anchors.fill: parent
        radius: look.cornerRadius
        color: {
            if (look.solid)
                return Theme.color("activeFill", "#ffffff");
            if (control.active)
                return Qt.rgba(1, 1, 1, 0.34);
            return Theme.color("glassFill", [1, 1, 1, 0.14]);
        }
        Behavior on color { ColorAnimation { duration: Theme.durMedium } }
    }

    // Hover brightens the glass, press dims it.
    Rectangle {
        anchors.fill: parent
        radius: look.cornerRadius
        color: control.pressed ? Qt.rgba(0, 0, 0, 0.1) : Qt.rgba(1, 1, 1, control.hovered && !look.solid ? 0.1 : 0)
        Behavior on color { ColorAnimation { duration: Theme.durShort } }
    }

    GlassEdge {
        anchors.fill: parent
        radius: look.cornerRadius
        strength: look.resting ? 1 : 0.7
    }
}
