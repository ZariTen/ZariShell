import QtQuick
import QtQuick.Layouts

// A row of bar content. Plain (no surface of its own) since the taskbar
// strip is already glass; `framed` gives it a recessed Win7 tray look.
Rectangle {
    default property alias content: row.data
    property alias spacing: row.spacing
    property bool framed: false

    implicitWidth: row.implicitWidth + (framed ? Theme.spacingM * 2 : 0)
    implicitHeight: Theme.barHeight - 10
    radius: Theme.radius
    color: framed ? Qt.rgba(0, 0, 0, 0.22) : "transparent"
    border.width: framed ? 1 : 0
    border.color: Qt.rgba(1, 1, 1, 0.10)

    RowLayout {
        id: row
        anchors.centerIn: parent
        spacing: Theme.spacingS
    }
}
