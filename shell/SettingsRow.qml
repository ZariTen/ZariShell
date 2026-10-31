pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell.Io

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

    // Accent picker (kind "accent"): a saturation/brightness square and a
    // hue bar under the row, opened from the swatch. Picks apply live.
    property bool colorPickerOpen: false
    property real pickHue: 0
    property real pickSaturation: 0
    property real pickValue: 0
    readonly property real pickMarkerRadius: Theme.px(7)
    // The accent in use while the picker is open; any change made outside
    // the picker (hex field, Theme / Wallpaper, reset) reloads the markers.
    readonly property string pickerSeed: colorPickerOpen ? Theme.accentSeed.toString() : ""

    Layout.fillWidth: true
    implicitHeight: Theme.px(40) + (fontListOpen ? fontPicker.height : 0) + (colorPickerOpen ? colorPicker.height + Theme.spacingS : 0)

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

    // Collapse both pickers and clear the font search when the row is hidden
    // or the settings panel closes, so they start closed next time.
    function closePickers() {
        fontListOpen = false;
        filterInput.text = "";
        colorPickerOpen = false;
    }

    // Load the markers from the accent in use, unless it is the picker's own
    // last pick: reading that back would round the markers, and a gray or
    // black (no hue) would reset the hue to red.
    function loadPickerFromAccent() {
        var seed = Theme.accentSeed;
        if (seed.toString() === Qt.hsva(pickHue, pickSaturation, pickValue, 1).toString())
            return;
        if (seed.hsvHue >= 0)
            pickHue = seed.hsvHue;
        pickSaturation = seed.hsvSaturation;
        pickValue = seed.hsvValue;
    }

    // Position on a picker track as 0..1. Both ends are inset by the marker
    // radius, so the marker stays inside and the extremes are easy to hit.
    function trackRatio(position, length) {
        return Math.max(0, Math.min(1, (position - pickMarkerRadius) / (length - 2 * pickMarkerRadius)));
    }

    // Save every pick as #rrggbb.
    function pickColor(hue, saturation, value) {
        pickHue = Math.max(0, Math.min(1, hue));
        pickSaturation = Math.max(0, Math.min(1, saturation));
        pickValue = Math.max(0, Math.min(1, value));
        Settings.set("accent", Qt.hsva(pickHue, pickSaturation, pickValue, 1).toString());
    }

    onPickerSeedChanged: if (colorPickerOpen) loadPickerFromAccent()

    onVisibleChanged: if (!visible) closePickers()

    Connections {
        target: ShellState
        function onPanelChanged() {
            if (ShellState.panel !== "settings")
                row.closePickers();

        }
    }

    // Eyedropper: hide the panel, let hyprpicker pick from the screen, then
    // reopen the panel. An empty result (Escape) changes nothing.
    // The delay lets the panel fade out first so it is not in the frozen frame.
    Timer {
        id: eyedropperDelay
        interval: Theme.durMedium + 100
        onTriggered: screenColorPicker.running = true
    }
    Process {
        id: screenColorPicker
        command: ["hyprpicker", "--format=hex", "--lowercase-hex", "--no-fancy", "--quiet"]
        stdout: StdioCollector {
            onStreamFinished: {
                var pickedHex = text.trim();
                if (/^#[0-9a-f]{6}$/.test(pickedHex))
                    Settings.set("accent", pickedHex);
                ShellState.panel = "settings";
            }
        }
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
            Button {
                implicitWidth: Theme.px(22)
                implicitHeight: Theme.px(22)
                radius: Theme.radiusFull
                onClicked: row.colorPickerOpen = !row.colorPickerOpen
                // The picked accent itself; a theme may derive its accent
                // tokens from it (aero and modern only use its hue).
                Rectangle {
                    anchors.fill: parent
                    radius: Theme.radiusFull
                    color: Theme.accentSeed
                    border.width: 1
                    border.color: Theme.border
                }
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
        IconButton {
            implicitWidth: Theme.px(30)
            radius: Theme.radiusFull
            enabled: row.isSet
            opacity: row.isSet ? 1 : Theme.dim(0.5)
            codepoint: 0xF099B // md-restore
            icon.color: Theme.textSurfaceVariant
            onClicked: Settings.reset(row.modelData.key)
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

    // Accent picker: saturation runs left to right and brightness bottom to
    // top over the current hue; the bar below chooses the hue.
    ColumnLayout {
        id: colorPicker
        visible: row.colorPickerOpen
        anchors.top: controls.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.leftMargin: Theme.spacingM
        anchors.rightMargin: Theme.spacingM
        height: Theme.px(150)
        spacing: Theme.spacingS

        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            radius: Theme.radius
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0; color: "white" }
                GradientStop { position: 1; color: Qt.hsva(row.pickHue, 1, 1, 1) }
            }
            Rectangle {
                anchors.fill: parent
                radius: parent.radius
                gradient: Gradient {
                    GradientStop { position: 0; color: "transparent" }
                    GradientStop { position: 1; color: "black" }
                }
            }
            Rectangle {
                x: row.pickSaturation * (parent.width - width)
                y: (1 - row.pickValue) * (parent.height - height)
                width: row.pickMarkerRadius * 2
                height: width
                radius: Theme.radiusFull
                color: Qt.hsva(row.pickHue, row.pickSaturation, row.pickValue, 1)
                border.width: 2
                border.color: "white"
            }
            MouseArea {
                anchors.fill: parent
                preventStealing: true
                onPressed: mouse => row.pickColor(row.pickHue, row.trackRatio(mouse.x, width), 1 - row.trackRatio(mouse.y, height))
                onPositionChanged: mouse => row.pickColor(row.pickHue, row.trackRatio(mouse.x, width), 1 - row.trackRatio(mouse.y, height))
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: Theme.spacingS
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: Theme.px(14)
                radius: Theme.radiusFull
                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop { position: 0 / 6; color: Qt.hsva(0 / 6, 1, 1, 1) }
                    GradientStop { position: 1 / 6; color: Qt.hsva(1 / 6, 1, 1, 1) }
                    GradientStop { position: 2 / 6; color: Qt.hsva(2 / 6, 1, 1, 1) }
                    GradientStop { position: 3 / 6; color: Qt.hsva(3 / 6, 1, 1, 1) }
                    GradientStop { position: 4 / 6; color: Qt.hsva(4 / 6, 1, 1, 1) }
                    GradientStop { position: 5 / 6; color: Qt.hsva(5 / 6, 1, 1, 1) }
                    GradientStop { position: 6 / 6; color: Qt.hsva(0, 1, 1, 1) }
                }
                Rectangle {
                    x: row.pickHue * (parent.width - width)
                    anchors.verticalCenter: parent.verticalCenter
                    width: row.pickMarkerRadius * 2
                    height: width
                    radius: Theme.radiusFull
                    color: Qt.hsva(row.pickHue, 1, 1, 1)
                    border.width: 2
                    border.color: "white"
                }
                MouseArea {
                    anchors.fill: parent
                    preventStealing: true
                    onPressed: mouse => row.pickColor(row.trackRatio(mouse.x, width), row.pickSaturation, row.pickValue)
                    onPositionChanged: mouse => row.pickColor(row.trackRatio(mouse.x, width), row.pickSaturation, row.pickValue)
                }
            }

            // Eyedropper: pick the accent from anywhere on screen.
            IconButton {
                implicitWidth: Theme.px(30)
                radius: Theme.radiusFull
                codepoint: 0xF020A // md-eyedropper
                icon.color: Theme.textSurfaceVariant
                onClicked: {
                    ShellState.close();
                    eyedropperDelay.start();
                }
            }
        }
    }
}
