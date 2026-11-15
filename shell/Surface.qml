import QtQuick

// Generic background for bars, panels, cards and dialogs. Children go on top.
// `headerHeight` (px) marks a title area a theme may style (0 = none). The
// look comes from Theme.component("Surface") and reads this item as `control`.
Item {
    id: control

    default property alias content: inner.data
    property real radius: Theme.radiusLarge
    property color color: Theme.bar
    property bool shadow: true
    property bool attachedTop: false
    property real headerHeight: 0

    clip: attachedTop

    // Extend the look past the screen edge to hide both outer and inner
    // rims, without moving the content or changing the reserved bar height.
    Loader {
        x: 0
        y: control.attachedTop ? -2 : 0
        width: parent.width
        height: parent.height + (control.attachedTop ? 2 : 0)
        source: Theme.component("Surface")
    }

    Item {
        id: inner
        anchors.fill: parent
    }
}
