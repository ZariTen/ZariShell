import QtQuick
import qs

// Liquid Glass field: a recessed glass capsule (clearer for the main field of
// a screen) lit from below; focus adds a highlight ring with a faint halo.
// `control` is the generic Field.
Item {
    id: look

    readonly property real cornerRadius: Math.min(height / 2, Theme.radiusLarge)

    Rectangle {
        anchors.fill: parent
        radius: look.cornerRadius
        color: control.prominent ? Theme.color("glassFill", [1, 1, 1, 0.12]) : Theme.inset
    }

    GlassEdge {
        anchors.fill: parent
        radius: look.cornerRadius
        recessed: true
    }

    Rectangle {
        visible: control.focused
        anchors.fill: parent
        anchors.margins: -3
        radius: look.cornerRadius + 3
        color: "transparent"
        border.width: 3
        border.color: Qt.rgba(Theme.highlight.r, Theme.highlight.g, Theme.highlight.b, 0.25)
    }

    Rectangle {
        visible: control.focused
        anchors.fill: parent
        radius: look.cornerRadius
        color: "transparent"
        border.width: 1.5
        border.color: Theme.highlight
    }
}
