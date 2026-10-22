import QtQuick

// Filled shape for orbs, round default buttons and count badges. Children
// go on top. `role` ("button", "orb" or "badge") lets a theme style each
// kind; `bordered` adds a 1px Theme.border edge. Look: Theme.component("Fill").
Item {
    id: control

    default property alias content: inner.data
    property color color: Theme.primary
    property real radius: Theme.radiusFull
    property bool bordered: false
    property string role: "button"

    Loader {
        anchors.fill: parent
        source: Theme.component("Fill")
    }

    Item {
        id: inner
        anchors.fill: parent
    }
}
