import QtQuick
import QtQuick.Layouts

DropPanel {
    id: panel
    name: "tray"
    headerHeight: 0
    screen: ShellState.trayScreen || ShellState.focusedScreen()
    anchorCenter: ShellState.trayAnchorX
    cardWidth: apps.implicitWidth + Theme.spacingL * 2

    onOpenChanged: if (open) Qt.callLater(() => apps.forceActiveFocus())

    TrayItems {
        id: apps
        menuWindow: panel
        maximumWidth: Math.max(cellWidth, (panel.screen ? panel.screen.width : panel.width) - Theme.gap * 2 - Theme.spacingL * 2)
        Layout.fillWidth: true
        Layout.preferredHeight: Math.min(implicitHeight, Math.max(cellHeight, panel.height - Theme.barSpace - Theme.gap * 2 - Theme.spacingL * 2))
        onCountChanged: if (count === 0 && panel.open) ShellState.close()
    }
}
