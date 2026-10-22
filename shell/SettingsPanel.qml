import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland

// Global settings dialog (ShellState.panel "settings"; quick settings cog,
// or `qs ipc call settings toggle`). Every row edits one key of
// settings.json through Settings; a key that is not set follows the theme.
// Built only from generic components, so the active theme styles it.
Scope {
    id: root

    readonly property bool open: ShellState.panel === "settings"
    readonly property string section: ShellState.settingsSection

    // Rows: key, label, kind ("slider" | "switch" | "font" | "accent"),
    // slider range/step, unit ("pct" | "px" | "x") and the value used when
    // the key is unset (the theme's value).
    readonly property var sections: [
        { id: "appearance", title: "Appearance", glyph: 0xF03D8, rows: [
            { key: "scale", label: "UI scale", kind: "slider", min: 0.75, max: 1.5, step: 0.05, unit: "pct", def: 1, onRelease: true },
            { key: "radius", label: "Corner radius", kind: "slider", min: 0, max: 2, step: 0.1, unit: "pct", def: 1 },
            { key: "spacing", label: "Spacing", kind: "slider", min: 0.5, max: 2, step: 0.05, unit: "pct", def: 1 },
            { key: "barHeight", label: "Bar height", kind: "slider", min: 28, max: 64, step: 1, unit: "px", def: Theme.themeBarHeight, onRelease: true },
            { key: "barOpacity", label: "Bar opacity", kind: "slider", min: 0, max: 1, step: 0.01, unit: "pct", def: Theme.themeBar.a },
            { key: "panelOpacity", label: "Panel opacity", kind: "slider", min: 0, max: 1, step: 0.01, unit: "pct", def: Theme.themePanel.a },
            { key: "accent", label: "Accent color", kind: "accent", def: "" }
        ] },
        { id: "text", title: "Text", glyph: 0xF06D6, rows: [
            { key: "font", label: "Font family", kind: "font", def: "" },
            { key: "fontSize", label: "Base font size", kind: "slider", min: 9, max: 20, step: 1, unit: "px", def: Theme.themeFontBody },
            { key: "iconSize", label: "Icon size", kind: "slider", min: 12, max: 24, step: 1, unit: "px", def: 16 }
        ] },
        { id: "motion", title: "Motion", glyph: 0xF04C5, rows: [
            { key: "animationSpeed", label: "Animation speed", kind: "slider", min: 0.25, max: 3, step: 0.05, unit: "x", def: 1 },
            { key: "reduceMotion", label: "Reduce motion", kind: "switch", def: false }
        ] },
        { id: "layout", title: "Layout", glyph: 0xF056E, rows: [
            { key: "avatarSize", label: "Lock screen avatar", kind: "slider", min: 64, max: 192, step: 4, unit: "px", def: 112 },
            { key: "panelWidth", label: "Panel width", kind: "slider", min: 0.8, max: 1.5, step: 0.05, unit: "pct", def: 1, onRelease: true },
            { key: "dim", label: "Dimmed items", kind: "slider", min: 0.15, max: 0.9, step: 0.05, unit: "pct", def: 0.5 }
        ] },
        // Theme picker goes here later (see Settings.qml); for now it only
        // shows the active theme.
        { id: "theme", title: "Theme", glyph: 0xF00E3, rows: [] }
    ]
    readonly property var current: {
        for (var i = 0; i < sections.length; i++) {
            if (sections[i].id === section)
                return sections[i];
        }
        return sections[0];
    }

    function keysOf(sec) {
        return sec.rows.map(r => r.key);
    }

    PanelWindow {
        id: window

        screen: {
            var all = Quickshell.screens;
            var focused = Hyprland.focusedMonitor;
            for (var i = 0; focused && i < all.length; i++) {
                if (all[i].name === focused.name)
                    return all[i];
            }
            return all[0];
        }
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

                    Button {
                        implicitWidth: Theme.px(30)
                        implicitHeight: Theme.px(30)
                        radius: Theme.radiusFull
                        onClicked: ShellState.close()
                        MdIcon {
                            anchors.centerIn: parent
                            codepoint: 0xF0156 // md-close
                        }
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
                                id: nav
                                required property var modelData
                                Layout.fillWidth: true
                                implicitHeight: Theme.px(36)
                                active: root.current.id === modelData.id
                                onClicked: ShellState.settingsSection = modelData.id

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: Theme.spacingM
                                    anchors.rightMargin: Theme.spacingM
                                    spacing: Theme.spacingM
                                    MdIcon {
                                        codepoint: nav.modelData.glyph
                                        color: nav.active ? Theme.accent : Theme.textSurface
                                    }
                                    StyledText {
                                        Layout.fillWidth: true
                                        text: nav.modelData.title
                                        font.weight: nav.active ? Font.DemiBold : Font.Normal
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
                                text: root.current.title
                                font.pixelSize: Theme.fontTitle
                                font.weight: Font.DemiBold
                            }
                            ActionButton {
                                visible: root.current.rows.length > 0
                                enabled: root.keysOf(root.current).some(k => Settings.has(k))
                                opacity: enabled ? 1 : Theme.dim(0.5)
                                text: "Reset section"
                                onClicked: if (enabled) Settings.resetKeys(root.keysOf(root.current))
                            }
                        }

                        Flickable {
                            id: flick
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            clip: true
                            boundsBehavior: Flickable.StopAtBounds
                            contentWidth: width
                            contentHeight: rows.implicitHeight

                            ColumnLayout {
                                id: rows
                                width: flick.width
                                spacing: Theme.spacingS

                                Repeater {
                                    model: root.current.rows
                                    delegate: SettingsRow {}
                                }

                                // Theme section (picker stub)
                                ColumnLayout {
                                    visible: root.current.id === "theme"
                                    Layout.fillWidth: true
                                    spacing: Theme.spacingS
                                    StyledText {
                                        text: "Active theme: " + (Theme.name || "(unnamed)") + (Theme.userActive ? " (from ~/.config/zarishell/current)" : " (packaged)")
                                    }
                                    StyledText {
                                        Layout.fillWidth: true
                                        wrapMode: Text.Wrap
                                        color: Theme.textSurfaceVariant
                                        font.pixelSize: Theme.fontSmall
                                        text: "A theme picker will live here. For now, point ~/.config/zarishell/current at a theme folder, or set ZARISHELL_THEME."
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
