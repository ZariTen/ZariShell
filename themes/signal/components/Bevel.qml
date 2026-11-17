import QtQuick
import qs

Item {
    id: bevel

    property color face: Theme.surfaceContainer
    property real radius: Theme.radius
    property bool sunken: false
    property bool attachedTop: false
    property bool attachedSides: false
    property color light: Theme.borderLight
    property color dark: Theme.border
    property real sheen: 1.07

    readonly property real corner: Math.max(0, Math.min(radius, width / 2, height / 2))
    readonly property real depth: Math.max(0, Math.min(2, width / 4, height / 4))

    Rectangle {
        anchors.fill: parent
        radius: bevel.corner
        color: bevel.dark
    }

    Rectangle {
        anchors.fill: parent
        anchors.margins: bevel.depth / 2
        radius: Math.max(0, bevel.corner - bevel.depth / 2)
        gradient: Gradient {
            GradientStop { position: 0; color: bevel.sunken ? bevel.dark : bevel.light }
            GradientStop { position: 1; color: bevel.sunken ? bevel.light : bevel.dark }
        }
    }

    Rectangle {
        anchors.fill: parent
        anchors.margins: bevel.depth
        radius: Math.max(0, bevel.corner - bevel.depth)
        gradient: Gradient {
            GradientStop { position: 0; color: bevel.sunken ? Qt.darker(bevel.face, 1.12) : Qt.lighter(bevel.face, bevel.sheen) }
            GradientStop { position: 1; color: bevel.sunken ? bevel.face : Qt.darker(bevel.face, 1.07) }
        }
    }
}
