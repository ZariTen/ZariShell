import QtQuick
import QtQuick.Layouts

// Glossy quick-settings toggle tile: icon, label, sublabel; glows when on.
AeroButton {
    id: tile

    property int codepoint: 0
    property string label: ""
    property string sublabel: ""
    property int trailingSpace: 0   // room reserved on the right (e.g. for a split chevron)

    Layout.fillWidth: true
    implicitHeight: 56
    alwaysFramed: true

    Rectangle {
        anchors.fill: parent
        anchors.margins: 1
        radius: tile.radius
        z: -1
        opacity: tile.active ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: Theme.durMedium } }
        gradient: Gradient {
            GradientStop { position: 0.0; color: Qt.rgba(Theme.glow.r, Theme.glow.g, Theme.glow.b, 0.45) }
            GradientStop { position: 0.5; color: Qt.rgba(Theme.glow.r, Theme.glow.g, Theme.glow.b, 0.2) }
            GradientStop { position: 1.0; color: Qt.rgba(Theme.glow.r, Theme.glow.g, Theme.glow.b, 0.3) }
        }
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: Theme.spacingM
        anchors.rightMargin: Theme.spacingS + tile.trailingSpace
        spacing: Theme.spacingS

        MdIcon {
            Layout.alignment: Qt.AlignVCenter
            codepoint: tile.codepoint
            font.pixelSize: 20
            color: tile.active ? "#ffffff" : Theme.textSurfaceVariant
        }
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0
            StyledText {
                Layout.fillWidth: true
                text: tile.label
                font.weight: Font.DemiBold
            }
            StyledText {
                Layout.fillWidth: true
                visible: text !== ""
                text: tile.sublabel
                font.pixelSize: Theme.fontSmall
                color: Theme.textSurfaceVariant
            }
        }
    }
}
