import QtQuick
import QtQuick.Effects

// Aero glass surface: tinted translucent body (Hyprland blurs behind it),
// glossy vertical gradient with a hard-edged sheen on the top half, a 1px
// light inner edge, a dark outer edge and a soft drop shadow.
// Children go on top of the glass.
Item {
    id: glass

    default property alias content: inner.data
    property real radius: Theme.radiusLarge
    property color tint: Theme.glassTint
    property bool shadow: true
    property real sheenHeight: 0.48   // fraction of height covered by the top gloss band

    Rectangle {
        id: body
        anchors.fill: parent
        radius: glass.radius
        color: glass.tint
        border.width: 1
        border.color: Theme.edgeDark

        layer.enabled: glass.shadow
        layer.effect: MultiEffect {
            shadowEnabled: true
            shadowColor: "#000000"
            shadowOpacity: 0.55
            shadowBlur: 0.8
            shadowVerticalOffset: 3
            blurMax: 24
        }
    }

    // Gloss: bright top band with a hard edge, gentle darkening at the bottom.
    Rectangle {
        anchors.fill: parent
        anchors.margins: 1
        radius: Math.max(0, glass.radius - 1)
        border.width: 1
        border.color: Theme.edgeLight
        gradient: Gradient {
            GradientStop { position: 0.0; color: Theme.sheenTop }
            GradientStop { position: glass.sheenHeight; color: Theme.sheenMid }
            GradientStop { position: glass.sheenHeight + 0.001; color: Qt.rgba(1, 1, 1, 0.0) }
            GradientStop { position: 1.0; color: Qt.rgba(0, 0, 0, 0.10) }
        }
    }

    Item {
        id: inner
        anchors.fill: parent
    }
}
