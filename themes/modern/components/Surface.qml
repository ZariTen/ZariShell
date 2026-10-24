import QtQuick
import QtQuick.Effects
import QtQuick.Window
import qs

// Modern: a dark rounded island with a hairline light edge, a faint accent
// sheen at the top and a soft drop shadow. An edge-to-edge strip (the bar,
// the lock / login bottom bars) is drawn as a floating pill inset from the
// screen edges instead. `control` is the generic Surface.
Item {
    id: look

    // Full-width and bar-high: this is an edge bar, so float it.
    readonly property bool floating: look.Window.width > 0 && width >= look.Window.width - 1 && height <= Theme.barHeight + 4
    readonly property int inset: look.floating ? Theme.px(Theme.metric("floatInset", 4)) : 0

    Rectangle {
        id: body
        anchors.fill: parent
        anchors.margins: look.inset
        radius: Math.min(control.radius, height / 2)
        color: control.color
        border.width: 1
        border.color: Theme.border

        layer.enabled: control.shadow || look.floating
        layer.effect: MultiEffect {
            shadowEnabled: true
            shadowColor: "#000000"
            shadowOpacity: 0.5
            shadowBlur: 0.9
            shadowVerticalOffset: 4
            blurMax: 32
        }
    }

    // Accent sheen over the top of the island (the title area when there is one).
    Rectangle {
        anchors.fill: body
        anchors.margins: 1
        radius: Math.max(0, body.radius - 1)
        gradient: Gradient {
            GradientStop { position: 0.0; color: Theme.color("sheen", [1, 1, 1, 0.06]) }
            GradientStop { position: control.headerHeight > 0 ? Math.min(0.9, control.headerHeight / Math.max(1, body.height)) : 0.5; color: "transparent" }
        }
    }
}
