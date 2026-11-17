import QtQuick
import qs

Bevel {
    face: control.color
    radius: control.radius
    attachedTop: control.attachedTop
    attachedSides: control.attachedSides

    // headerHeight is nominal, not the bottom of the panel's laid-out title.
    Rectangle {
        x: Math.max(Theme.px(10), parent.corner)
        y: Theme.px(5)
        width: Math.max(0, parent.width - 2 * x)
        height: 1
        visible: control.headerHeight > 0
        color: Theme.color("rail", Theme.outline)
    }
}
