import QtQuick

// Generic text-field frame. Put a TextInput inside and point `input` at it.
// `prominent` is for the main field of a screen (lock / login password). The
// look comes from Theme.component("Field") and reads this item as `control`.
Item {
    id: control

    default property alias content: holder.data
    property Item input
    property bool prominent: false
    readonly property bool focused: input ? input.activeFocus : false

    implicitHeight: Theme.px(34)

    Loader {
        anchors.fill: parent
        source: Theme.component("Field")
    }

    Item {
        id: holder
        anchors.fill: parent
    }
}
