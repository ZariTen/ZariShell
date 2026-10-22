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
    property real headerHeight: 0

    Loader {
        anchors.fill: parent
        source: Theme.component("Surface")
    }

    Item {
        id: inner
        anchors.fill: parent
    }
}
