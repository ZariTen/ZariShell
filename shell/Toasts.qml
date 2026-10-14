import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Services.Notifications
import Quickshell.Wayland
import Quickshell.Widgets

Scope {
    id: root

    readonly property var live: Notifs.popups

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: toastWindow

            required property var modelData
            readonly property var monitor: Hyprland.monitorFor(modelData)
            readonly property bool showHere: {
                if (root.live.length === 0 || ShellState.panel === "notifications")
                    return false;
                if (Hyprland.focusedMonitor === null)
                    return modelData === Quickshell.screens[0];
                return monitor !== null && monitor.name === Hyprland.focusedMonitor.name;
            }

            screen: modelData
            visible: showHere
            color: "transparent"
            aboveWindows: true
            exclusionMode: ExclusionMode.Ignore

            anchors {
                top: true
                right: true
            }

            margins.top: Theme.barHeight + Theme.gap * 2
            margins.right: Theme.gap
            implicitWidth: 380
            implicitHeight: Math.max(1, column.implicitHeight)

            WlrLayershell.namespace: "shell-notification"

            Column {
                id: column
                width: parent.width
                spacing: Theme.spacingS

                move: Transition {
                    NumberAnimation { properties: "y"; duration: Theme.durMedium; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.emphasized }
                }

                Repeater {
                    model: ScriptModel { values: Notifs.popups }

                    delegate: Rectangle {
                        id: toast
                        required property var modelData
                        readonly property bool critical: modelData.urgency === NotificationUrgency.Critical

                        width: column.width
                        implicitHeight: content.implicitHeight + Theme.spacingL * 2
                        radius: Theme.radiusLarge
                        color: "transparent"

                        Glass {
                            anchors.fill: parent
                            tint: toast.critical ? Qt.rgba(0.42, 0.05, 0.04, 0.88) : Theme.glassTintStrong
                            sheenHeight: Math.min(0.48, 30 / Math.max(1, toast.height))
                        }

                        // Slide in from the right.
                        // Popup expiry only hides the toast; it stays in the notification center.
                        Timer {
                            id: expire
                            interval: 5000
                            running: !toast.critical
                            onTriggered: Notifs.expirePopup(toast.modelData)
                        }

                        transform: Translate { id: slide; x: 0 }
                        NumberAnimation on opacity { from: 0; to: 1; duration: Theme.durMedium }
                        Component.onCompleted: slideIn.start()
                        NumberAnimation {
                            id: slideIn
                            target: slide
                            property: "x"
                            from: 80
                            to: 0
                            duration: Theme.durLong
                            easing.type: Easing.BezierSpline
                            easing.bezierCurve: Theme.emphasized
                        }

                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            onEntered: expire.stop()
                            onExited: if (!toast.critical) expire.restart()
                            onClicked: {
                                if (toast.modelData.actions.length > 0)
                                    toast.modelData.actions[0].invoke();
                                else
                                    Notifs.dismiss(toast.modelData);
                            }
                        }

                        RowLayout {
                            id: content
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.top: parent.top
                            anchors.margins: Theme.spacingL
                            spacing: Theme.spacingM

                            NotifIcon {
                                Layout.alignment: Qt.AlignTop
                                notification: toast.modelData
                                critical: toast.critical
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 2

                                RowLayout {
                                    Layout.fillWidth: true
                                    StyledText {
                                        Layout.fillWidth: true
                                        text: Notifs.appLabel(toast.modelData)
                                        font.pixelSize: Theme.fontSmall
                                        color: toast.critical ? Theme.error : Theme.glow
                                    }
                                    MdIcon {
                                        codepoint: 0xF0156 // md-close
                                        font.pixelSize: 14
                                        color: Theme.textSurfaceVariant
                                        MouseArea {
                                            anchors.fill: parent
                                            anchors.margins: -4
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: Notifs.dismiss(toast.modelData)
                                        }
                                    }
                                }

                                StyledText {
                                    Layout.fillWidth: true
                                    visible: text !== ""
                                    text: toast.modelData.summary
                                    font.pixelSize: Theme.fontTitle - 1
                                    font.weight: Font.DemiBold
                                }

                                StyledText {
                                    Layout.fillWidth: true
                                    visible: text !== ""
                                    wrapMode: Text.WordWrap
                                    maximumLineCount: 4
                                    textFormat: Text.PlainText
                                    color: Theme.textSurfaceVariant
                                    text: toast.modelData.body
                                }

                                Flow {
                                    Layout.fillWidth: true
                                    Layout.topMargin: Theme.spacingS
                                    visible: toast.modelData.actions.length > 0
                                    spacing: Theme.spacingS

                                    Repeater {
                                        model: toast.modelData.actions
                                        delegate: ActionButton {
                                            required property var modelData
                                            text: modelData.text
                                            implicitHeight: 30
                                            onClicked: modelData.invoke()
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
}
