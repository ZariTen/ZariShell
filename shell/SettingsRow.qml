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

    // Font picker (kind "font"): a searchable list of the installed families
    // that opens under the row. The families come from Qt when it opens.
    property bool fontListOpen: false
    property string fontFilter: ""
    readonly property string savedFont: modelData.kind === "font" ? Settings.get(modelData.key, "") : ""
    readonly property var installedFonts: fontListOpen ? uniqueSorted(Qt.fontFamilies()) : []
    readonly property bool savedFontMissing: savedFont !== "" && !Qt.fontFamilies().some(family => family.toLowerCase() === savedFont.toLowerCase())
    readonly property var fontChoices: {
        if (!fontListOpen)
            return [];
        var needle = fontFilter.trim().toLowerCase();
        var families = savedFontMissing ? [savedFont].concat(installedFonts) : installedFonts;
        var choices = needle === "" ? [{ family: "", label: Theme.themeFont + " (theme)" }] : [];
        families.forEach(family => {
            if (needle === "" || family.toLowerCase().indexOf(needle) >= 0)
                choices.push({ family: family, label: family });
        });
        return choices;
    }

    Layout.fillWidth: true
    implicitHeight: Theme.px(40) + (fontListOpen ? fontPicker.height : 0)

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

    function uniqueSorted(names) {
        var seen = {};
        var unique = [];
        names.forEach(name => {
            var trimmed = String(name).trim();
            if (trimmed !== "" && !seen[trimmed.toLowerCase()]) {
                seen[trimmed.toLowerCase()] = true;
                unique.push(trimmed);
            }
        });
        return unique.sort((first, second) => first.localeCompare(second));
    }

    // An empty family means the theme's font (the key is removed).
    function pickFont(family) {
        if (family === "")
            Settings.reset(modelData.key);
        else
            Settings.set(modelData.key, family);
        fontListOpen = false;
    }

    // -- Visual tree --------------------------------------------------------
    Surface {
        anchors.fill: parent
        radius: Theme.radius
        color: Theme.surfaceContainer
        shadow: false
    }

    RowLayout {
        id: controls
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        height: Theme.px(40)
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

        // Font family: shows the current family; opens the list below
        Button {
            visible: row.modelData.kind === "font"
            Layout.fillWidth: true
            implicitHeight: Theme.px(30)
            framed: true
            active: row.fontListOpen
            onClicked: row.fontListOpen = !row.fontListOpen

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: Theme.spacingS
                anchors.rightMargin: Theme.spacingS
                spacing: Theme.spacingS
                StyledText {
                    Layout.fillWidth: true
                    text: row.savedFont !== "" ? row.savedFont : Theme.themeFont + " (theme)"
                    color: row.savedFont !== "" ? Theme.textSurface : Theme.textSurfaceVariant
                    font.italic: row.savedFont === ""
                }
                StyledText {
                    visible: row.savedFontMissing
                    text: "not installed"
                    color: Theme.error
                    font.pixelSize: Theme.fontSmall
                }
                MdIcon {
                    codepoint: row.fontListOpen ? 0xF0143 : 0xF0140 // md-chevron_up / md-chevron_down
                    color: Theme.textSurfaceVariant
                }
            }
        }

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

    // Font list: search field and the matching families, each drawn in its
    // own font. The current one is checked; a saved family that is not
    // installed is listed first and marked.
    ColumnLayout {
        id: fontPicker
        visible: row.fontListOpen
        anchors.top: controls.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.leftMargin: Theme.spacingM
        anchors.rightMargin: Theme.spacingM
        height: Theme.px(260)
        spacing: Theme.spacingXs

        onVisibleChanged: {
            if (!visible)
                return;
            filterInput.text = "";
            filterInput.forceActiveFocus();
            var selectedIndex = row.fontChoices.findIndex(choice => choice.family.toLowerCase() === row.savedFont.toLowerCase());
            fontList.positionViewAtIndex(Math.max(0, selectedIndex), ListView.Center);
        }

        Field {
            Layout.fillWidth: true
            implicitHeight: Theme.px(30)
            input: filterInput
            TextInput {
                id: filterInput
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
                onTextChanged: row.fontFilter = text
                onAccepted: if (row.fontChoices.length > 0) row.pickFont(row.fontChoices[0].family)
                Keys.onEscapePressed: row.fontListOpen = false
                StyledText {
                    anchors.fill: parent
                    visible: filterInput.text === ""
                    text: "Search " + row.installedFonts.length + " installed fonts"
                    color: Theme.textSurfaceVariant
                    font.italic: true
                }
            }
        }

        ListView {
            id: fontList
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.bottomMargin: Theme.spacingS
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            model: row.fontChoices

            delegate: Button {
                id: fontChoice
                required property var modelData
                readonly property bool selected: modelData.family.toLowerCase() === row.savedFont.toLowerCase()
                width: ListView.view.width
                implicitHeight: Theme.px(32)
                active: selected
                passWheel: true
                onClicked: row.pickFont(modelData.family)

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: Theme.spacingS
                    anchors.rightMargin: Theme.spacingS
                    spacing: Theme.spacingS
                    StyledText {
                        Layout.fillWidth: true
                        text: fontChoice.modelData.label
                        font.family: fontChoice.modelData.family !== "" ? fontChoice.modelData.family : Theme.themeFont
                        font.italic: fontChoice.modelData.family === ""
                    }
                    StyledText {
                        visible: fontChoice.selected && row.savedFontMissing
                        text: "not installed"
                        color: Theme.error
                        font.pixelSize: Theme.fontSmall
                    }
                    MdIcon {
                        opacity: fontChoice.selected ? 1 : 0
                        codepoint: 0xF012C // md-check
                        color: Theme.accent
                    }
                }
            }

            StyledText {
                anchors.centerIn: parent
                visible: fontList.count === 0
                text: "No installed font matches"
                color: Theme.textSurfaceVariant
            }
        }
    }
}
