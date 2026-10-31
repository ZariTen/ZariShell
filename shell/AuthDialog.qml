import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Polkit
import Quickshell.Wayland

Scope {
    // -- Visual tree --------------------------------------------------------
    PanelWindow {
        id: window

        readonly property bool active: agent.isActive && agent.flow !== null

        screen: Quickshell.screens[0]
        visible: active || card.animating
        color: "transparent"
        aboveWindows: true
        exclusionMode: ExclusionMode.Ignore

        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }

        WlrLayershell.namespace: "shell-polkit"
        WlrLayershell.keyboardFocus: active ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

        onActiveChanged: {
            if (active)
                secret.forceActiveFocus();
        }

        function submit() {
            if (agent.flow)
                agent.flow.submit(secret.text);
            secret.text = "";
        }

        function cancel() {
            if (agent.flow)
                agent.flow.cancelAuthenticationRequest();
        }

        Rectangle {
            anchors.fill: parent
            color: Theme.scrimStrong
            opacity: card.shown ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: Theme.durMedium } }
        }

        PanelCard {
            id: card
            shown: window.active
            width: Theme.widthPx(420)
            height: column.implicitHeight + Theme.spacingXl * 2

            ColumnLayout {
                id: column
                anchors.fill: parent
                anchors.margins: Theme.spacingXl
                spacing: Theme.spacingM

                StyledText {
                    Layout.fillWidth: true
                    Layout.topMargin: -Theme.spacingS
                    text: "User Account Control"
                    color: Theme.textSurfaceVariant
                    font.pixelSize: Theme.fontSmall
                }

                Item {
                    Layout.alignment: Qt.AlignHCenter
                    implicitWidth: Theme.px(52)
                    implicitHeight: Theme.px(52)

                    MdIcon {

                        anchors.centerIn: parent
                        codepoint: 0xF0780 // md-shield_half_full (UAC shield)
                        color: Theme.warning
                        font.pixelSize: Theme.iconPx(26)
                    }
                }

                StyledText {
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignHCenter
                    text: "Do you want to allow this action?"
                    font.pixelSize: Theme.fontHeadline - 2
                    font.weight: Font.Bold
                }

                StyledText {
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.WordWrap
                    color: Theme.textSurfaceVariant
                    text: agent.flow ? agent.flow.message : ""
                }

                StyledText {
                    Layout.fillWidth: true
                    visible: agent.flow !== null && agent.flow.supplementaryMessage !== ""
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.WordWrap
                    font.pixelSize: Theme.fontSmall
                    color: agent.flow !== null && agent.flow.supplementaryIsError ? Theme.error : Theme.textSurfaceVariant
                    text: agent.flow ? agent.flow.supplementaryMessage : ""
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.topMargin: Theme.spacingS
                    visible: agent.flow !== null && agent.flow.isResponseRequired
                    implicitHeight: Theme.px(48)
                    radius: Theme.radius
                    color: Theme.surfaceContainerHigh
                    border.width: secret.activeFocus ? 2 : 1
                    border.color: secret.activeFocus ? Theme.primary : Theme.outlineVariant

                    TextInput {
                        id: secret
                        anchors.fill: parent
                        anchors.leftMargin: Theme.spacingL
                        anchors.rightMargin: Theme.spacingL
                        verticalAlignment: TextInput.AlignVCenter
                        echoMode: agent.flow !== null && agent.flow.responseVisible ? TextInput.Normal : TextInput.Password
                        passwordCharacter: "\u2022"
                        color: Theme.textSurface
                        font.family: Theme.font
                        font.pixelSize: Theme.fontTitle
                        clip: true
                        onAccepted: window.submit()
                        Keys.onEscapePressed: window.cancel()

                        StyledText {
                            anchors.fill: parent
                            visible: secret.text === ""
                            color: Theme.outline
                            text: agent.flow ? agent.flow.inputPrompt : ""
                        }
                    }
                }

                RowLayout {
                    Layout.alignment: Qt.AlignRight
                    Layout.topMargin: Theme.spacingS
                    spacing: Theme.spacingS

                    ActionButton {
                        text: "Cancel"
                        onClicked: window.cancel()
                    }

                    ActionButton {
                        text: "Authenticate"
                        filled: true
                        onClicked: window.submit()
                    }
                }
            }
        }
    }

    // -- Background objects -------------------------------------------------
    PolkitAgent {
        id: agent
    }
}
