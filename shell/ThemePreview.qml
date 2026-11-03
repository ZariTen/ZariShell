import QtQuick

// Tiny mock desktop for the theme picker, drawn from a theme.json's own
// colors and shapes: its surface, bar and a panel with text in the theme's
// font and a highlight button. Bar size and style are the user's (the same
// in every theme). Fallbacks match Theme.qml defaults.
Rectangle {
    id: root

    required property var spec

    // Real sizes are scaled down; radii a little less, so shape stays visible.
    readonly property real sizeScale: 0.2
    readonly property real radiusScale: 0.4

    readonly property bool pills: Theme.barPills
    readonly property bool floating: Theme.barFloating
    readonly property int barHeight: Math.max(Theme.px(6), Math.round(Theme.barHeight * sizeScale))
    readonly property int barInset: floating ? Theme.px(3) : 0

    function value(sectionName, key, fallbackValue) {
        return Theme.specValue(spec, sectionName, key, fallbackValue);
    }

    function metric(key, fallbackValue) {
        var rawValue = value("metrics", key, fallbackValue);
        return typeof rawValue === "number" ? rawValue : fallbackValue;
    }

    function shapeRadius(key, fallbackValue, itemHeight) {
        return Math.min(Theme.px(metric(key, fallbackValue) * radiusScale), itemHeight / 2);
    }

    function tint(key, fallbackValue) {
        return Theme.specColor(spec, key, fallbackValue);
    }

    implicitWidth: Theme.px(76)
    implicitHeight: Theme.px(48)
    radius: Math.min(Theme.radiusSmall, Theme.px(4))
    clip: true
    color: tint("surface", "#24282e")
    border.width: 1
    border.color: Theme.outlineVariant

    // Bar: one strip, or a pill per group in the Pills bar style.
    Repeater {
        model: root.pills ? [[0, 0.4], [0.7, 0.3]] : [[0, 1]]

        Rectangle {
            required property var modelData
            readonly property real span: root.width - root.barInset * 2
            x: root.barInset + span * modelData[0]
            y: root.barInset
            width: span * modelData[1]
            height: root.barHeight
            radius: root.floating ? Math.max(root.shapeRadius("barRadius", 0, height), root.shapeRadius("radiusLarge", 8, height)) : 0
            color: root.tint("bar", [0.21, 0.23, 0.26, 0.92])
            border.width: 1
            border.color: root.tint("border", [0, 0, 0, 0.35])

            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                x: Math.max(Theme.px(3), parent.radius / 2)
                width: Theme.px(4)
                height: width
                radius: width / 2
                color: root.tint("accent", "accent")
            }
        }
    }

    // Panel with a line of text and a highlighted button.
    Rectangle {
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: Theme.px(4)
        width: Theme.px(46)
        height: Theme.px(28)
        radius: root.shapeRadius("radiusLarge", 8, height)
        color: root.tint("panel", [0.24, 0.26, 0.30, 0.96])
        border.width: 1
        border.color: root.tint("border", [0, 0, 0, 0.35])

        Text {
            x: Theme.px(5)
            y: Theme.px(3)
            text: "Aa"
            color: root.tint("textSurface", "#ffffff")
            font.family: root.value("fonts", "font", "sans-serif")
            font.pixelSize: Theme.px(10)
        }

        Rectangle {
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.margins: Theme.px(4)
            width: Theme.px(18)
            height: Theme.px(7)
            radius: root.shapeRadius("radius", 5, height)
            color: root.tint("highlight", "accent")
        }
    }
}
