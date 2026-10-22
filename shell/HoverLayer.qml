import QtQuick

// Hover state for list rows/cards: the shared Highlight with a border on
// hover, dimmer on press. Exposes MouseArea signals (clicked, wheel, ...).
MouseArea {
    id: area
    property color tint: Theme.highlight
    property real radius: Theme.radius

    anchors.fill: parent
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor

    Highlight {
        anchors.fill: parent
        radius: area.radius
        tint: area.tint
        bordered: true
        level: area.pressed ? 0.35 : (area.containsMouse ? 0.6 : 0)
        Behavior on level { NumberAnimation { duration: Theme.durShort } }
    }
}
