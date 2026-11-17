import QtQuick
import qs

Bevel {
    radius: control.radius
    sunken: control.pressed
    sheen: 1
    face: control.pressed ? Qt.darker(Theme.buttonDefault, 1.12) : control.hovered ? Qt.darker(Theme.buttonDefault, 1.04) : Theme.buttonDefault
    light: control.hovered ? Theme.highlight : Theme.borderLight
}
