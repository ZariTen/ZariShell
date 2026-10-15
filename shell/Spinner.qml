import QtQuick

// Rotating busy glyph (md-loading). Hidden while `running` is false.
MdIcon {
    id: spinner

    property bool running: true

    codepoint: 0xF0772 // md-loading
    visible: running

    RotationAnimator on rotation {
        from: 0
        to: 360
        duration: 1000
        loops: Animation.Infinite
        running: spinner.running
    }
}
