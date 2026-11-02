import QtQuick
import QtQuick.Window
import qs

// Modern: a dark rounded island with a hairline edge. An edge-to-edge strip
// (the bar, the lock / login bottom bars) is drawn as a floating pill inset
// from the screen edges instead. `control` is the generic Surface.
Item {
    id: look

    // Full-width and bar-high: this is an edge bar, so float it.
    readonly property bool floating: look.Window.width > 0 && width >= look.Window.width - 1 && height <= Theme.barHeight + 4
    readonly property int inset: look.floating ? Theme.px(Theme.metric("floatInset", 4)) : 0

    Rectangle {
        anchors.fill: parent
        anchors.margins: look.inset
        radius: Math.min(control.radius, height / 2)
        color: control.color
        border.width: 1
        border.color: Theme.border
    }
}
