import QtQuick

// Glass window/dialog card with an enter/exit animation (fade + scale + rise).
// `shown` drives it; `animating` keeps the window mapped until exit finishes.
Item {
    id: card

    property bool shown: false
    property alias radius: glass.radius
    property alias tint: glass.tint
    readonly property bool animating: opacity > 0

    anchors.centerIn: parent
    opacity: shown ? 1 : 0
    scale: shown ? 1 : 0.95
    anchors.verticalCenterOffset: shown ? 0 : 20

    Behavior on opacity { NumberAnimation { duration: Theme.durMedium; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.standard } }
    Behavior on scale { NumberAnimation { duration: Theme.durLong; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.emphasized } }
    Behavior on anchors.verticalCenterOffset { NumberAnimation { duration: Theme.durLong; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.emphasized } }

    Glass {
        id: glass
        anchors.fill: parent
        tint: Theme.glassTintStrong
        sheenHeight: Math.min(0.48, 44 / Math.max(1, card.height))   // title-bar-like gloss band
    }

    // Swallow clicks so the scrim behind doesn't close the panel.
    MouseArea {
        anchors.fill: parent
    }
}
