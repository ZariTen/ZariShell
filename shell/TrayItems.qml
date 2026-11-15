import QtQuick
import QtQuick.Controls as Controls
import Quickshell.Services.SystemTray
import Quickshell.Widgets

GridView {
    id: grid

    required property var menuWindow
    property real maximumWidth: Theme.px(200)
    readonly property int columns: Math.min(5, Math.max(1, Math.floor(maximumWidth / cellWidth)), Math.max(1, count))

    model: SystemTray.items
    implicitWidth: columns * cellWidth
    implicitHeight: Math.ceil(count / columns) * cellHeight
    cellWidth: Theme.px(40)
    cellHeight: Theme.px(40)
    clip: true
    boundsBehavior: Flickable.StopAtBounds
    keyNavigationEnabled: true
    activeFocusOnTab: true
    Controls.ScrollBar.vertical: Controls.ScrollBar {}

    delegate: Button {
        id: trayIcon
        required property var modelData
        required property int index
        width: grid.cellWidth
        height: grid.cellHeight
        active: GridView.isCurrentItem && grid.activeFocus
        restyleContent: false
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
        Accessible.role: Accessible.Button
        Accessible.name: modelData.title || modelData.id || qsTr("Tray app")
        Accessible.onPressAction: clicked({ button: Qt.LeftButton, x: width / 2, y: height / 2 })

        IconImage {
            anchors.centerIn: parent
            implicitSize: Theme.px(20)
            source: trayIcon.modelData.icon
        }

        onClicked: mouse => {
            grid.currentIndex = index;
            var menuPos = trayIcon.mapToItem(grid.menuWindow.contentItem, mouse.x, mouse.y);
            if (modelData.hasMenu && (mouse.button === Qt.RightButton || modelData.onlyMenu)) {
                modelData.display(grid.menuWindow, menuPos.x, menuPos.y);
            } else {
                if (mouse.button === Qt.MiddleButton)
                    modelData.secondaryActivate();
                else
                    modelData.activate();
                ShellState.close();
            }
        }
        onWheel: wheel => modelData.scroll(wheel.angleDelta.y, false)

        Controls.ToolTip.visible: hovered
        Controls.ToolTip.delay: 600
        Controls.ToolTip.text: Accessible.name
    }

    Keys.onReturnPressed: if (currentItem) currentItem.clicked({ button: Qt.LeftButton, x: currentItem.width / 2, y: currentItem.height / 2 })
    Keys.onEnterPressed: if (currentItem) currentItem.clicked({ button: Qt.LeftButton, x: currentItem.width / 2, y: currentItem.height / 2 })
    Keys.onMenuPressed: if (currentItem) currentItem.clicked({ button: Qt.RightButton, x: currentItem.width / 2, y: currentItem.height / 2 })
}
