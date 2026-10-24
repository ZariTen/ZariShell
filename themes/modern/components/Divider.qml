import QtQuick
import QtQuick.Window
import qs

// Modern: a soft rounded rule. Hidden when it spans the whole screen (the
// bar's bottom edge), since the bar floats as a pill. `control` is the
// generic Divider.
Rectangle {
    id: look

    visible: !(look.Window.width > 0 && width >= look.Window.width - 1)
    radius: Math.min(width, height) / 2
    color: control.strong ? Theme.dividerStrong : Theme.divider
}
