import QtQuick

// Win7 taskbar-style glossy button face. Transparent at rest unless
// `active` (or `alwaysFramed`). Hover brightens the glass sheen, tints the
// border and rises a soft glow from the bottom edge (all clipped to the
// button); `active` keeps a steady, calmer version of that tint; press goes
// dark and inset. Put content inside; handle clicks via the `clicked` signal.
Item {
    id: button

    default property alias content: contentItem.data
    property bool active: false
    property bool alwaysFramed: false
    property real radius: Theme.radius
    property color glowColor: Theme.glowFill
    property alias hovered: mouse.containsMouse
    property alias pressed: mouse.pressed
    property alias acceptedButtons: mouse.acceptedButtons
    readonly property bool lit: active || mouse.containsMouse
    // 0..1 strength of the tint: hover brightens, active stays calm.
    readonly property real level: mouse.pressed ? 0.35 : (active ? (mouse.containsMouse ? 1 : 0.9) : (mouse.containsMouse ? 0.6 : 0))
    signal clicked(var mouse)
    signal wheel(var wheel)

    Rectangle {
        id: face
        anchors.fill: parent
        radius: button.radius
        opacity: button.lit || button.alwaysFramed || mouse.pressed ? 1 : 0
        color: "transparent"
        border.width: 1
        border.color: Theme.edgeDark
        Behavior on opacity { NumberAnimation { duration: Theme.durShort } }

        // Glass body: light border, top-half gloss.
        Rectangle {
            anchors.fill: parent
            anchors.margins: 1
            radius: Math.max(0, button.radius - 1)
            border.width: 1
            border.color: mouse.pressed ? Qt.rgba(1, 1, 1, 0.18) : (button.lit ? Qt.rgba(button.glowColor.r, button.glowColor.g, button.glowColor.b, 0.55) : Theme.edgeLight)
            Behavior on border.color { ColorAnimation { duration: Theme.durShort } }
            gradient: Gradient {
                GradientStop { position: 0.0; color: mouse.pressed ? Qt.rgba(0, 0, 0, 0.35) : Qt.rgba(1, 1, 1, button.lit ? 0.28 : 0.16) }
                GradientStop { position: 0.47; color: mouse.pressed ? Qt.rgba(0, 0, 0, 0.25) : Qt.rgba(1, 1, 1, button.lit ? 0.12 : 0.07) }
                GradientStop { position: 0.48; color: mouse.pressed ? Qt.rgba(0, 0, 0, 0.2) : Qt.rgba(1, 1, 1, 0.02) }
                GradientStop { position: 1.0; color: mouse.pressed ? Qt.rgba(0, 0, 0, 0.1) : Qt.rgba(1, 1, 1, button.lit ? 0.08 : 0.04) }
            }
        }
    }

    // Soft glow from the bottom edge, inside the face.
    GlowFill {
        anchors.fill: parent
        anchors.margins: 1
        radius: Math.max(0, button.radius - 1)
        tint: button.glowColor
        level: button.level
        Behavior on level { NumberAnimation { duration: Theme.durMedium } }
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
        onClicked: m => button.clicked(m)
        onWheel: w => button.wheel(w)
    }
}
