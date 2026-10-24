import QtQuick
import qs

// Ink: a paper disc drawn with an ink ring (the fill color), so the ink
// glyph or count on top stays readable. Default buttons get a second, finer
// ring inside. `control` is the generic Fill.
Rectangle {
    radius: control.radius
    color: Theme.color("paper", "#f7f3ea")
    border.width: control.role === "badge" ? 1 : 1.5
    border.color: control.color

    Rectangle {
        anchors.fill: parent
        anchors.margins: 3
        visible: control.role === "button"
        radius: Math.max(0, parent.radius - 3)
        color: "transparent"
        border.width: 1
        border.color: Qt.rgba(control.color.r, control.color.g, control.color.b, 0.35)
    }
}
