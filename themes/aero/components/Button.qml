import QtQuick
import qs

// Aero: Win7 taskbar-style glossy button face. Hover brightens the glass
// sheen, tints the border and rises a soft glow from the bottom edge (all
// clipped to the button); `active` keeps a calmer version of that tint; press
// goes dark and inset. `control` is the generic Button.
Item {
    Rectangle {
        anchors.fill: parent
        radius: control.radius
        opacity: control.lit || control.framed || control.pressed ? 1 : 0
        color: "transparent"
        border.width: 1
        border.color: Theme.border
        Behavior on opacity { NumberAnimation { duration: Theme.durShort } }

        // Glass body: light border, top-half gloss.
        Rectangle {
            anchors.fill: parent
            anchors.margins: 1
            radius: Math.max(0, control.radius - 1)
            border.width: 1
            border.color: control.pressed ? Qt.rgba(1, 1, 1, 0.18) : (control.lit ? Qt.rgba(control.tint.r, control.tint.g, control.tint.b, 0.55) : Theme.borderLight)
            Behavior on border.color { ColorAnimation { duration: Theme.durShort } }
            gradient: Gradient {
                GradientStop { position: 0.0; color: control.pressed ? Qt.rgba(0, 0, 0, 0.35) : Qt.rgba(1, 1, 1, control.lit ? 0.28 : 0.16) }
                GradientStop { position: 0.47; color: control.pressed ? Qt.rgba(0, 0, 0, 0.25) : Qt.rgba(1, 1, 1, control.lit ? 0.12 : 0.07) }
                GradientStop { position: 0.48; color: control.pressed ? Qt.rgba(0, 0, 0, 0.2) : Qt.rgba(1, 1, 1, 0.02) }
                GradientStop { position: 1.0; color: control.pressed ? Qt.rgba(0, 0, 0, 0.1) : Qt.rgba(1, 1, 1, control.lit ? 0.08 : 0.04) }
            }
        }
    }

    // Soft glow from the bottom edge, inside the face.
    Highlight {
        anchors.fill: parent
        anchors.margins: 1
        radius: Math.max(0, control.radius - 1)
        tint: control.tint
        level: control.level
        Behavior on level { NumberAnimation { duration: Theme.durMedium } }
    }
}
