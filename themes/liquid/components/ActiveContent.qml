import QtQuick
import QtQuick.Effects
import qs

// Liquid Glass active content: the glyphs and text of an active button turn
// dark gray so they read on its solid white face (see Button.qml here).
MultiEffect {
    colorization: 1
    colorizationColor: Theme.color("activeGlyph", "#3a3a3c")
}
