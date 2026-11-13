import QtQuick

Button {
    id: root

    required property var modelData
    readonly property bool occupied: modelData.toplevels.values.length > 0
    readonly property bool numbered: Theme.workspaceStyle === "numbers"

    implicitWidth: numbered ? Math.max(Theme.px(active ? 44 : 32), label.implicitWidth + Theme.spacingS * 2) : Theme.px(30)
    implicitHeight: Theme.px(30)
    active: modelData.active
    tint: modelData.urgent ? Theme.error : Theme.highlight
    restyleContent: !modelData.urgent
    onClicked: modelData.activate()

    Accessible.role: Accessible.Button
    Accessible.name: qsTr("Workspace %1").arg(modelData.name)
    Accessible.description: modelData.urgent ? "Urgent" : active ? "Active" : occupied ? "Occupied" : "Empty"
    Accessible.onPressAction: modelData.activate()

    Behavior on implicitWidth {
        NumberAnimation { duration: Theme.durMedium; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.emphasized }
    }

    // Urgency stays visible even when the theme ignores tint or restyles content.
    plainContent: Rectangle {
        objectName: "workspaceUrgency"
        visible: root.modelData.urgent
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.topMargin: Theme.px(4)
        anchors.rightMargin: Theme.px(4)
        width: Theme.px(7)
        height: width
        radius: height / 2
        color: Theme.error
        border.width: Math.max(1, Theme.px(1))
        border.color: Theme.surface
    }

    StyledText {
        id: label
        objectName: "workspaceLabel"
        anchors.centerIn: parent
        visible: root.numbered
        text: root.modelData.name
        color: root.modelData.urgent && !root.active ? Theme.error : Theme.textSurface
        font.weight: root.active ? Font.Bold : Font.Normal
        opacity: root.active || root.occupied || root.hovered || root.modelData.urgent ? 1 : Theme.dim(0.5)
    }

    Rectangle {
        objectName: "workspaceMarker"
        anchors.centerIn: parent
        visible: !root.numbered
        width: Theme.px(Theme.workspaceStyle === "pills" ? (root.active ? 22 : 12) : (root.active ? 10 : 7))
        height: Theme.workspaceStyle === "pills" ? Theme.px(6) : width
        radius: Theme.workspaceStyle === "diamonds" ? 0 : height / 2
        rotation: Theme.workspaceStyle === "diamonds" ? 45 : 0
        color: root.modelData.urgent && !root.active ? Theme.error : root.active ? Theme.accent : root.occupied ? Theme.textSurface : "transparent"
        border.width: root.active || root.occupied || root.modelData.urgent ? 0 : Math.max(1, Theme.px(1))
        border.color: Theme.outline
        opacity: root.active || root.occupied || root.hovered || root.modelData.urgent ? 1 : Theme.dim(0.5)
    }

    Rectangle {
        objectName: "workspaceOccupied"
        visible: root.numbered && root.occupied && !root.active
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: Theme.spacingXs
        width: Theme.px(10)
        height: Theme.px(2)
        radius: Theme.radiusFull
        color: root.modelData.urgent ? Theme.error : Theme.accent
    }
}
