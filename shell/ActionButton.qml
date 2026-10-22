import QtQuick

// Dialog button: always framed; `filled` = default button
// (accent tinted). Hover / press looks come from Button.
Button {
    id: button

    property string text: ""
    property bool filled: false

    implicitWidth: Math.max(86, label.implicitWidth + Theme.spacingL * 2)
    implicitHeight: Theme.px(30)
    framed: true
    radius: Theme.radius

    Rectangle {
        anchors.fill: parent
        anchors.margins: 1
        radius: button.radius
        visible: button.filled
        color: Theme.buttonDefault
        z: -1
    }

    StyledText {
        id: label
        anchors.centerIn: parent
        text: button.text
        font.weight: Font.Medium
    }
}
