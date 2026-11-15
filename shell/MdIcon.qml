import QtQuick

// A Nerd Font Material Design glyph, given by codepoint. The item is a square
// box (font.pixelSize on each side) with the glyph centered in it, so it lines
// up predictably in buttons, tiles and rows (anchors.centerIn or layouts).
//
// Center the visible ink, not the font's advance or line box. Their bearings
// and rounded dimensions can otherwise shift small glyphs off center.
Item {
    id: icon

    property int codepoint: 0
    property alias color: glyph.color
    property alias font: glyph.font

    implicitWidth: glyph.font.pixelSize
    implicitHeight: glyph.font.pixelSize

    TextMetrics {
        id: metrics
        font: glyph.font
        text: glyph.text
    }

    StyledText {
        id: glyph
        x: (icon.width - metrics.tightBoundingRect.width) / 2 - metrics.tightBoundingRect.x
        y: (icon.height - metrics.tightBoundingRect.height) / 2 - metrics.tightBoundingRect.y - baselineOffset
        font.family: Theme.iconFont
        font.pixelSize: Theme.iconPx(16)
        text: icon.codepoint > 0 ? Theme.icon(icon.codepoint) : ""
        elide: Text.ElideNone
    }
}
