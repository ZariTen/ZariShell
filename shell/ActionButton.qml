import QtQuick

// Win7 dark dialog button: framed glossy bevel; `filled` = default button
// (accent tinted). Hover glows, press darkens.
AeroButton {
    id: button

    property string text: ""
    property bool filled: false

    implicitWidth: Math.max(86, label.implicitWidth + Theme.spacingL * 2)
    implicitHeight: 30
    alwaysFramed: true
    radius: Theme.radius

    Rectangle {
        anchors.fill: parent
        anchors.margins: 1
        radius: button.radius
        visible: button.filled
        color: Theme.primaryContainer
        opacity: 0.7
        z: -1
    }

    StyledText {
        id: label
        anchors.centerIn: parent
        text: button.text
        font.weight: Font.Medium
    }
}
