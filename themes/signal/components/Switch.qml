import QtQuick
import qs

Item {
    id: look

    readonly property real inset: Math.max(2, Theme.px(3))

    Bevel {
        anchors.fill: parent
        radius: Theme.radiusSmall
        face: Theme.inset
        sunken: true
        light: control.activeFocus ? Theme.highlight : Theme.insetEdge
    }

    Rectangle {
        anchors.fill: parent
        anchors.margins: look.inset
        radius: Math.max(0, Theme.radiusSmall - 1)
        color: control.checked ? Qt.rgba(Theme.highlight.r, Theme.highlight.g, Theme.highlight.b, 0.28) : Theme.surfaceContainer
        Behavior on color { ColorAnimation { duration: Theme.durShort } }
    }

    Bevel {
        x: control.checked ? parent.width - width - look.inset : look.inset
        anchors.verticalCenter: parent.verticalCenter
        width: Math.max(Theme.px(8), parent.width * 0.45)
        height: Math.max(Theme.px(4), parent.height - look.inset * 2)
        radius: Theme.radiusSmall
        face: control.hovered ? Qt.lighter(Theme.color("metal", Theme.textSurfaceVariant), 1.1) : Theme.color("metal", Theme.textSurfaceVariant)
        light: Theme.color("metalLight", Theme.textSurface)
        dark: Theme.color("metalDark", Theme.border)
        sunken: control.pressed
        Behavior on x { NumberAnimation { duration: Theme.durShort } }

        Rectangle {
            anchors.centerIn: parent
            width: Theme.px(2)
            height: Math.max(Theme.px(2), parent.height - Theme.px(8))
            color: Theme.color("metalDark", Theme.border)
        }
    }
}
