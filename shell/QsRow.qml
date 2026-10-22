import QtQuick
import QtQuick.Layouts

// Selectable list row for the quick settings pickers: glyph (or spinner),
// title, subtitle and trailing controls. The whole row is clickable; items
// put inside sit on the right, above the click area.
Item {
    id: row

    property int codepoint: 0
    property color iconColor: Theme.textSurface
    property string title: ""
    property string subtitle: ""
    property color subtitleColor: Theme.textSurfaceVariant
    property bool highlighted: false   // e.g. the connected entry
    property bool current: false       // keyboard focus ring
    property bool busy: false
    readonly property bool hovered: hover.containsMouse
    default property alias trailing: tail.data
    signal clicked

    implicitHeight: Theme.px(46)

    // Highlighted (e.g. connected) entry
    Highlight {
        anchors.fill: parent
        radius: Theme.radius
        bordered: true
        level: row.highlighted ? 0.9 : 0
        Behavior on level { NumberAnimation { duration: Theme.durMedium } }
    }

    HoverLayer {
        id: hover
        onClicked: row.clicked()
    }

    // Keyboard focus: same look as hover
    Highlight {
        anchors.fill: parent
        radius: Theme.radius
        bordered: true
        level: row.current ? 0.6 : 0
        Behavior on level { NumberAnimation { duration: Theme.durShort } }
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: Theme.spacingS
        anchors.rightMargin: Theme.spacingS
        spacing: Theme.spacingS

        Item {
            Layout.preferredWidth: Theme.px(26)
            Layout.preferredHeight: Theme.px(26)

            MdIcon {
                anchors.centerIn: parent
                visible: !row.busy
                codepoint: row.codepoint
                font.pixelSize: Theme.iconPx(20)
                color: row.iconColor
            }
            Spinner {
                anchors.centerIn: parent
                running: row.busy
                font.pixelSize: Theme.iconPx(18)
                color: Theme.accent
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0

            StyledText {
                Layout.fillWidth: true
                text: row.title
                font.weight: row.highlighted ? Font.Bold : Font.DemiBold
            }
            StyledText {
                Layout.fillWidth: true
                visible: text !== ""
                text: row.subtitle
                font.pixelSize: Theme.fontSmall
                color: row.subtitleColor
            }
        }

        RowLayout {
            id: tail
            spacing: Theme.spacingS
        }
    }
}
