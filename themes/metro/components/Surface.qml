import QtQuick
import qs

// Metro: a solid, opaque panel with a 1px edge and no shadow or gloss.
// Panels with a title area (headerHeight) carry a thin accent band along the
// top, like a Windows 8 flyout. `control` is the generic Surface.
Rectangle {
    radius: control.radius
    color: control.color
    border.width: 1
    border.color: Theme.borderLight

    Rectangle {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        visible: control.headerHeight > 0
        height: 4
        color: Theme.highlight
    }
}
