import QtQuick

// Win7-style glossy slider (green fill, round thumb). `value` 0..1 is shown;
// `moved(v)` fires on click/drag/scroll. Set `interactive: false` for a meter.
Rectangle {
    id: slider

    property real value: 0
    property bool interactive: true
    property color fillTop: "#b6f39a"
    property color fillMid: "#4fc22a"
    property color fillDark: "#2f9e12"
    property color fillBottom: "#5fd23a"
    readonly property real shown: drag.pressed ? drag.ratio : Math.max(0, Math.min(1, value))
    signal moved(real v)

    implicitHeight: interactive ? 10 : 8
    radius: 2
    color: Qt.rgba(0, 0, 0, 0.5)
    border.width: 1
    border.color: Qt.rgba(1, 1, 1, 0.25)

    Rectangle {
        x: 1
        y: 1
        width: (parent.width - 2) * slider.shown
        height: parent.height - 2
        radius: 1
        Behavior on width { enabled: !drag.pressed; NumberAnimation { duration: Theme.durMedium; easing.type: Easing.OutCubic } }
        gradient: Gradient {
            GradientStop { position: 0.0; color: slider.fillTop }
            GradientStop { position: 0.45; color: slider.fillMid }
            GradientStop { position: 0.5; color: slider.fillDark }
            GradientStop { position: 1.0; color: slider.fillBottom }
        }
    }

    Rectangle {
        visible: slider.interactive
        x: Math.max(0, Math.min(parent.width - width, (parent.width - 2) * slider.shown - width / 2))
        anchors.verticalCenter: parent.verticalCenter
        width: 12
        height: 12
        radius: 6
        border.width: 1
        border.color: Theme.edgeDark
        scale: drag.containsMouse || drag.pressed ? 1.15 : 1
        Behavior on scale { NumberAnimation { duration: Theme.durShort } }
        gradient: Gradient {
            GradientStop { position: 0.0; color: "#ffffff" }
            GradientStop { position: 1.0; color: "#9fb7c9" }
        }
    }

    MouseArea {
        id: drag
        property real ratio: 0
        anchors.fill: parent
        anchors.topMargin: -6
        anchors.bottomMargin: -6
        enabled: slider.interactive
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        function ratioAt(x) { return Math.max(0, Math.min(1, x / width)); }
        onPressed: mouse => { ratio = ratioAt(mouse.x); slider.moved(ratio); }
        onPositionChanged: mouse => {
            if (pressed) {
                ratio = ratioAt(mouse.x);
                slider.moved(ratio);
            }
        }
        onWheel: wheel => slider.moved(Math.max(0, Math.min(1, slider.value + (wheel.angleDelta.y > 0 ? 0.05 : -0.05))))
    }
}
