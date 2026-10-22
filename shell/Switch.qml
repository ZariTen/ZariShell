import QtQuick

// Generic on/off switch. `checked` is what is shown; `toggled()` fires on
// click or Space, so the owner decides what actually changes. The look comes
// from Theme.component("Switch") and reads this item as `control`.
Item {
    id: control

    property bool checked: false
    readonly property bool hovered: mouse.containsMouse
    readonly property bool pressed: mouse.pressed
    signal toggled

    implicitWidth: Theme.px(42)
    implicitHeight: Theme.px(22)
    opacity: enabled ? 1 : Theme.dim(0.45)
    activeFocusOnTab: true
    Keys.onSpacePressed: control.toggled()
    Behavior on opacity { NumberAnimation { duration: Theme.durShort } }

    Loader {
        anchors.fill: parent
        source: Theme.component("Switch")
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        anchors.margins: Theme.px(-3)
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: control.toggled()
    }
}
