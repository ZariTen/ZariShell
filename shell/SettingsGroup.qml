pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts

Item {
    id: group

    property var rows: []

    Layout.fillWidth: true
    implicitHeight: content.implicitHeight + Theme.spacingXs * 2
    visible: rows.length > 0

    Surface {
        anchors.fill: parent
        radius: Theme.radius
        color: Theme.surfaceContainer
        shadow: false
    }

    ColumnLayout {
        id: content
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.topMargin: Theme.spacingXs
        spacing: 0

        Repeater {
            model: group.rows
            delegate: SettingsRow {
                required property int index

                Divider {
                    visible: index > 0
                    anchors.top: parent.top
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.leftMargin: Theme.spacingM
                    anchors.rightMargin: Theme.spacingM
                }
            }
        }
    }
}
