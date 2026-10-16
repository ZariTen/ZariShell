import QtQuick

// Win7-style glossy on/off switch. `checked` is what is shown; `toggled()`
// fires on click or Space, so the owner decides what actually changes.
Item {
    id: sw

    property bool checked: false
    readonly property bool hovered: mouse.containsMouse
    signal toggled

    implicitWidth: 42
    implicitHeight: 22
    opacity: enabled ? 1 : 0.45
    activeFocusOnTab: true
    Keys.onSpacePressed: sw.toggled()
    Behavior on opacity { NumberAnimation { duration: Theme.durShort } }

    Rectangle {
        id: track
        anchors.fill: parent
        radius: height / 2
        color: Theme.inset
        border.width: 1
        border.color: sw.activeFocus ? Theme.glowFill : Theme.insetBorder

        Rectangle {
            anchors.fill: parent
            anchors.margins: 1
            radius: height / 2
            opacity: sw.checked ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: Theme.durMedium } }
            gradient: Gradient {
                GradientStop { position: 0.0; color: Qt.lighter(Theme.glowFill, 1.25) }
                GradientStop { position: 0.5; color: Theme.glowFill }
                GradientStop { position: 0.51; color: Qt.darker(Theme.glowFill, 1.15) }
                GradientStop { position: 1.0; color: Theme.glowFill }
            }
        }

        // Top gloss
        Rectangle {
            anchors.fill: parent
            anchors.margins: 1
            radius: height / 2
            gradient: Gradient {
                GradientStop { position: 0.0; color: Qt.rgba(1, 1, 1, 0.28) }
                GradientStop { position: 0.5; color: Qt.rgba(1, 1, 1, 0.06) }
                GradientStop { position: 0.51; color: Qt.rgba(1, 1, 1, 0) }
                GradientStop { position: 1.0; color: Qt.rgba(1, 1, 1, 0) }
            }
        }
    }

    Rectangle {
        id: thumb
        x: sw.checked ? parent.width - width - 3 : 3
        anchors.verticalCenter: parent.verticalCenter
        width: 16
        height: 16
        radius: 8
        border.width: 1
        border.color: Theme.edgeDark
        scale: mouse.pressed ? 0.92 : (mouse.containsMouse ? 1.1 : 1)
        Behavior on x { NumberAnimation { duration: Theme.durMedium; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.emphasized } }
        Behavior on scale { NumberAnimation { duration: Theme.durShort } }
        gradient: Gradient {
            GradientStop { position: 0.0; color: "#ffffff" }
            GradientStop { position: 1.0; color: "#9fb7c9" }
        }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        anchors.margins: -3
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: sw.toggled()
    }
}
