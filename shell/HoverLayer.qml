import QtQuick

// Aero hover state for list rows/cards: the shared glow fill and tinted
// border on hover, dimmer on press. Exposes MouseArea signals (clicked, wheel, …).
MouseArea {
    id: area
    property color tint: Theme.glowFill
    property real radius: Theme.radius

    anchors.fill: parent
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor

    GlowFill {
        anchors.fill: parent
        radius: area.radius
        tint: area.tint
        bordered: true
        level: area.pressed ? 0.35 : (area.containsMouse ? 0.6 : 0)
        Behavior on level { NumberAnimation { duration: Theme.durShort } }
    }
}
