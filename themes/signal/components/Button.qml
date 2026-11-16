import QtQuick
import qs

Item {
    Bevel {
        anchors.fill: parent
        radius: control.radius
        visible: control.framed || control.lit || control.pressed
        sunken: control.pressed || control.active
        face: {
            const base = control.pressed ? Theme.inset : (control.hovered ? Theme.surfaceContainerHigh : Theme.surfaceContainer);
            return control.lit ? Qt.tint(base, Qt.rgba(control.tint.r, control.tint.g, control.tint.b, control.active ? 0.10 : 0.04)) : base;
        }
    }
    Rectangle {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: 3
        height: 2
        visible: control.active
        color: control.tint
    }
}
