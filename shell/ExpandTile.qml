import QtQuick
import QtQuick.Layouts

// Quick-settings tile split in two: the tile body toggles, the chevron on the
// right opens the matching sub-page (`expand()`).
Item {
    id: split

    property int codepoint: 0
    property string label: ""
    property string sublabel: ""
    property bool active: false
    signal clicked(var mouse)
    signal expand

    Layout.fillWidth: true
    implicitHeight: tile.implicitHeight
    opacity: enabled ? 1 : 0.5

    Tile {
        id: tile
        anchors.fill: parent
        codepoint: split.codepoint
        label: split.label
        sublabel: split.sublabel
        active: split.active
        trailingSpace: 36
        onClicked: mouse => split.clicked(mouse)
    }

    Rectangle {
        anchors.right: more.left
        anchors.rightMargin: Theme.spacingXs / 2
        anchors.verticalCenter: parent.verticalCenter
        width: 1
        height: parent.height - 22
        color: Qt.rgba(1, 1, 1, 0.22)
    }

    AeroButton {
        id: more
        anchors.right: parent.right
        anchors.rightMargin: Theme.spacingXs
        anchors.verticalCenter: parent.verticalCenter
        implicitWidth: 28
        implicitHeight: parent.height - 14
        onClicked: split.expand()

        MdIcon {
            anchors.centerIn: parent
            codepoint: 0xF0142 // md-chevron_right
        }
    }
}
