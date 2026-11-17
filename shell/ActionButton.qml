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

    Loader {
        anchors.fill: parent
        anchors.margins: 1
        visible: button.filled
        z: -1
        property var control: button
        sourceComponent: Theme.effect("FilledButton") || plainFill
    }

    Component {
        id: plainFill
        Rectangle {
            radius: button.radius
            color: Theme.buttonDefault
        }
    }

    StyledText {
        id: label
        anchors.centerIn: parent
        text: button.text
        color: button.filled ? Theme.textButtonDefault : Theme.textSurface
        font.weight: Font.Medium
    }
}
