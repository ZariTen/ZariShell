import QtQuick

// The shared Aero highlight: a soft tint rising from the bottom edge, with an
// optional 1px tinted border. Everything stays inside its own rounded rect (no
// blur), so hover/selection/active look the same on buttons, rows and tiles.
// `level` 0..1 scales the whole thing (animate it for smooth transitions).
Rectangle {
    id: fill

    property color tint: Theme.glowFill
    property real level: 1
    property bool bordered: false

    visible: level > 0.005
    color: "transparent"
    border.width: bordered ? 1 : 0
    border.color: Qt.rgba(tint.r, tint.g, tint.b, 0.5 * Math.min(1, level))
    gradient: Gradient {
        GradientStop { position: 0.0; color: Qt.rgba(fill.tint.r, fill.tint.g, fill.tint.b, 0.10 * fill.level) }
        GradientStop { position: 0.55; color: Qt.rgba(fill.tint.r, fill.tint.g, fill.tint.b, 0.14 * fill.level) }
        GradientStop { position: 1.0; color: Qt.rgba(fill.tint.r, fill.tint.g, fill.tint.b, 0.42 * fill.level) }
    }
}
