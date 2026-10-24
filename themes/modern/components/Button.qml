import QtQuick
import qs

// Modern: a soft pill. Hover lays a tint wash; `active` adds a tinted fill
// with a glowing tinted ring; press dips the wash. Small buttons are fully
// round; large tiles keep the large radius. `control` is the generic Button.
Rectangle {
    id: look

    readonly property color tint: control.tint

    radius: Math.min(height / 2, Math.max(control.radius, Theme.radiusLarge))
    color: control.framed ? Theme.surfaceContainerHigh : "transparent"
    border.width: control.active ? 1 : 0
    border.color: Qt.rgba(look.tint.r, look.tint.g, look.tint.b, 0.55)

    Rectangle {
        anchors.fill: parent
        radius: parent.radius
        color: {
            if (control.pressed)
                return Qt.rgba(look.tint.r, look.tint.g, look.tint.b, 0.12);
            var strength = control.active ? 0.26 : 0.16;
            return Qt.rgba(look.tint.r, look.tint.g, look.tint.b, strength * control.level / (control.active ? 0.9 : 0.6));
        }
        Behavior on color { ColorAnimation { duration: Theme.durShort } }
    }

    // Soft outer glow while active.
    Rectangle {
        visible: control.active
        anchors.fill: parent
        anchors.margins: -2
        radius: parent.radius + 2
        color: "transparent"
        border.width: 2
        border.color: Qt.rgba(look.tint.r, look.tint.g, look.tint.b, 0.14)
    }
}
