import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Services.Notifications
import Quickshell.Wayland
import Quickshell.Widgets

// Dropdown under the bar's bell: notification history, newest first.
Scope {
    id: root

    readonly property bool open: ShellState.panel === "notifications"

    onOpenChanged: if (open) Notifs.markRead()

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: window

            required property var modelData
            readonly property var monitor: Hyprland.monitorFor(modelData)
            readonly property bool focusedHere: {
                if (!root.open)
                    return false;
                if (Hyprland.focusedMonitor === null)
                    return modelData === Quickshell.screens[0];
                return monitor !== null && monitor.name === Hyprland.focusedMonitor.name;
            }

            screen: modelData
            visible: focusedHere || card.opacity > 0
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

            onFocusedHereChanged: if (focusedHere) card.forceActiveFocus()

            SystemClock {
                id: clock
                precision: SystemClock.Minutes
            }

            MouseArea {
                anchors.fill: parent
                onClicked: ShellState.close()
            }

            Rectangle {
                id: card

                readonly property bool shown: window.focusedHere

                anchors.right: parent.right
                anchors.rightMargin: Theme.gap
                y: Theme.barHeight + Theme.gap * 2 + (shown ? 0 : -16)
                width: 400
                height: Math.min(window.height - y - Theme.gap * 4, column.implicitHeight + Theme.spacingL * 2)
                color: "transparent"
                opacity: shown ? 1 : 0
                focus: true
                Keys.onEscapePressed: ShellState.close()

                Behavior on opacity { NumberAnimation { duration: Theme.durMedium; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.standard } }
                Behavior on y { NumberAnimation { duration: Theme.durLong; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.emphasized } }
                Behavior on height { NumberAnimation { duration: Theme.durMedium; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.standard } }

                Glass {
                    anchors.fill: parent
                    tint: Theme.glassTintStrong
                    sheenHeight: Math.min(0.48, 44 / Math.max(1, card.height))
                }

                MouseArea {
                    anchors.fill: parent
                }

                ColumnLayout {
                    id: column
                    anchors.fill: parent
                    anchors.margins: Theme.spacingL
                    spacing: Theme.spacingM

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: Theme.spacingM

                        StyledText {
                            Layout.fillWidth: true
                            text: "Notifications"
                            font.pixelSize: Theme.fontTitle + 2
                            font.weight: Font.Bold
                        }

                        ActionButton {
                            visible: Notifs.history.length > 0
                            text: "Clear all"
                            implicitHeight: 30
                            onClicked: Notifs.clearAll()
                        }
                    }

                    // Empty state
                    Item {
                        Layout.fillWidth: true
                        implicitHeight: 128
                        visible: Notifs.history.length === 0

                        Column {
                            anchors.centerIn: parent
                            spacing: Theme.spacingS

                            Rectangle {
                                anchors.horizontalCenter: parent.horizontalCenter
                                implicitWidth: 56
                                implicitHeight: 56
                                radius: Theme.radiusFull
                                color: Theme.surfaceContainerHigh

                                MdIcon {
                                    anchors.centerIn: parent
                                    codepoint: 0xF009B // md-bell_off
                                    color: Theme.outline
                                    font.pixelSize: 26
                                }
                            }

                            StyledText {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: "You're all caught up"
                                color: Theme.textSurfaceVariant
                        }
                        }
                    }

                    ListView {
                        id: list
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        Layout.preferredHeight: contentHeight
                        visible: count > 0
                        clip: true
                        spacing: Theme.spacingS
                        boundsBehavior: Flickable.StopAtBounds
                        model: ScriptModel { values: Notifs.history }

                        add: Transition {
                            NumberAnimation { property: "opacity"; from: 0; to: 1; duration: Theme.durMedium }
                        }
                        remove: Transition {
                            NumberAnimation { property: "opacity"; to: 0; duration: Theme.durShort }
                        }
                        displaced: Transition {
                            NumberAnimation { property: "y"; duration: Theme.durMedium; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.emphasized }
                        }

                        delegate: Rectangle {
                            id: entry
                            required property var modelData
                            readonly property bool critical: modelData.urgency === NotificationUrgency.Critical

                            width: ListView.view.width
                            implicitHeight: row.implicitHeight + Theme.spacingM * 2
                            radius: Theme.radius
                            color: critical ? Qt.rgba(0.70, 0.18, 0.12, 0.40) : Theme.surfaceContainer
                            border.width: 1
                            border.color: Qt.rgba(1, 1, 1, 0.08)

                            HoverLayer {
                                radius: entry.radius
                                onClicked: {
                                    if (entry.modelData.actions.length > 0)
                                        entry.modelData.actions[0].invoke();
                                }
                            }

                            RowLayout {
                                id: row
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.top: parent.top
                                anchors.margins: Theme.spacingM
                                spacing: Theme.spacingM

                                NotifIcon {
                                    Layout.alignment: Qt.AlignTop
                                    implicitWidth: 36
                                    implicitHeight: 36
                                    notification: entry.modelData
                                    critical: entry.critical
                                }

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 2

                                    RowLayout {
                                        Layout.fillWidth: true
                                        spacing: Theme.spacingS

                                        StyledText {
                                            Layout.fillWidth: true
                                            text: Notifs.appLabel(entry.modelData)
                                            font.pixelSize: Theme.fontSmall
                                            color: entry.critical ? Theme.error : Theme.primary
                                        }
                                        StyledText {
                                            text: Notifs.relativeTime(Notifs.timeOf(entry.modelData), clock.date)
                                            font.pixelSize: Theme.fontSmall
                                            color: Theme.outline
                                        }
                                        Item {
                                            implicitWidth: 20
                                            implicitHeight: 20

                                            MdIcon {
                                                anchors.centerIn: parent
                                                codepoint: 0xF0156 // md-close
                                                font.pixelSize: 14
                                                color: Theme.textSurfaceVariant
                                            }
                                            HoverLayer {
                                                onClicked: Notifs.dismiss(entry.modelData)
                                            }
                                        }
                                    }

                                    StyledText {
                                        Layout.fillWidth: true
                                        visible: text !== ""
                                        text: entry.modelData.summary
                                        font.weight: Font.DemiBold
                                    }

                                    StyledText {
                                        Layout.fillWidth: true
                                        visible: text !== ""
                                        wrapMode: Text.WordWrap
                                        maximumLineCount: 3
                                        textFormat: Text.PlainText
                                        color: Theme.textSurfaceVariant
                                        font.pixelSize: Theme.fontSmall + 1
                                        text: entry.modelData.body
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
