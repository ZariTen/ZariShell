import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Notifications
import Quickshell.Wayland

// Dropdown under the bar's bell: notification history, newest first.
Scope {
    id: root

    // -- State and derived properties ---------------------------------------
    readonly property bool open: ShellState.panel === "notifications"

    onOpenChanged: if (open) Notifs.markRead()

    // -- Visual tree --------------------------------------------------------
    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: window

            required property var modelData
            readonly property bool focusedHere: root.open && ShellState.isFocusedScreen(modelData)

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

            MouseArea {
                anchors.fill: parent
                onClicked: ShellState.close()
            }

            Rectangle {
                id: card

                readonly property bool shown: window.focusedHere

                anchors.right: parent.right
                anchors.rightMargin: Theme.gap
                y: Theme.barSpace + Theme.gap * 2 + (shown ? 0 : -16)
                width: Theme.widthPx(400)
                height: Math.min(window.height - y - Theme.gap * 4, column.implicitHeight + Theme.spacingL * 2)
                color: "transparent"
                opacity: shown ? 1 : 0
                focus: true
                Keys.onEscapePressed: ShellState.close()

                Behavior on opacity { NumberAnimation { duration: Theme.durMedium; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.standard } }
                Behavior on y { NumberAnimation { duration: Theme.durLong; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.emphasized } }
                Behavior on height { NumberAnimation { duration: Theme.durMedium; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.standard } }

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
                            implicitHeight: Theme.px(30)
                            onClicked: Notifs.clearAll()
                        }
                    }

                    // Empty state
                    Item {
                        Layout.fillWidth: true
                        implicitHeight: Theme.px(128)
                        visible: Notifs.history.length === 0

                        Column {
                            anchors.centerIn: parent
                            spacing: Theme.spacingS

                            Rectangle {
                                anchors.horizontalCenter: parent.horizontalCenter
                                implicitWidth: Theme.px(56)
                                implicitHeight: Theme.px(56)
                                radius: Theme.radiusFull
                                color: Theme.surfaceContainerHigh

                                MdIcon {
                                    anchors.centerIn: parent
                                    codepoint: 0xF009B // md-bell_off
                                    color: Theme.outline
                                    font.pixelSize: Theme.iconPx(26)
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
                            color: critical ? Theme.criticalContainer : Theme.surfaceContainer
                            border.width: 1
                            border.color: Theme.outlineFaint

                            HoverLayer {
                                radius: entry.radius
                                onClicked: {
                                    var action = Notifs.clickAction(entry.modelData);
                                    if (action)
                                        action.invoke();
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
                                    implicitWidth: Theme.px(36)
                                    implicitHeight: Theme.px(36)
                                    notification: entry.modelData
                                    critical: entry.critical
                                }

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: Theme.px(2)

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
                                            implicitWidth: Theme.px(20)
                                            implicitHeight: Theme.px(20)

                                            MdIcon {
                                                anchors.centerIn: parent
                                                codepoint: 0xF0156 // md-close
                                                font.pixelSize: Theme.iconPx(14)
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

            SystemClock {
                id: clock
                precision: SystemClock.Minutes
            }
        }
    }
}
