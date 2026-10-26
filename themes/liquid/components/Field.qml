import QtQuick
import qs

// Liquid Glass field: a recessed glass capsule (clearer for the main field of
// a screen) lit from below; focus turns its rim into a highlight ring.
// `control` is the generic Field.
Item {
    id: look

    readonly property real cornerRadius: Math.min(height / 2, Theme.radiusLarge)

    Rectangle {
        anchors.fill: parent
        radius: look.cornerRadius
        color: control.prominent ? Theme.color("glassFill", [1, 1, 1, 0.12]) : Theme.inset
        border.width: control.focused ? 1.5 : 0
        border.color: Theme.highlight
    }

    GlassEdge {
        visible: !control.focused
        anchors.fill: parent
        radius: look.cornerRadius
        recessed: true
    }
}
