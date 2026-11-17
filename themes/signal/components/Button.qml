import QtQuick
import qs

Item {
    id: look

    readonly property real corner: Math.max(0, Math.min(control.radius, width / 2, height / 2))

    Bevel {
        anchors.fill: parent
        radius: look.corner
        visible: control.framed || control.lit || control.pressed
        sunken: control.pressed || control.active
        light: control.lit ? Qt.tint(Theme.borderLight, Qt.rgba(control.tint.r, control.tint.g, control.tint.b, 0.3)) : Theme.borderLight
        face: {
            const base = control.pressed ? Theme.inset : (control.hovered ? Theme.surfaceContainerHigh : Theme.surfaceContainer);
            return control.lit ? Qt.tint(base, Qt.rgba(control.tint.r, control.tint.g, control.tint.b, control.active ? 0.14 : 0.07)) : base;
        }
    }
    Rectangle {
        readonly property real inset: Math.max(Theme.px(4), look.corner * 0.6)
        x: inset
        y: parent.height - Theme.px(4) - height
        width: Math.max(0, parent.width - 2 * inset)
        height: Theme.px(2)
        radius: height / 2
        visible: control.active
        color: control.tint
    }
}
