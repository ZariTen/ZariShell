import QtQuick

// Generic button. Put content inside; handle `clicked` / `wheel`. Transparent
// at rest unless `active` or `framed`; hover and `active` light it up with
// `tint`. The face comes from Theme.component("Button") and reads this item
// as `control`.
Item {
    id: control

    default property alias content: contentItem.data
    property bool active: false
    property bool framed: false        // show the face at rest too
    property real radius: Theme.radius
    property color tint: Theme.highlight
    property alias hovered: mouse.containsMouse
    property alias pressed: mouse.pressed
    property alias acceptedButtons: mouse.acceptedButtons
    readonly property bool lit: active || mouse.containsMouse

    // 0..1 highlight strength: hover brightens, active stays calm, press dims.
    readonly property real level: {
        if (mouse.pressed)
            return 0.35;
        if (active)
            return mouse.containsMouse ? 1 : 0.9;
        return mouse.containsMouse ? 0.6 : 0;
    }

    signal clicked(var mouse)
    signal wheel(var wheel)

    Loader {
        anchors.fill: parent
        source: Theme.component("Button")
    }

    Item {
        id: contentItem
        anchors.fill: parent
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: mouseEvent => control.clicked(mouseEvent)
        onWheel: wheelEvent => control.wheel(wheelEvent)
    }
}
