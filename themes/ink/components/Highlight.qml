import QtQuick
import qs

// Ink: a faint ink wash with a short ink mark in the left margin, like a
// marginal note; `bordered` adds a hairline rule. `control` is the generic
// Highlight.
Item {
    id: look

    readonly property real strength: Math.min(1, control.level)
    readonly property color ink: control.tint

    Rectangle {
        anchors.fill: parent
        radius: control.radius
        color: Qt.rgba(look.ink.r, look.ink.g, look.ink.b, 0.08 * look.strength)
        border.width: control.bordered ? 1 : 0
        border.color: Qt.rgba(look.ink.r, look.ink.g, look.ink.b, 0.55 * look.strength)
    }

    Rectangle {
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        width: 2
        height: parent.height * 0.6 * look.strength
        color: look.ink
        opacity: look.strength
    }
}
