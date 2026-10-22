import QtQuick
import QtQuick.Layouts
import Quickshell

// Win7-style shutdown dialog. Lock and Suspend run at once; Log out,
// Restart and Shut down ask for confirmation first.
Scope {
    id: root

    property string pending: ""   // action awaiting confirmation
    readonly property var actions: [
        { id: "lock", label: "Lock", glyph: 0xF033E, confirm: false },
        { id: "logout", label: "Log out", glyph: 0xF0343, confirm: true },
        { id: "suspend", label: "Sleep", glyph: 0xF04B2, confirm: false },
        { id: "reboot", label: "Restart", glyph: 0xF0709, confirm: true },
        { id: "poweroff", label: "Shut down", glyph: 0xF0425, confirm: true }
    ]

    function label(id) {
        var a = actions.find(x => x.id === id);
        return a ? a.label : "";
    }

    function run(id) {
        pending = "";
        ShellState.close();
        if (id === "lock")
            ShellState.lockRequested();
        else if (id === "logout")
            Quickshell.execDetached(["hyprctl", "dispatch", "exit"]);
        else if (id === "suspend")
            Quickshell.execDetached(["systemctl", "suspend"]);
        else if (id === "reboot")
            Quickshell.execDetached(["systemctl", "reboot"]);
        else if (id === "poweroff")
            Quickshell.execDetached(["systemctl", "poweroff"]);
    }

    Connections {
        target: ShellState
        function onPanelChanged() {
            root.pending = "";
        }
    }

    DropPanel {
        name: "power"
        centered: true
        cardWidth: 520

        PanelHeader {
            codepoint: 0xF0425
            title: root.pending === "" ? "Shut down or sign out" : "Confirm"
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
                    implicitHeight: 92
                    framed: true
                    tint: modelData.id === "poweroff" || modelData.id === "reboot" ? "#ff7a5c" : Theme.highlight
                    onClicked: modelData.confirm ? root.pending = modelData.id : root.run(modelData.id)

                    ColumnLayout {
                        anchors.centerIn: parent
                        spacing: Theme.spacingS
                        MdIcon {
                            Layout.alignment: Qt.AlignHCenter
                            codepoint: action.modelData.glyph
                            font.pixelSize: 32
                            color: action.modelData.id === "poweroff" ? "#ff8a70" : "#ffffff"
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
                text: "Are you sure you want to " + root.label(root.pending).toLowerCase() + "? Unsaved work in open applications may be lost."
            }
            RowLayout {
                Layout.alignment: Qt.AlignRight
                spacing: Theme.spacingS
                ActionButton {
                    text: "Cancel"
                    onClicked: root.pending = ""
                }
                ActionButton {
                    text: root.label(root.pending)
                    filled: true
                    onClicked: root.run(root.pending)
                }
            }
        }
    }
}
