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

    Rectangle {
        anchors.fill: parent
        radius: bevel.radius
        border.width: 1
        border.color: bevel.dark
        gradient: Gradient {
            GradientStop { position: 0; color: bevel.sunken ? Qt.darker(bevel.face, 1.16) : Qt.lighter(bevel.face, 1.14) }
            GradientStop { position: 1; color: bevel.sunken ? bevel.face : Qt.darker(bevel.face, 1.12) }
        }
    }

    Rectangle {
        anchors.fill: parent
        anchors.margins: 1
        radius: Math.max(0, bevel.radius - 1)
        color: "transparent"
        border.width: 1
        border.color: bevel.sunken ? bevel.dark : Qt.rgba(bevel.light.r, bevel.light.g, bevel.light.b, 0.45)
    }

    Rectangle {
        x: 2; y: 2
        width: Math.max(0, parent.width - 4); height: 1
        visible: !bevel.attachedTop
        color: bevel.sunken ? bevel.dark : bevel.light
    }
    Rectangle {
        x: 2; y: 2
        width: 1; height: Math.max(0, parent.height - 4)
        visible: !bevel.attachedSides
        color: bevel.sunken ? bevel.dark : bevel.light
    }
    Rectangle {
        x: 2; y: parent.height - 2
        width: Math.max(0, parent.width - 4); height: 1
        color: bevel.sunken ? bevel.light : bevel.dark
    }
}
