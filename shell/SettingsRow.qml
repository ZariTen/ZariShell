pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts

// One row of the settings panel: label, control, value and a reset button.
// `modelData` is a row spec from SettingsPanel.qml.
Item {
    id: row

    // -- Public / derived properties ----------------------------------------
    required property var modelData
    readonly property bool isSet: Settings.has(modelData.key)
    readonly property var currentValue: Settings.get(modelData.key, modelData.def)
    readonly property real displayedSliderValue: slider.pendingValue >= 0 ? slider.pendingValue : Number(currentValue)

    Layout.fillWidth: true
    implicitHeight: Theme.px(40)

    // -- Helper functions ---------------------------------------------------
    function formatValue(rowSpec, numericValue) {
        if (rowSpec.unit === "pct")
            return Math.round(numericValue * 100) + "%";
        if (rowSpec.unit === "px")
            return Math.round(numericValue) + " px";
        return numericValue.toFixed(2) + "x";
    }

    function snapValue(rowSpec, ratio) {
        var stepped = rowSpec.min + Math.round(ratio * (rowSpec.max - rowSpec.min) / rowSpec.step) * rowSpec.step;
        return Math.round(Math.max(rowSpec.min, Math.min(rowSpec.max, stepped)) * 100) / 100;
    }

    // -- Visual tree --------------------------------------------------------
    Surface {
        anchors.fill: parent
        radius: Theme.radius
        color: Theme.surfaceContainer
        shadow: false
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: Theme.spacingM
        anchors.rightMargin: Theme.spacingXs
        spacing: Theme.spacingM

        StyledText {
            Layout.preferredWidth: Theme.px(140)
            text: row.modelData.label
            color: row.isSet ? Theme.textSurface : Theme.textSurfaceVariant
        }

        // Slider
        Slider {
            id: slider
            property real pendingValue: -1

            visible: row.modelData.kind === "slider"
            Layout.fillWidth: true
            tone: "accent"
            value: {
                if (row.modelData.kind !== "slider")
                    return 0;
                return (row.displayedSliderValue - row.modelData.min) / (row.modelData.max - row.modelData.min);
            }
            onMoved: ratio => {
                var snapped = row.snapValue(row.modelData, ratio);
                if (row.modelData.onRelease)
                    pendingValue = snapped;
                else
                    Settings.set(row.modelData.key, snapped);
            }
            onReleased: ratio => {
                if (row.modelData.onRelease) {
                    Settings.set(row.modelData.key, row.snapValue(row.modelData, ratio));
                    pendingValue = -1;
                }
            }
        }
        StyledText {
            visible: row.modelData.kind === "slider"
            Layout.preferredWidth: Theme.px(56)
            horizontalAlignment: Text.AlignRight
            text: row.modelData.kind === "slider" ? row.formatValue(row.modelData, row.displayedSliderValue) : ""
            color: Theme.textSurfaceVariant
        }

        // Switch
        Item {
            visible: row.modelData.kind === "switch"
            Layout.fillWidth: true
        }
        Switch {
            visible: row.modelData.kind === "switch"
            checked: row.modelData.kind === "switch" && row.currentValue === true
            onToggled: Settings.set(row.modelData.key, !checked)
        }

        // Font family
        Field {
            visible: row.modelData.kind === "font"
            Layout.fillWidth: true
            implicitHeight: Theme.px(30)
            input: fontInput
            TextInput {
                id: fontInput
                anchors.fill: parent
                anchors.leftMargin: Theme.spacingS
                anchors.rightMargin: Theme.spacingS
                verticalAlignment: TextInput.AlignVCenter
                color: Theme.textSurface
                selectionColor: Theme.primary
                selectedTextColor: Theme.textPrimary
                font.family: Theme.font
                font.pixelSize: Theme.fontBody
                clip: true
                text: row.modelData.kind === "font" ? Settings.get("font", "") : ""
                onAccepted: Settings.set("font", text.trim())
                onEditingFinished: Settings.set("font", text.trim())
                StyledText {
                    anchors.fill: parent
                    visible: fontInput.text === ""
                    text: Theme.themeFont + " (theme)"
                    color: Theme.textSurfaceVariant
                    font.italic: true
                }
            }
        }

        // Accent: theme / wallpaper / custom color
        RowLayout {
            visible: row.modelData.kind === "accent"
            Layout.fillWidth: true
            spacing: Theme.spacingXs
            Repeater {
                model: [
                    { value: "", label: "Theme" },
                    { value: "wallpaper", label: "Wallpaper" }
                ]
                Button {
                    id: choiceButton
                    required property var modelData
                    implicitWidth: choiceLabel.implicitWidth + Theme.spacingM * 2
                    implicitHeight: Theme.px(30)
                    framed: true
                    active: Settings.get("accent", "") === modelData.value
                    onClicked: modelData.value === "" ? Settings.reset("accent") : Settings.set("accent", modelData.value)
                    StyledText {
                        id: choiceLabel
                        anchors.centerIn: parent
                        text: choiceButton.modelData.label
                    }
                }
            }
            Field {
                Layout.fillWidth: true
                implicitHeight: Theme.px(30)
                Layout.minimumWidth: Theme.px(84)
                input: hexInput
                TextInput {
                    id: hexInput
                    anchors.fill: parent
                    anchors.leftMargin: Theme.spacingS
                    anchors.rightMargin: Theme.spacingS
                    verticalAlignment: TextInput.AlignVCenter
                    color: Theme.textSurface
                    selectionColor: Theme.primary
                    selectedTextColor: Theme.textPrimary
                    font.family: Theme.font
                    font.pixelSize: Theme.fontBody
                    clip: true
                    maximumLength: 9
                    text: /^#/.test(Settings.get("accent", "")) ? Settings.get("accent", "") : ""
                    onAccepted: {
                        var trimmedHex = text.trim();
                        if (/^#([0-9a-fA-F]{6}|[0-9a-fA-F]{8})$/.test(trimmedHex))
                            Settings.set("accent", trimmedHex);
                    }
                    StyledText {
                        anchors.fill: parent
                        visible: hexInput.text === ""
                        text: "#rrggbb"
                        color: Theme.textSurfaceVariant
                        font.italic: true
                    }
                }
            }
            Rectangle {
                implicitWidth: Theme.px(22)
                implicitHeight: Theme.px(22)
                radius: Theme.radiusFull
                color: Theme.accent
                border.width: 1
                border.color: Theme.border
            }
        }

        // Choice: one segmented button per value in `choices`
        RowLayout {
            visible: row.modelData.kind === "choice"
            Layout.fillWidth: true
            spacing: Theme.spacingXs
            Repeater {
                model: row.modelData.kind === "choice" ? row.modelData.choices : []
                Button {
                    id: optionButton
                    required property var modelData
                    implicitWidth: optionLabel.implicitWidth + Theme.spacingM * 2
                    implicitHeight: Theme.px(30)
                    framed: true
                    active: row.currentValue === modelData.value
                    onClicked: Settings.set(row.modelData.key, modelData.value)
                    StyledText {
                        id: optionLabel
                        anchors.centerIn: parent
                        text: optionButton.modelData.label
                    }
                }
            }
            Item {
                Layout.fillWidth: true
            }
        }

        // Reset
        Button {
            implicitWidth: Theme.px(30)
            implicitHeight: Theme.px(30)
            radius: Theme.radiusFull
            enabled: row.isSet
            opacity: row.isSet ? 1 : Theme.dim(0.5)
            onClicked: Settings.reset(row.modelData.key)
            MdIcon {
                anchors.centerIn: parent
                codepoint: 0xF099B // md-restore
                color: Theme.textSurfaceVariant
            }
        }
    }
}
