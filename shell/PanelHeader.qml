import QtQuick
import QtQuick.Layouts

// Title row for glass panels: glyph + title (+ optional trailing items).
RowLayout {
    property int codepoint: 0
    property string title: ""
    default property alias trailing: tail.data

    Layout.fillWidth: true
    spacing: Theme.spacingS

    MdIcon {
        Layout.alignment: Qt.AlignVCenter
        codepoint: parent.codepoint
        color: Theme.glow
    }
    StyledText {
        Layout.alignment: Qt.AlignVCenter
        Layout.fillWidth: true
        text: parent.title
        font.pixelSize: Theme.fontTitle
        font.weight: Font.DemiBold
    }
    RowLayout {
        id: tail
        spacing: Theme.spacingXs
    }
}
