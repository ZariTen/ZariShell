import QtQuick
import qs

Rectangle {
    radius: control.radius
    color: control.color
    border.width: control.bordered ? 1 : 0
    border.color: Theme.border

    Rectangle {
        anchors.fill: parent
        anchors.margins: 1
        radius: Math.max(0, control.radius - 1)
        color: "transparent"
        border.width: control.bordered ? 1 : 0
        border.color: Qt.rgba(1, 1, 1, 0.18)
        gradient: Gradient {
            GradientStop { position: 0; color: Qt.rgba(1, 1, 1, 0.07) }
            GradientStop { position: 0.45; color: "transparent" }
            GradientStop { position: 1; color: Qt.rgba(0, 0, 0, 0.08) }
        }
    }
}
