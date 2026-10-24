import QtQuick
import QtQuick.Effects
import qs

// Modern glow: a wide pastel accent halo around the lock / login clock.
MultiEffect {
    shadowEnabled: true
    shadowColor: Theme.color("glow", Theme.accent)
    shadowOpacity: 0.85
    shadowBlur: 1
    shadowHorizontalOffset: 0
    shadowVerticalOffset: 0
    blurMax: 56
}
