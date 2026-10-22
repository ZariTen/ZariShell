import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Widgets

Scope {
    id: root

    property var files: []

    function refresh() {
        listing.running = true;
    }

    function select(path) {
        Wallpaper.path = path;
        store.setText(path + "\n");
        ShellState.close();
    }

    FileView {
        id: store
        path: Quickshell.statePath("wallpaper")
        printErrors: false
        onLoaded: {
            var saved = text().trim();
            if (saved !== "")
                Wallpaper.path = saved;
        }
    }

    Process {
        id: listing
        command: ["ls", "-1", Wallpaper.dir]
        stdout: StdioCollector {
            onStreamFinished: {
                var names = text.trim() === "" ? [] : text.trim().split("\n");
                var images = [];
                for (var i = 0; i < names.length; i++) {
                    if (/\.(png|jpe?g|webp)$/i.test(names[i]))
                        images.push(Wallpaper.dir + "/" + names[i]);
                }
                images.sort();
                root.files = images;
            }
        }
    }

    Connections {
        target: ShellState
        function onPanelChanged() {
            if (ShellState.panel === "wallpaper")
                root.refresh();
        }
    }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: window

            required property var modelData
            readonly property var monitor: Hyprland.monitorFor(modelData)
            readonly property bool focusedHere: {
                if (ShellState.panel !== "wallpaper")
                    return false;
                if (Hyprland.focusedMonitor === null)
                    return modelData === Quickshell.screens[0];
                return monitor !== null && monitor.name === Hyprland.focusedMonitor.name;
            }

            screen: modelData
            visible: focusedHere || card.animating
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
            WlrLayershell.keyboardFocus: focusedHere ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

            onFocusedHereChanged: {
                if (focusedHere)
                    grid.forceActiveFocus();
            }

            Rectangle {
                anchors.fill: parent
                color: Theme.scrim
                opacity: card.shown ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: Theme.durMedium } }
            }

            MouseArea {
                anchors.fill: parent
                onClicked: ShellState.close()
            }

            PanelCard {
                id: card
                shown: window.focusedHere
                width: Math.min(window.width - 80, 1000)
                height: Math.min(window.height - 140, 640)

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: Theme.spacingXl
                    spacing: Theme.spacingL

                    RowLayout {
                        spacing: Theme.spacingM

                        Rectangle {
                            implicitWidth: Theme.px(40)
                            implicitHeight: Theme.px(40)
                            radius: Theme.radiusFull
                            color: Theme.primaryContainer

                            MdIcon {
                                anchors.centerIn: parent
                                codepoint: 0xF02E9
                                color: Theme.textPrimaryContainer
                                font.pixelSize: Theme.iconPx(20)
                            }
                        }

                        ColumnLayout {
                            spacing: 0
                            StyledText {
                                text: "Wallpapers"
                                font.pixelSize: Theme.fontHeadline
                                font.weight: Font.Bold
                            }
                            StyledText {
                                text: root.files.length + " images · colors follow the wallpaper"
                                font.pixelSize: Theme.fontSmall
                                color: Theme.textSurfaceVariant
                            }
                        }
                    }

                    GridView {
                        id: grid
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        clip: true
                        focus: true
                        boundsBehavior: Flickable.StopAtBounds
                        cellWidth: Math.floor(width / Math.max(1, Math.floor(width / 236)))
                        cellHeight: Theme.px(156)
                        model: root.files
                        keyNavigationEnabled: true
                        Keys.onEscapePressed: ShellState.close()
                        Keys.onReturnPressed: if (currentIndex >= 0) root.select(root.files[currentIndex])

                        delegate: Item {
                            id: tile
                            required property int index
                            required property string modelData
                            readonly property bool selected: modelData === Wallpaper.path
                            readonly property bool hot: hover.containsMouse || GridView.isCurrentItem && grid.activeFocus

                            width: grid.cellWidth
                            height: grid.cellHeight

                            ClippingRectangle {
                                anchors.fill: parent
                                anchors.margins: Theme.px(6)
                                radius: tile.selected ? Theme.radiusLarge : Theme.radius
                                color: Theme.surfaceContainerHigh
                                border.width: tile.selected ? 3 : (tile.hot ? 2 : 0)
                                border.color: tile.selected ? Theme.primary : Theme.outline
                                scale: tile.hot ? 1.03 : 1

                                Behavior on scale { NumberAnimation { duration: Theme.durMedium; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.emphasized } }
                                Behavior on radius { NumberAnimation { duration: Theme.durMedium } }

                                Image {
                                    anchors.fill: parent
                                    fillMode: Image.PreserveAspectCrop
                                    asynchronous: true
                                    sourceSize.width: 440
                                    sourceSize.height: 260
                                    source: Theme.fileUrl(tile.modelData)
                                    opacity: status === Image.Ready ? 1 : 0
                                    Behavior on opacity { NumberAnimation { duration: Theme.durMedium } }
                                }

                                Rectangle {
                                    visible: tile.selected
                                    anchors.right: parent.right
                                    anchors.top: parent.top
                                    anchors.margins: Theme.spacingS
                                    width: Theme.px(26)
                                    height: Theme.px(26)
                                    radius: Theme.radiusFull
                                    color: Theme.primary

                                    MdIcon {
                                        anchors.centerIn: parent
                                        codepoint: 0xF012C // md-check
                                        color: Theme.textPrimary
                                        font.pixelSize: Theme.iconPx(14)
                                    }
                                }
                            }

                            MouseArea {
                                id: hover
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.select(tile.modelData)
                            }
                        }
                    }
                }
            }
        }
    }
}
