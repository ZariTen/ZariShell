import QtQuick
import QtQuick.Effects

// Liquid Glass glow: a soft shadow under the lock / login clock, so the
// white digits stay readable over bright wallpapers.
MultiEffect {
    shadowEnabled: true
    shadowColor: "#000000"
    shadowOpacity: 0.35
    shadowBlur: 0.8
    shadowHorizontalOffset: 0
    shadowVerticalOffset: 2
    blurMax: 32
}
