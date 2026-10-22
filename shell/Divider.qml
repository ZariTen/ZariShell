import QtQuick

// Thin separator line. Size it like a Rectangle (implicit 1x1); `strong`
// asks for the more visible variant. Look: Theme.component("Divider").
Item {
    id: control

    property bool strong: false

    implicitWidth: 1
    implicitHeight: 1

    Loader {
        anchors.fill: parent
        source: Theme.component("Divider")
    }
}
