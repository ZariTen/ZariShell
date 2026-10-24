import QtQuick
import QtQuick.Effects
import qs

// Ink: ink bleeding softly into the paper around the lock / login clock.
MultiEffect {
    shadowEnabled: true
    shadowColor: Theme.textSurface
    shadowOpacity: 0.3
    shadowBlur: 0.3
    shadowHorizontalOffset: 1
    shadowVerticalOffset: 1
    blurMax: 12
}
