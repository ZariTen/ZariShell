pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland

// Global settings dialog (ShellState.panel "settings"; quick settings cog,
// or `qs ipc call settings toggle`). Every row edits one key of
// settings.json through Settings; a key that is not set uses its default
// (the theme's, for looks such as opacity and font family).
// Built only from generic components, so the active theme styles it.
Scope {
    id: root

    // -- Public / derived state ---------------------------------------------
    readonly property bool open: ShellState.panel === "settings"
    readonly property string section: ShellState.settingsSection

    // Rows: key, label, kind ("slider" | "switch" | "font" | "accent"),
    // slider range/step, unit ("pct" | "px" | "x") and the value used when
    // the key is unset.
    readonly property var sections: [
        { id: "appearance", title: "Appearance", glyph: 0xF03D8, rows: [
            { key: "scale", label: "UI scale", kind: "slider", min: 0.75, max: 1.5, step: 0.05, unit: "pct", def: 1, onRelease: true },
            { key: "radius", label: "Corner radius", kind: "slider", min: 0, max: 2, step: 0.1, unit: "pct", def: 1 },
            { key: "spacing", label: "Spacing", kind: "slider", min: 0.5, max: 2, step: 0.05, unit: "pct", def: 1 },
            { key: "barHeight", label: "Bar height", kind: "slider", min: 28, max: 64, step: 1, unit: "px", def: 42, onRelease: true },
            { key: "barOpacity", label: "Bar opacity", kind: "slider", min: 0, max: 1, step: 0.01, unit: "pct", def: Theme.themeBar.a },
            { key: "panelOpacity", label: "Panel opacity", kind: "slider", min: 0, max: 1, step: 0.01, unit: "pct", def: Theme.themePanel.a },
            { key: "accent", label: "Accent color", kind: "accent", def: "" }
        ] },
        { id: "text", title: "Text", glyph: 0xF06D6, rows: [
            { key: "font", label: "Font family", kind: "font", def: "" },
            { key: "fontSize", label: "Base font size", kind: "slider", min: 9, max: 20, step: 1, unit: "px", def: Theme.defaultFontSize },
            { key: "iconSize", label: "Icon size", kind: "slider", min: 12, max: 24, step: 1, unit: "px", def: 16 }
        ] },
        { id: "motion", title: "Motion", glyph: 0xF04C5, rows: [
            { key: "animationSpeed", label: "Animation speed", kind: "slider", min: 0.25, max: 3, step: 0.05, unit: "x", def: 1 },
            { key: "reduceMotion", label: "Reduce motion", kind: "switch", def: false }
        ] },
        { id: "layout", title: "Layout", glyph: 0xF056E, rows: [
            { key: "barStyle", label: "Bar style", kind: "choice", choices: [{ value: "full", label: "Full width" }, { value: "floating", label: "Floating" }, { value: "pills", label: "Pills" }], def: "full" },
            { key: "workspaceStyle", label: "Workspace style", kind: "choice", choiceLayout: "stacked", choices: [{ value: "dots", label: "Dots" }, { value: "numbers", label: "Numbers" }, { value: "pills", label: "Pills" }, { value: "diamonds", label: "Diamonds" }], def: "dots" },
            { key: "barGap", label: "Bar gap", kind: "slider", min: 0, max: 24, step: 1, unit: "px", def: 8, onRelease: true },
            { key: "avatarSize", label: "Lock screen avatar", kind: "slider", min: 64, max: 192, step: 4, unit: "px", def: 112 },
            { key: "panelWidth", label: "Panel width", kind: "slider", min: 0.8, max: 1.5, step: 0.05, unit: "pct", def: 1, onRelease: true },
            { key: "dim", label: "Dimmed items", kind: "slider", min: 0.15, max: 0.9, step: 0.05, unit: "pct", def: 0.5 }
        ] },
        { id: "theme", title: "Theme", glyph: 0xF00E3, rows: [] }
    ]

    readonly property var currentSection: {
        for (var i = 0; i < sections.length; i++) {
            if (sections[i].id === section)
                return sections[i];
        }
        return sections[0];
    }

    // -- Helper functions ---------------------------------------------------
    function sectionKeys(sectionSpec) {
        return sectionSpec.rows.map(rowSpec => rowSpec.key);
    }

    onOpenChanged: if (open) Theme.scan()

    // -- Visual tree --------------------------------------------------------
    PanelWindow {
        id: window

        screen: ShellState.focusedScreen()
        visible: root.open || card.animating
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
        WlrLayershell.keyboardFocus: root.open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

        Rectangle {
            anchors.fill: parent
            color: Theme.scrim
            opacity: card.shown ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: Theme.durMedium } }
        }

        MouseArea {
            anchors.fill: parent
            onClicked: ShellState.close()
        }

        PanelCard {
            id: card
            shown: root.open
            width: Math.min(window.width - Theme.px(80), Theme.widthPx(760))
            height: Math.min(window.height - Theme.px(120), Theme.px(580))
            focus: true
            onShownChanged: if (shown) card.forceActiveFocus()
            Keys.onEscapePressed: ShellState.close()

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: Theme.spacingXl
                spacing: Theme.spacingL

                // Title
                RowLayout {
                    Layout.fillWidth: true
                    spacing: Theme.spacingM

                    Rectangle {
                        implicitWidth: Theme.px(40)
                        implicitHeight: Theme.px(40)
                        radius: Theme.radiusFull
                        color: Theme.primaryContainer

                        MdIcon {
                            anchors.centerIn: parent
                            codepoint: 0xF062E // md-tune
                            color: Theme.textPrimaryContainer
                            font.pixelSize: Theme.iconPx(20)
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 0
                        StyledText {
                            text: "Settings"
                            font.pixelSize: Theme.fontHeadline
                            font.weight: Font.Bold
                        }
                        StyledText {
                            Layout.fillWidth: true
                            text: Settings.invalid ? "settings.json is not valid JSON: using defaults, changes are not saved" : "Changes apply and save immediately"
                            color: Settings.invalid ? Theme.error : Theme.textSurfaceVariant
                            font.pixelSize: Theme.fontSmall
                        }
                    }

                    IconButton {
                        implicitWidth: Theme.px(30)
                        radius: Theme.radiusFull
                        codepoint: 0xF0156 // md-close
                        onClicked: ShellState.close()
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    spacing: Theme.spacingL

                    // Section list
                    ColumnLayout {
                        Layout.alignment: Qt.AlignTop
                        Layout.fillWidth: false
                        Layout.preferredWidth: Theme.px(170)
                        Layout.maximumWidth: Theme.px(170)
                        spacing: Theme.spacingXs

                        Repeater {
                            model: root.sections
                            Button {
                                id: navButton
                                required property var modelData
                                Layout.fillWidth: true
                                implicitHeight: Theme.px(36)
                                active: root.currentSection.id === modelData.id
                                onClicked: ShellState.settingsSection = modelData.id

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: Theme.spacingM
                                    anchors.rightMargin: Theme.spacingM
                                    spacing: Theme.spacingM
                                    MdIcon {
                                        codepoint: navButton.modelData.glyph
                                        color: navButton.active ? Theme.accent : Theme.textSurface
                                    }
                                    StyledText {
                                        Layout.fillWidth: true
                                        text: navButton.modelData.title
                                        font.weight: navButton.active ? Font.DemiBold : Font.Normal
                                    }
                                }
                            }
                        }
                    }

                    Divider {
                        Layout.fillHeight: true
                    }

                    // Rows of the current section
                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        spacing: Theme.spacingM

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: Theme.spacingS
                            StyledText {
                                Layout.fillWidth: true
                                text: root.currentSection.title
                                font.pixelSize: Theme.fontTitle
                                font.weight: Font.DemiBold
                            }
                            ActionButton {
                                visible: root.currentSection.rows.length > 0
                                enabled: root.currentSection.rows.some(rowSpec => Settings.isModified(rowSpec.key, rowSpec.def))
                                opacity: enabled ? 1 : Theme.dim(0.5)
                                text: "Reset section"
                                onClicked: if (enabled) Settings.resetKeys(root.sectionKeys(root.currentSection))
                            }
                            ActionButton {
                                visible: root.currentSection.id === "theme"
                                text: "Reload"
                                onClicked: Theme.reload()
                            }
                        }

                        Flickable {
                            id: flick
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            clip: true
                            pixelAligned: true
                            boundsBehavior: Flickable.StopAtBounds
                            flickableDirection: Flickable.VerticalFlick
                            contentWidth: width
                            contentHeight: rows.implicitHeight

                            ColumnLayout {
                                id: rows
                                width: flick.width
                                spacing: Theme.spacingS

                                Repeater {
                                    model: root.currentSection.rows
                                    delegate: SettingsRow {}
                                }

                                // Theme picker. The model is a count, not the
                                // Theme.themes array: that array is replaced on
                                // every switch and scan, which would rebuild
                                // the cards (resetting their size and hover
                                // while the list keeps scrolling under them).
                                Repeater {
                                    model: root.currentSection.id === "theme" ? Theme.themes.length : 0

                                    Button {
                                        id: themeCard
                                        required property int index
                                        readonly property var themeEntry: Theme.themes[index] || ({})
                                        readonly property bool isCurrent: themeEntry.id === Theme.currentId
                                        Layout.fillWidth: true
                                        implicitHeight: cardRow.implicitHeight + Theme.spacingS * 2
                                        framed: true
                                        active: isCurrent
                                        passWheel: true
                                        onClicked: Theme.setTheme(themeEntry.id)

                                        // The preview shows the theme's own
                                        // colors, so it sits outside the
                                        // active restyle (Liquid Glass would
                                        // tint it dark gray).
                                        plainContent: ThemePreview {
                                            id: preview
                                            anchors.left: parent.left
                                            anchors.verticalCenter: parent.verticalCenter
                                            anchors.leftMargin: Theme.spacingS
                                            spec: themeCard.themeEntry.spec || ({})
                                        }

                                        RowLayout {
                                            id: cardRow
                                            anchors.left: parent.left
                                            anchors.right: parent.right
                                            anchors.verticalCenter: parent.verticalCenter
                                            anchors.leftMargin: Theme.spacingS
                                            anchors.rightMargin: Theme.spacingM
                                            spacing: Theme.spacingM

                                            // Room for the preview.
                                            Item {
                                                implicitWidth: preview.width
                                                implicitHeight: preview.height
                                            }

                                            ColumnLayout {
                                                Layout.fillWidth: true
                                                spacing: Theme.px(2)

                                                StyledText {
                                                    Layout.fillWidth: true
                                                    text: themeCard.themeEntry.name || ""
                                                    font.weight: Font.DemiBold
                                                }

                                                StyledText {
                                                    visible: text !== ""
                                                    Layout.fillWidth: true
                                                    text: themeCard.themeEntry.description || ""
                                                    color: Theme.textSurfaceVariant
                                                    font.pixelSize: Theme.fontSmall
                                                }
                                            }

                                            // Always laid out (only faded) so the
                                            // checkmark never shifts the text.
                                            MdIcon {
                                                opacity: themeCard.isCurrent ? 1 : 0
                                                codepoint: 0xF012C // md-check
                                                color: Theme.accent
                                                font.pixelSize: Theme.iconPx(18)
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        // Theme picker hint: outside the list so it stays
                        // visible however many themes there are.
                        StyledText {
                            visible: root.currentSection.id === "theme"
                            Layout.fillWidth: true
                            elide: Text.ElideMiddle
                            color: Theme.textSurfaceVariant
                            font.pixelSize: Theme.fontSmall
                            text: "User themes: ~/.config/zarishell/themes/<name>/theme.json"
                        }
                    }
                }
            }
        }
    }
}
