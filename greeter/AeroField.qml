import QtQuick
import QtQuick.Effects

// Dark inset text-field frame with the Aero focus glow (from LockSurface).
// Put a TextInput inside and point `input` at it.
Item {
    id: field
    default property alias content: holder.data
    property Item input
    readonly property bool focused: input ? input.activeFocus : false
    implicitHeight: 34

    Rectangle {
        anchors.fill: parent
        anchors.margins: -3
        radius: Theme.radius + 3
        color: "transparent"
        border.width: 3
        border.color: Theme.glow
        opacity: field.focused ? 0.55 : 0
        layer.enabled: true
        layer.effect: MultiEffect { blurEnabled: true; blur: 0.6; blurMax: 12 }
        Behavior on opacity { NumberAnimation { duration: Theme.durMedium } }
    }
    Rectangle {
        anchors.fill: parent
        radius: Theme.radius
        color: Qt.rgba(0, 0, 0, 0.55)
        border.width: 1
        border.color: field.focused ? Theme.glow : Qt.rgba(1, 1, 1, 0.3)
    }
    Item { id: holder; anchors.fill: parent }
}
