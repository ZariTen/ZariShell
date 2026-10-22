import QtQuick
import QtQuick.Layouts

// One row of the settings panel: label, control, value and a reset button.
// `modelData` is a row spec from SettingsPanel.qml.
Item {
    id: row
    required property var modelData
    readonly property bool isSet: Settings.has(modelData.key)
    readonly property var value: Settings.get(modelData.key, modelData.def)

    Layout.fillWidth: true
    implicitHeight: Theme.px(40)

    function fmt(spec, v) {
        if (spec.unit === "pct")
            return Math.round(v * 100) + "%";
        if (spec.unit === "px")
            return Math.round(v) + " px";
        return v.toFixed(2) + "x";
    }

    function snap(spec, ratio) {
        var v = spec.min + Math.round(ratio * (spec.max - spec.min) / spec.step) * spec.step;
        return Math.round(Math.max(spec.min, Math.min(spec.max, v)) * 100) / 100;
    }

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
            visible: row.modelData.kind === "slider"
            Layout.fillWidth: true
            tone: "accent"
            property real pending: -1
            value: row.modelData.kind !== "slider" ? 0 : ((pending >= 0 ? pending : row.value) - row.modelData.min) / (row.modelData.max - row.modelData.min)
            onMoved: v => {
                if (row.modelData.onRelease)
                    pending = row.snap(row.modelData, v);
                else
                    Settings.set(row.modelData.key, row.snap(row.modelData, v));
            }
            onReleased: v => {
                if (row.modelData.onRelease) {
                    Settings.set(row.modelData.key, row.snap(row.modelData, v));
                    pending = -1;
                }
            }
        }
        StyledText {
            visible: row.modelData.kind === "slider"
            Layout.preferredWidth: Theme.px(56)
            horizontalAlignment: Text.AlignRight
            text: row.modelData.kind === "slider" ? row.fmt(row.modelData, slider.pending >= 0 ? slider.pending : row.value) : ""
            color: Theme.textSurfaceVariant
        }

        // Switch
        Item {
            visible: row.modelData.kind === "switch"
            Layout.fillWidth: true
        }
        Switch {
            visible: row.modelData.kind === "switch"
            checked: row.modelData.kind === "switch" && row.value === true
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
                model: [{ v: "", t: "Theme" }, { v: "wallpaper", t: "Wallpaper" }]
                Button {
                    id: choiceButton
                    required property var modelData
                    implicitWidth: choice.implicitWidth + Theme.spacingM * 2
                    implicitHeight: Theme.px(30)
                    framed: true
                    active: Settings.get("accent", "") === modelData.v
                    onClicked: modelData.v === "" ? Settings.reset("accent") : Settings.set("accent", modelData.v)
                    StyledText {
                        id: choice
                        anchors.centerIn: parent
                        text: choiceButton.modelData.t
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
                    onAccepted: if (/^#([0-9a-fA-F]{6}|[0-9a-fA-F]{8})$/.test(text.trim())) Settings.set("accent", text.trim())
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
