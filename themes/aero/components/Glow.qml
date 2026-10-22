import QtQuick
import QtQuick.Effects
import qs

// Aero glow: soft accent halo around the lock / login clock.
MultiEffect {
    shadowEnabled: true
    shadowColor: Theme.accent
    shadowOpacity: 0.6
    shadowBlur: 1
    shadowHorizontalOffset: 0
    shadowVerticalOffset: 0
    blurMax: 40
}
