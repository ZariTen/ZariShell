import QtQuick
import QtQuick.Layouts

// Device or network list for a quick settings page. Up/Down move `cursor`
// and Return/Enter emit activated() with the row under it. Rows fade in and
// out, and slide when displaced.
ListView {
    id: list

    property bool keyActive: false
    property int cursor: -1   // row under the mouse or keyboard

    signal activated(Item row)

    function step(by) {
        keyActive = true;
        cursor = Math.max(0, Math.min(count - 1, cursor + by));
        positionViewAtIndex(cursor, ListView.Contain);
    }

    function activateCursor() {
        if (itemAtIndex(cursor))
            activated(itemAtIndex(cursor));
    }

    Layout.fillWidth: true
    clip: true
    spacing: Theme.px(2)
    boundsBehavior: Flickable.StopAtBounds

    Keys.onUpPressed: step(-1)
    Keys.onDownPressed: step(1)
    Keys.onReturnPressed: activateCursor()
    Keys.onEnterPressed: activateCursor()

    add: Transition {
        NumberAnimation { property: "opacity"; from: 0; to: 1; duration: Theme.durMedium }
    }
    remove: Transition {
        NumberAnimation { property: "opacity"; to: 0; duration: Theme.durShort }
    }
    displaced: Transition {
        NumberAnimation { property: "y"; duration: Theme.durMedium; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.emphasized }
    }
}
