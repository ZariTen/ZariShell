import QtQuick
import QtQuick.Layouts

Button {
    id: control

    property string text: ""
    property string detail: ""
    property bool expanded: false

    Layout.fillWidth: true
    implicitHeight: Math.max(Theme.px(40), content.implicitHeight + Theme.spacingS * 2)
    activeFocusOnTab: true
    active: expanded || activeFocus
    passWheel: true
    Accessible.role: Accessible.Button
    Accessible.name: detail ? text + ": " + detail : text
    Accessible.onPressAction: clicked({ button: Qt.LeftButton })
    Keys.onReturnPressed: clicked({ button: Qt.LeftButton })
    Keys.onSpacePressed: clicked({ button: Qt.LeftButton })

    RowLayout {
        id: content
        anchors.fill: parent
        anchors.leftMargin: Theme.spacingM
        anchors.rightMargin: Theme.spacingM
        spacing: Theme.spacingS

        StyledText {
            text: control.text
            font.weight: Font.Medium
        }
        StyledText {
            Layout.fillWidth: true
            text: control.detail
            horizontalAlignment: Text.AlignRight
            elide: Text.ElideRight
            color: Theme.textSurfaceVariant
        }
        MdIcon {
            codepoint: control.expanded ? 0xF0143 : 0xF0140
            color: Theme.textSurfaceVariant
        }
    }
}
