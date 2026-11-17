import QtQuick
import qs

Item {
    id: look

    readonly property color fill: Theme.toneColor(control.tone, Theme.highlight)
    readonly property real trackHeight: control.interactive ? Math.max(Theme.px(6), height * 0.65) : height
    readonly property real step: Theme.px(6)
    readonly property real inset: Math.max(0, Math.min(2, width / 4, trackHeight / 4))

    Bevel {
        anchors.verticalCenter: parent.verticalCenter
        width: parent.width; height: look.trackHeight
        radius: Theme.radiusSmall
        face: Theme.inset
        sunken: true
    }

    Item {
        id: segments
        x: look.inset
        anchors.verticalCenter: parent.verticalCenter
        width: Math.max(0, parent.width - 2 * look.inset)
        height: Math.max(0, look.trackHeight - 2 * look.inset)
        clip: true

        readonly property int count: width > 0 ? Math.max(1, Math.floor(width / look.step)) : 0
        readonly property real gap: Math.min(Theme.px(2), width / Math.max(1, count) / 3)
        readonly property real segmentWidth: Math.max(0, (width - (count - 1) * gap) / Math.max(1, count))

        Repeater {
            model: segments.count
            Rectangle {
                required property int index
                x: index * (segments.segmentWidth + segments.gap)
                width: segments.segmentWidth
                height: segments.height
                color: index < Math.ceil(control.shown * segments.count) ? look.fill : Qt.rgba(look.fill.r, look.fill.g, look.fill.b, 0.1)
            }
        }
    }

    Bevel {
        visible: control.interactive
        x: Math.max(0, Math.min(parent.width - width, parent.width * control.shown - width / 2))
        anchors.verticalCenter: parent.verticalCenter
        width: Theme.px(13)
        height: parent.height + Theme.px(8)
        radius: Theme.radiusSmall
        face: control.hovered ? Qt.lighter(Theme.color("metal", Theme.textSurfaceVariant), 1.1) : Theme.color("metal", Theme.textSurfaceVariant)
        light: Theme.color("metalLight", Theme.textSurface)
        dark: Theme.color("metalDark", Theme.border)
        sunken: control.pressed

        Rectangle {
            anchors.centerIn: parent
            width: 1; height: Math.max(1, parent.height - Theme.px(8))
            color: Theme.color("metalDark", Theme.border)
        }
    }
}
