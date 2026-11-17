import QtQuick
import qs

Rectangle {
    anchors.fill: parent
    radius: Math.max(0, Math.min(control.padding > 0 ? control.innerRadius : control.radius, width / 2, height / 2))
    color: "transparent"
    border.width: control.bordered ? 1 : 0
    border.color: Theme.border

    Rectangle {
        anchors.fill: parent
        anchors.margins: 1
        radius: Math.max(0, parent.radius - 1)
        color: "transparent"
        border.width: control.bordered ? 1 : 0
        border.color: Theme.borderLight
    }
}
