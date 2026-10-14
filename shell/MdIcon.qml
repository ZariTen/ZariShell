import QtQuick

// A Nerd Font Material Design glyph, given by codepoint.
StyledText {
    property int codepoint: 0
    font.family: Theme.iconFont
    text: codepoint > 0 ? Theme.icon(codepoint) : ""
    font.pixelSize: 16
    elide: Text.ElideNone
    horizontalAlignment: Text.AlignHCenter
}
