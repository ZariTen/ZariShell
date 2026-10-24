import QtQuick
import qs

// Ink: a sheet of warm paper with a fine grain and a hairline ink rule round
// the edge. Raised sheets (shadow: true) get a faint second rule set a few
// pixels off, like a print slightly out of register. `control` is the
// generic Surface.
Item {
    id: look

    readonly property bool raised: control.shadow && width > 120 && height > 60
    readonly property color ink: Theme.textSurface

    Rectangle {
        visible: look.raised
        x: 3
        y: 3
        width: parent.width
        height: parent.height
        radius: control.radius
        color: "transparent"
        border.width: 1
        border.color: Qt.rgba(look.ink.r, look.ink.g, look.ink.b, 0.22)
    }

    Rectangle {
        anchors.fill: parent
        radius: control.radius
        color: control.color
        border.width: 1
        border.color: Theme.border
    }

    Image {
        anchors.fill: parent
        anchors.margins: 1
        source: Qt.resolvedUrl("../paper-grain.png")
        fillMode: Image.Tile
        opacity: control.color.a
        visible: control.color.a > 0.3
    }
}
