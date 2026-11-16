import QtQuick
import qs

Item {
    id: look

    readonly property color fill: Theme.toneColor(control.tone, Theme.highlight)
    readonly property real trackHeight: control.interactive ? Math.max(6, parent.height * 0.65) : parent.height
    readonly property real step: Theme.px(6)

    Bevel {
        anchors.verticalCenter: parent.verticalCenter
        width: parent.width; height: look.trackHeight
        radius: 1
        face: Theme.inset
        sunken: true
    }

    Item {
        x: 2
        anchors.verticalCenter: parent.verticalCenter
        width: Math.max(0, parent.width - 4)
        height: Math.max(1, look.trackHeight - 4)
        clip: true

        Repeater {
            model: Math.max(0, Math.floor(parent.width / look.step))
            Rectangle {
                required property int index
                x: index * look.step
                width: Math.max(1, look.step - Theme.px(2))
                height: parent.height
                color: index < Math.ceil(control.shown * Math.floor(parent.width / look.step)) ? look.fill : Qt.rgba(look.fill.r, look.fill.g, look.fill.b, 0.1)
            }
        }
    }

    Bevel {
        visible: control.interactive
        x: Math.max(0, Math.min(parent.width - width, parent.width * control.shown - width / 2))
        anchors.verticalCenter: parent.verticalCenter
        width: Theme.px(13)
        height: parent.height + Theme.px(8)
        radius: 1
        face: Theme.color("metal", Theme.textSurfaceVariant)
        light: Theme.color("metalLight", Theme.textSurface)
        dark: Theme.color("metalDark", Theme.border)
        sunken: control.pressed

        Rectangle {
            anchors.centerIn: parent
            width: 1; height: Math.max(1, parent.height - 8)
            color: Theme.color("metalDark", Theme.border)
        }
    }
}
