import QtQuick

// Generic slider / meter. `value` 0..1 is shown; `moved(value)` fires on click,
// drag and scroll, `released(value)` when a drag ends. `interactive: false`
// makes it a plain meter. `tone` picks the fill: "normal", "accent",
// "warning", "critical" or "muted". The look comes from
// Theme.component("Slider") and reads this item as `control`.
Item {
    id: control

    property real value: 0
    property bool interactive: true
    property string tone: "normal"
    readonly property real shown: drag.pressed ? drag.ratio : Math.max(0, Math.min(1, value))
    readonly property bool hovered: drag.containsMouse
    readonly property bool pressed: drag.pressed

    signal moved(real value)
    signal released(real value)

    implicitHeight: interactive ? 10 : 8

    Loader {
        anchors.fill: parent
        source: Theme.component("Slider")
    }

    MouseArea {
        id: drag
        property real ratio: 0
        anchors.fill: parent
        anchors.topMargin: Theme.px(-6)
        anchors.bottomMargin: Theme.px(-6)
        enabled: control.interactive
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        function ratioAt(mouseX) { return Math.max(0, Math.min(1, mouseX / width)); }
        onPressed: mouse => {
            ratio = ratioAt(mouse.x);
            control.moved(ratio);
        }
        onPositionChanged: mouse => {
            if (pressed) {
                ratio = ratioAt(mouse.x);
                control.moved(ratio);
            }
        }
        onReleased: mouse => control.released(ratioAt(mouse.x))
        onWheel: wheel => {
            var step = wheel.angleDelta.y > 0 ? 0.05 : -0.05;
            control.moved(Math.max(0, Math.min(1, control.value + step)));
        }
    }
}
