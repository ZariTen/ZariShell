import QtQuick
import qs

// Aero: Win7-style glossy on/off switch. `control` is the generic Switch.
Item {
    Rectangle {
        anchors.fill: parent
        radius: height / 2
        color: Theme.inset
        border.width: 1
        border.color: control.activeFocus ? Theme.highlight : Theme.insetBorder

        Rectangle {
            anchors.fill: parent
            anchors.margins: 1
            radius: height / 2
            opacity: control.checked ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: Theme.durMedium } }
            gradient: Gradient {
                GradientStop { position: 0.0; color: Qt.lighter(Theme.highlight, 1.25) }
                GradientStop { position: 0.5; color: Theme.highlight }
                GradientStop { position: 0.51; color: Qt.darker(Theme.highlight, 1.15) }
                GradientStop { position: 1.0; color: Theme.highlight }
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
        x: control.checked ? parent.width - width - 3 : 3
        anchors.verticalCenter: parent.verticalCenter
        width: 16
        height: 16
        radius: 8
        border.width: 1
        border.color: Theme.border
        scale: control.pressed ? 0.92 : (control.hovered ? 1.1 : 1)
        Behavior on x { NumberAnimation { duration: Theme.durMedium; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.emphasized } }
        Behavior on scale { NumberAnimation { duration: Theme.durShort } }
        gradient: Gradient {
            GradientStop { position: 0.0; color: "#ffffff" }
            GradientStop { position: 1.0; color: "#9fb7c9" }
        }
    }
}
