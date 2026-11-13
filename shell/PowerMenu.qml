import QtQuick
import QtQuick.Layouts
import Quickshell

// Shutdown dialog. Lock and Suspend run at once; Log out,
// Restart and Shut down ask for confirmation first.
Scope {
    id: root

    // -- State and action definitions ---------------------------------------
    property string pending: ""   // action awaiting confirmation
    // Lock has no command: it goes through ShellState.lockRequested().
    readonly property var actions: [
        { id: "lock", label: qsTr("Lock"), glyph: 0xF033E, confirm: false },
        { id: "logout", label: qsTr("Log out"), glyph: 0xF0343, confirm: true, command: ["hyprctl", "dispatch", "exit"] },
        { id: "suspend", label: qsTr("Sleep"), glyph: 0xF04B2, confirm: false, command: ["systemctl", "suspend"] },
        { id: "reboot", label: qsTr("Restart"), glyph: 0xF0709, confirm: true, command: ["systemctl", "reboot"] },
        { id: "poweroff", label: qsTr("Shut down"), glyph: 0xF0425, confirm: true, command: ["systemctl", "poweroff"] }
    ]

    // -- Helper functions ---------------------------------------------------
    function findAction(actionId) {
        return actions.find(candidate => candidate.id === actionId) || null;
    }

    function actionLabel(actionId) {
        var actionEntry = findAction(actionId);
        return actionEntry ? actionEntry.label : "";
    }

    function runAction(actionId) {
        pending = "";
        ShellState.close();
        var actionEntry = findAction(actionId);
        if (actionId === "lock")
            ShellState.lockRequested();
        else if (actionEntry)
            Quickshell.execDetached(actionEntry.command);
    }



    // -- Visual tree --------------------------------------------------------
    DropPanel {
        name: "power"
        centered: true
        cardWidth: Theme.widthPx(520)

        PanelHeader {
            codepoint: 0xF0425
            title: root.pending === "" ? qsTr("Shut down or sign out") : qsTr("Confirm")
        }

        // Action buttons
        RowLayout {
            Layout.fillWidth: true
            visible: root.pending === ""
            spacing: Theme.spacingS

            Repeater {
                model: root.actions

                delegate: Button {
                    id: action
                    required property var modelData
                    Layout.fillWidth: true
                    implicitHeight: Theme.px(92)
                    framed: true
                    tint: modelData.id === "poweroff" || modelData.id === "reboot" ? Theme.dangerHighlight : Theme.highlight
                    onClicked: modelData.confirm ? root.pending = modelData.id : root.runAction(modelData.id)

                    ColumnLayout {
                        anchors.centerIn: parent
                        spacing: Theme.spacingS
                        MdIcon {
                            Layout.alignment: Qt.AlignHCenter
                            codepoint: action.modelData.glyph
                            font.pixelSize: Theme.iconPx(32)
                            color: action.modelData.id === "poweroff" ? Theme.danger : Theme.textSurface
                        }
                        StyledText {
                            Layout.alignment: Qt.AlignHCenter
                            text: action.modelData.label
                        }
                    }
                }
            }
        }

        // Confirmation
        ColumnLayout {
            Layout.fillWidth: true
            visible: root.pending !== ""
            spacing: Theme.spacingM

            StyledText {
                Layout.fillWidth: true
                wrapMode: Text.WordWrap
                text: qsTr("Confirm %1? Unsaved work in open applications may be lost.").arg(root.actionLabel(root.pending))
            }
            RowLayout {
                Layout.alignment: Qt.AlignRight
                spacing: Theme.spacingS
                ActionButton {
                    text: qsTr("Cancel")
                    onClicked: root.pending = ""
                }
                ActionButton {
                    text: root.actionLabel(root.pending)
                    filled: true
                    onClicked: root.runAction(root.pending)
                }
            }
        }
    }

    // -- Background objects -------------------------------------------------
    Connections {
        target: ShellState
        function onPanelChanged() {
            root.pending = "";
        }
    }
}
