import QtQuick

// Button showing one centered MdIcon. Square by default; set implicitWidth
// and implicitHeight for other sizes. `icon` is the MdIcon (color, font).
Button {
    property alias codepoint: glyph.codepoint
    property alias icon: glyph

    implicitWidth: Theme.px(28)
    implicitHeight: implicitWidth

    MdIcon {
        id: glyph
        anchors.centerIn: parent
    }
}
