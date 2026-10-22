import QtQuick
import QtQuick.Layouts

// Sub-page of the quick settings panel: back button, glyph, title and
// trailing header controls, then the page body. Fades in when shown; hidden
// pages take no space, so the card resizes around the visible page.
ColumnLayout {
    id: page

    property int codepoint: 0
    property string title: ""
    property bool shown: false
    default property alias content: body.data
    property alias trailing: tail.data
    signal back

    Layout.fillWidth: true
    spacing: Theme.spacingM
    visible: shown
    onVisibleChanged: if (visible) fadeIn.restart()

    NumberAnimation {
        id: fadeIn
        target: page
        property: "opacity"
        from: 0
        to: 1
        duration: Theme.durMedium
        easing.type: Easing.BezierSpline
        easing.bezierCurve: Theme.standard
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: Theme.spacingS

        Button {
            implicitWidth: 28
            implicitHeight: 28
            onClicked: page.back()
            MdIcon {
                anchors.centerIn: parent
                codepoint: 0xF0141 // md-chevron_left
            }
        }
        MdIcon {
            Layout.alignment: Qt.AlignVCenter
            codepoint: page.codepoint
            color: Theme.accent
        }
        StyledText {
            Layout.fillWidth: true
            text: page.title
            font.pixelSize: Theme.fontTitle
            font.weight: Font.DemiBold
        }
        RowLayout {
            id: tail
            spacing: Theme.spacingS
        }
    }

    ColumnLayout {
        id: body
        Layout.fillWidth: true
        spacing: Theme.spacingS
    }
}
