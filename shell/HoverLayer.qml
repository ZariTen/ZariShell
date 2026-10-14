import QtQuick

// Aero hover state for list rows/cards: light glossy fill + light border on
// hover, darker on press. Exposes MouseArea signals (clicked, wheel, …).
MouseArea {
    id: area
    property color tint: Theme.glow
    property real radius: Theme.radius

    anchors.fill: parent
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor

    Rectangle {
        anchors.fill: parent
        radius: area.radius
        opacity: area.pressed ? 0.7 : (area.containsMouse ? 1 : 0)
        border.width: 1
        border.color: Qt.rgba(area.tint.r, area.tint.g, area.tint.b, 0.55)
        gradient: Gradient {
            GradientStop { position: 0.0; color: Qt.rgba(area.tint.r, area.tint.g, area.tint.b, area.pressed ? 0.10 : 0.22) }
            GradientStop { position: 0.5; color: Qt.rgba(area.tint.r, area.tint.g, area.tint.b, 0.10) }
            GradientStop { position: 1.0; color: Qt.rgba(area.tint.r, area.tint.g, area.tint.b, 0.16) }
        }
        Behavior on opacity { NumberAnimation { duration: Theme.durShort } }
    }
}
