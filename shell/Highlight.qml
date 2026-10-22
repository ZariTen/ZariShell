import QtQuick

// Generic hover / selection / active highlight, shared by buttons, rows and
// tiles. `level` 0..1 scales it (animate it for smooth transitions),
// `bordered` adds a tinted 1px edge. The look comes from
// Theme.component("Highlight") and reads this item as `control`.
Item {
    id: control

    property color tint: Theme.highlight
    property real level: 1
    property bool bordered: false
    property real radius: Theme.radius

    visible: level > 0.005

    Loader {
        anchors.fill: parent
        source: Theme.component("Highlight")
    }
}
