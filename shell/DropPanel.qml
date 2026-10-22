import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland

// Generic drop-down panel on the focused monitor, opened via ShellState.panel.
// align: "left" | "center" | "right" drops it under the bar; centered: true
// makes it a dimmed, centered dialog. Children go into a ColumnLayout.
PanelWindow {
    id: panel

    property string name
    property string align: "right"
    property bool centered: false
    property int cardWidth: Theme.widthPx(360)
    property bool canGoBack: false   // Escape steps back (signal back) instead of closing
    default property alias content: column.data
    readonly property bool open: ShellState.panel === name
    property alias spacing: column.spacing
    signal back

    screen: {
        var all = Quickshell.screens;
        var focused = Hyprland.focusedMonitor;
        for (var i = 0; focused && i < all.length; i++) {
            if (all[i].name === focused.name)
                return all[i];
        }
        return all[0];
    }
    visible: open || card.opacity > 0
    color: "transparent"
    aboveWindows: true
    exclusionMode: ExclusionMode.Ignore

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    WlrLayershell.namespace: "shell-panel"
    WlrLayershell.keyboardFocus: open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    onOpenChanged: if (open) card.forceActiveFocus()

    Rectangle {
        anchors.fill: parent
        visible: panel.centered
        color: Theme.scrim
        opacity: panel.open ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: Theme.durMedium } }
    }

    MouseArea {
        anchors.fill: parent
        onClicked: ShellState.close()
    }

    Item {
        id: card

        readonly property real restY: panel.centered ? (panel.height - height) / 2 : Theme.barHeight + Theme.gap

        x: panel.align === "left" ? Theme.gap : (panel.align === "center" || panel.centered ? (panel.width - width) / 2 : panel.width - width - Theme.gap)
        y: restY + (panel.open ? 0 : -14)
        width: panel.cardWidth
        height: column.implicitHeight + Theme.spacingL * 2
        opacity: panel.open ? 1 : 0
        scale: panel.centered ? (panel.open ? 1 : 0.95) : 1
        focus: true
        Keys.onEscapePressed: panel.canGoBack ? panel.back() : ShellState.close()

        Behavior on opacity { NumberAnimation { duration: Theme.durMedium; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.standard } }
        Behavior on height { NumberAnimation { duration: Theme.durMedium; easing.type: Easing.OutCubic } }
        Behavior on y { NumberAnimation { duration: Theme.durLong; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.emphasized } }
        Behavior on scale { NumberAnimation { duration: Theme.durLong; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.emphasized } }

        Surface {
            anchors.fill: parent
            color: Theme.panel
            headerHeight: Theme.px(44)
        }

        MouseArea {
            anchors.fill: parent
        }

        ColumnLayout {
            id: column
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: Theme.spacingL
            spacing: Theme.spacingM
        }
    }
}
