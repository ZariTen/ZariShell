import QtQuick
import QtQuick.Effects

// Win7 taskbar-style glossy button face. Transparent at rest unless
// `active`; hover lights it up with an Aero glow, press darkens it.
// Put content inside; handle clicks via the `clicked` signal.
Item {
    id: button

    default property alias content: contentItem.data
    property bool active: false
    property bool alwaysFramed: false
    property real radius: Theme.radius
    property color glowColor: Theme.glow
    property alias hovered: mouse.containsMouse
    property alias pressed: mouse.pressed
    property alias acceptedButtons: mouse.acceptedButtons
    readonly property bool lit: active || mouse.containsMouse
    signal clicked(var mouse)
    signal wheel(var wheel)

    // Bottom glow (soft radial-ish blob) shown on hover/active.
    Rectangle {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 1
        width: parent.width * 0.8
        height: parent.height * 0.55
        radius: height / 2
        color: button.glowColor
        opacity: mouse.pressed ? 0.25 : (mouse.containsMouse ? 0.75 : (button.active ? 0.5 : 0))
        layer.enabled: true
        layer.effect: MultiEffect { blurEnabled: true; blur: 1; blurMax: 16 }
        Behavior on opacity { NumberAnimation { duration: Theme.durMedium } }
    }

    Rectangle {
        id: face
        anchors.fill: parent
        radius: button.radius
        opacity: button.lit || button.alwaysFramed || mouse.pressed ? 1 : 0
        color: "transparent"
        border.width: 1
        border.color: Theme.edgeDark
        Behavior on opacity { NumberAnimation { duration: Theme.durShort } }

        Rectangle {
            anchors.fill: parent
            anchors.margins: 1
            radius: Math.max(0, button.radius - 1)
            border.width: 1
            border.color: button.lit ? Qt.rgba(1, 1, 1, 0.45) : Theme.edgeLight
            gradient: Gradient {
                GradientStop { position: 0.0; color: mouse.pressed ? Qt.rgba(0, 0, 0, 0.35) : Qt.rgba(1, 1, 1, button.lit ? 0.30 : 0.16) }
                GradientStop { position: 0.47; color: mouse.pressed ? Qt.rgba(0, 0, 0, 0.25) : Qt.rgba(1, 1, 1, button.lit ? 0.14 : 0.07) }
                GradientStop { position: 0.48; color: mouse.pressed ? Qt.rgba(0, 0, 0, 0.2) : Qt.rgba(1, 1, 1, 0.02) }
                GradientStop { position: 1.0; color: mouse.pressed ? Qt.rgba(0, 0, 0, 0.1) : Qt.rgba(1, 1, 1, button.lit ? 0.10 : 0.04) }
            }
        }
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
