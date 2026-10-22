import QtQuick
import QtQuick.Layouts

// A row of bar content. Plain (no surface of its own) since the taskbar
// strip is already a surface; `framed` gives it a recessed tray look.
Rectangle {
    default property alias content: row.data
    property alias spacing: row.spacing
    property bool framed: false
    readonly property int padding: framed ? Theme.spacingXs : 0

    implicitWidth: row.implicitWidth + padding * 2
    implicitHeight: Theme.barHeight - 10
    radius: Theme.radius
    color: framed ? Theme.inset : "transparent"
    border.width: framed ? 1 : 0
    border.color: Qt.rgba(1, 1, 1, 0.10)

    RowLayout {
        id: row
        anchors.centerIn: parent
        spacing: Theme.spacingXs
    }
}
