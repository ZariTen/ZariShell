import QtQuick
import QtQuick.Effects
import qs

// Modern: a glossy filled shape. The color runs from a lighter top to the
// base color, with a hairline light rim; orbs and default buttons also cast
// a soft colored glow. `control` is the generic Fill.
Item {
    Rectangle {
        anchors.fill: parent
        radius: Math.min(control.radius, height / 2)
        gradient: Gradient {
            GradientStop { position: 0.0; color: Qt.lighter(control.color, 1.12) }
            GradientStop { position: 1.0; color: Qt.darker(control.color, 1.25) }
        }
        border.width: 1
        border.color: control.bordered ? Theme.border : Qt.rgba(1, 1, 1, 0.12)

        layer.enabled: control.role !== "badge"
        layer.effect: MultiEffect {
            shadowEnabled: true
            shadowColor: control.color
            shadowOpacity: 0.55
            shadowBlur: 0.7
            shadowVerticalOffset: 2
            blurMax: 20
        }
    }
}
