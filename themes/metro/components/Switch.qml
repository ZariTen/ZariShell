import QtQuick
import qs

// Metro: the Windows 8 toggle. A rectangular frame with an inner fill (accent
// when on, dark grey when off) and a solid white block for the thumb.
// `control` is the generic Switch.
Item {
    id: look

    readonly property int inner: 3

    Rectangle {
        anchors.fill: parent
        color: "transparent"
        border.width: 2
        border.color: control.hovered || control.activeFocus ? Theme.textSurface : Theme.textSurfaceVariant
    }

    Rectangle {
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.margins: look.inner + 1
        width: Math.max(0, thumb.x - look.inner - 1)
        color: control.checked ? Theme.highlight : Theme.inset
        Behavior on color { ColorAnimation { duration: Theme.durShort } }
    }

    Rectangle {
        id: thumb
        x: control.checked ? parent.width - width : 0
        y: -2
        width: Theme.px(12)
        height: parent.height + 4
        color: Theme.textSurface
        Behavior on x { NumberAnimation { duration: Theme.durMedium; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.emphasized } }
    }
}
