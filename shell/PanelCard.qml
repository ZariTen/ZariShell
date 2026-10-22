import QtQuick

// Panel window/dialog card with an enter/exit animation (fade + scale + rise).
// `shown` drives it; `animating` keeps the window mapped until exit finishes.
Item {
    id: card

    property bool shown: false
    property alias radius: surface.radius
    property alias color: surface.color
    readonly property bool animating: opacity > 0

    anchors.centerIn: parent
    opacity: shown ? 1 : 0
    scale: shown ? 1 : 0.95
    anchors.verticalCenterOffset: shown ? 0 : 20

    Behavior on opacity { NumberAnimation { duration: Theme.durMedium; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.standard } }
    Behavior on scale { NumberAnimation { duration: Theme.durLong; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.emphasized } }
    Behavior on anchors.verticalCenterOffset { NumberAnimation { duration: Theme.durLong; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.emphasized } }

    Surface {
        id: surface
        anchors.fill: parent
        color: Theme.panel
        headerHeight: 44   // title-bar area
    }

    // Swallow clicks so the scrim behind doesn't close the panel.
    MouseArea {
        anchors.fill: parent
    }
}
