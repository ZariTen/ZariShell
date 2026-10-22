import QtQuick
import QtQuick.Layouts

// Centered empty / loading / unavailable state for the quick settings
// pickers: glyph (or spinner), message, detail and an optional action.
Item {
    id: empty

    property int codepoint: 0
    property string title: ""
    property string detail: ""
    property string actionText: ""
    property bool busy: false
    signal action

    Layout.fillWidth: true
    implicitHeight: Theme.px(136)

    Column {
        anchors.centerIn: parent
        width: parent.width
        spacing: Theme.spacingS

        Item {
            anchors.horizontalCenter: parent.horizontalCenter
            implicitWidth: Theme.px(40)
            implicitHeight: Theme.px(40)
            width: Theme.px(40)
            height: Theme.px(40)

            MdIcon {
                anchors.centerIn: parent
                visible: !empty.busy
                codepoint: empty.codepoint
                font.pixelSize: Theme.iconPx(32)
                color: Theme.outline
            }
            Spinner {
                anchors.centerIn: parent
                running: empty.busy
                font.pixelSize: Theme.iconPx(32)
                color: Theme.accent
            }
        }

        StyledText {
            anchors.horizontalCenter: parent.horizontalCenter
            width: Math.min(implicitWidth, parent.width - Theme.spacingL * 2)
            horizontalAlignment: Text.AlignHCenter
            text: empty.title
            font.weight: Font.DemiBold
        }
        StyledText {
            anchors.horizontalCenter: parent.horizontalCenter
            width: parent.width - Theme.spacingL * 2
            horizontalAlignment: Text.AlignHCenter
            visible: text !== ""
            text: empty.detail
            wrapMode: Text.WordWrap
            maximumLineCount: 2
            font.pixelSize: Theme.fontSmall
            color: Theme.textSurfaceVariant
        }
        ActionButton {
            anchors.horizontalCenter: parent.horizontalCenter
            visible: empty.actionText !== ""
            text: empty.actionText
            filled: true
            onClicked: empty.action()
        }
    }
}
