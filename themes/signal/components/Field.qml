import QtQuick
import qs

Bevel {
    face: Theme.inset
    radius: Theme.radius
    sunken: true
    light: control.focused ? Theme.highlight : Theme.insetEdge
    dark: control.focused ? Theme.highlight : Theme.insetBorder
}
