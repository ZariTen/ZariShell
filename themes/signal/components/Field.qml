import QtQuick
import qs

Bevel {
    face: Theme.inset
    radius: Theme.radius
    sunken: true
    light: control.focused ? Theme.highlight : Theme.insetEdge

    Rectangle {
        anchors.fill: parent
        anchors.margins: 2
        radius: Math.max(0, Theme.radius - 1)
        color: "transparent"
        border.width: control.focused ? 1 : 0
        border.color: Theme.highlight
    }
}
