import QtQuick
import qs

Bevel {
    face: control.color
    radius: control.radius
    attachedTop: control.attachedTop
    attachedSides: control.attachedSides

    Rectangle {
        x: Theme.px(10); y: Theme.px(5)
        width: Math.max(0, parent.width - 2 * x)
        height: 2
        visible: control.headerHeight > 0
        color: Theme.color("rail", Theme.outline)
        Rectangle { y: 2; width: parent.width; height: 1; color: Theme.border }
    }
    Rectangle {
        x: 3; y: Math.max(0, control.headerHeight - 2)
        width: Math.max(0, parent.width - 6); height: 1
        visible: control.headerHeight > 0
        color: Theme.border
        Rectangle { y: 1; width: parent.width; height: 1; color: Qt.rgba(1, 1, 1, 0.12) }
    }
}
