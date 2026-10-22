import QtQuick
import QtQuick.Effects
import qs

// Aero: recessed text-field frame. Prominent fields (lock / login) get the
// dark well and the soft accent focus glow. `control` is the generic Field.
Item {
    Rectangle {
        anchors.fill: parent
        anchors.margins: -3
        visible: control.prominent
        radius: Theme.radius + 3
        color: "transparent"
        border.width: 3
        border.color: Theme.accent
        opacity: control.focused ? 0.55 : 0
        layer.enabled: control.prominent
        layer.effect: MultiEffect { blurEnabled: true; blur: 0.6; blurMax: 12 }
        Behavior on opacity { NumberAnimation { duration: Theme.durMedium } }
    }

    Rectangle {
        anchors.fill: parent
        radius: Theme.radius
        color: control.prominent ? Qt.rgba(0, 0, 0, 0.55) : Theme.inset
        border.width: 1
        border.color: control.focused ? Theme.accent : Qt.rgba(1, 1, 1, control.prominent ? 0.3 : 0.25)
        Behavior on border.color { ColorAnimation { duration: Theme.durShort } }
    }
}
