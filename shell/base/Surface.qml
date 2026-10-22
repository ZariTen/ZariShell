import QtQuick
import QtQuick.Effects
import qs

// Neutral flat surface: solid translucent body, 1px edge, soft shadow.
// `control` is the generic Surface.
Rectangle {
    radius: control.radius
    color: control.color
    border.width: 1
    border.color: Theme.borderLight

    layer.enabled: control.shadow
    layer.effect: MultiEffect {
        shadowEnabled: true
        shadowColor: "#000000"
        shadowOpacity: 0.35
        shadowBlur: 0.6
        shadowVerticalOffset: 2
        blurMax: 16
    }
}
