import QtQuick
import qs

Item {
    Bevel {
        anchors.fill: parent
        radius: 1
        face: Theme.inset
        sunken: true
        light: control.activeFocus ? Theme.highlight : Theme.insetEdge
    }

    Rectangle {
        x: 4; y: 4
        width: Math.max(0, parent.width - 8)
        height: Math.max(0, parent.height - 8)
        color: control.checked ? Qt.rgba(Theme.highlight.r, Theme.highlight.g, Theme.highlight.b, 0.35) : Theme.surfaceContainer
    }

    Bevel {
        x: control.checked ? parent.width - width - 3 : 3
        anchors.verticalCenter: parent.verticalCenter
        width: Math.max(8, parent.width * 0.45)
        height: Math.max(4, parent.height - 6)
        radius: 1
        face: Theme.color("metal", Theme.textSurfaceVariant)
        light: Theme.color("metalLight", Theme.textSurface)
        dark: Theme.color("metalDark", Theme.border)
        sunken: control.pressed
        Behavior on x { NumberAnimation { duration: Theme.durShort } }

        Rectangle {
            anchors.centerIn: parent
            width: 2; height: Math.max(2, parent.height - 8)
            color: control.checked ? Theme.highlight : Theme.color("metalDark", Theme.border)
        }
    }
}
