//@ pragma UseQApplication
import QtQuick
import Quickshell

// greetd greeter entry point. Runs under cage (extend mode) as the `greeter`
// user; cage maximizes this single toplevel over the whole output layout and
// Greeter.qml places the card on the detected main screen.
ShellRoot {
    FloatingWindow {
        color: "black"
        implicitWidth: 1280
        implicitHeight: 800
        Greeter { anchors.fill: parent }
    }
}
