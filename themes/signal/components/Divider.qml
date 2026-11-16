import QtQuick
import qs

Rectangle {
    color: control.strong ? Theme.dividerStrong : Theme.divider
    Rectangle {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        height: Math.min(1, parent.height)
        color: Qt.rgba(1, 1, 1, control.strong ? 0.18 : 0.08)
    }
}
