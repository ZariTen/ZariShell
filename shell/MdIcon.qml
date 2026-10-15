import QtQuick

// A Nerd Font Material Design glyph, given by codepoint. The item is a square
// box (font.pixelSize on each side) with the glyph centered in it, so it lines
// up predictably in buttons, tiles and rows (anchors.centerIn or layouts).
//
// Uses the Propo family: its advance width is the glyph's own width, so the
// ink is horizontally centered (the plain family keeps a monospace advance
// that the wider icons overflow, and the Mono family shrinks them). Nerd Font
// icons are vertically centered on the line box, which the Text is centered by.
Item {
    id: icon

    property int codepoint: 0
    property alias color: glyph.color
    property alias font: glyph.font

    implicitWidth: glyph.font.pixelSize
    implicitHeight: glyph.font.pixelSize

    StyledText {
        id: glyph
        x: Math.round((icon.width - width) / 2)
        y: Math.round((icon.height - height) / 2)
        font.family: Theme.iconFont
        font.pixelSize: 16
        text: icon.codepoint > 0 ? Theme.icon(icon.codepoint) : ""
        elide: Text.ElideNone
    }
}
