import QtQuick
import Quickshell
import Quickshell.Io

ShellRoot {
    id: root
    readonly property var accentRoles: ["accent", "highlight", "primary", "primaryContainer", "buttonDefault"]
    readonly property var surfaces: ({ bar: "themeBar", panel: "themePanel", surfaceContainer: "surfaceContainer", inset: "inset" })
    property int phase: 0
    property string defaultAccent
    property color defaultPanel
    property string defaultText
    property string defaultError
    property color previousSample
    property color customPanel
    property var themePalettes
    property real darkBlueLightness: 0

    FileView { id: fixtureFile; blockWrites: true; printErrors: false }

    function check(condition, message) {
        if (!condition) throw new Error(message);
    }
    function writeFixture(name, data) {
        var dir = Quickshell.env("XDG_CACHE_HOME");
        check(dir && dir.startsWith("/"), "Set an isolated XDG cache through the QML regression runner");
        fixtureFile.path = dir + "/" + name;
        fixtureFile.setText(data);
        return fixtureFile.path;
    }
    function wallpaper(name, rgb) {
        Wallpaper.path = writeFixture(name + ".ppm", "P3\n2 2\n255\n" + (rgb + "\n").repeat(4));
    }
    function sampleWallpaper(name, pixels) {
        previousSample = Theme.wallpaperColor;
        Wallpaper.path = writeFixture(name + ".ppm", "P3\n" + pixels.length + " 1\n255\n" + pixels.join("\n"));
    }
    function contrast(foreground, background) {
        var fg = Theme.relativeLuminance(Qt.tint(background, foreground));
        var bg = Theme.relativeLuminance(background);
        return (Math.max(fg, bg) + 0.05) / (Math.min(fg, bg) + 0.05);
    }
    function defaultPalettes() {
        var values = {};
        for (var theme of Theme.themes.concat([{ id: "legacy", spec: { accent: "wallpaper" } }])) {
            values[theme.id] = ["accent", "bar", "panel", "surface", "textSurface"].map(key =>
                String(Theme.specColor(theme.spec, key, key === "accent" ? "accent" : "#ffffff")));
        }
        return values;
    }
    function checkPalette(channel) {
        var alternatives = channel === "g" ? ["r", "b"] : ["g", "b"];
        for (var role of accentRoles) {
            var live = Theme[role];
            check(alternatives.every(other => live[channel] - live[other] > 0.1),
                "Wallpaper must color Metro's " + role + ": " + live);
            for (var theme of Theme.themes) {
                var preview = Theme.specColor(theme.spec, role, "transparent");
                check(Qt.colorEqual(live, preview), theme.id + " must use the same wallpaper " + role + ": " + preview + " versus " + live);
            }
        }
        check(String(Theme.textSurface) === defaultText && String(Theme.error) === defaultError,
            "Wallpaper must not replace body text or status colors");
    }
    function checkSurfaces(channel) {
        var alternatives = channel === "g" ? ["r", "b"] : ["g", "b"];
        for (var role of Object.keys(surfaces)) {
            var live = Theme[surfaces[role]];
            check(alternatives.every(other => live[channel] - live[other] > 0.14),
                "Wallpaper must visibly tint Metro's " + role + ": " + live);
            for (var theme of Theme.themes) {
                var preview = Theme.specColor(theme.spec, role, "transparent");
                check(alternatives.every(other => preview[channel] - preview[other] > 0.14),
                    theme.id + " must visibly tint its " + role + ": " + preview);
                if (theme.id === Theme.currentId)
                    check(Qt.colorEqual(live, preview), "Live palette and preview must agree for " + role);
            }
        }
    }

    Timer {
        interval: 25
        running: true
        repeat: true
        onTriggered: {
            try {
                if (root.phase === 0 && Theme.themes.length > 0) {
                    root.check(Theme.setTheme("metro") === "metro", "Metro theme must load");
                    Settings.reset("accent");
                    root.defaultAccent = String(Theme.accent);
                    root.defaultPanel = Theme.themePanel;
                    root.defaultText = String(Theme.textSurface);
                    root.defaultError = String(Theme.error);
                    root.wallpaper("green", "0 255 0");
                    root.phase = 1;
                } else if (root.phase === 1 && Math.abs(Theme.sampledWallpaperHue - 1 / 3) < 0.01) {
                    root.check(String(Theme.accent) === root.defaultAccent, "Theme mode must preserve Metro's own accent");
                    Settings.set("accent", "wallpaper");
                    root.checkPalette("g");
                    root.checkSurfaces("g");
                    root.check(root.contrast(Theme.textSurfaceVariant, Qt.tint(Theme.surface, Theme.panel)) >= 4.5,
                        "Unmodified settings labels must stay readable on the green panel");
                    root.check(root.contrast(Theme.textBarError, Qt.tint(Theme.surface, Theme.bar)) >= 4.5,
                        "Low-battery text must stay readable on the green bar");
                    root.wallpaper("red", "255 0 0");
                    root.phase = 2;
                } else if (root.phase === 2 && Math.abs(Theme.sampledWallpaperHue) < 0.01) {
                    root.checkPalette("r");
                    root.checkSurfaces("r");
                    Settings.reset("accent");
                    root.check(String(Theme.accent) === root.defaultAccent, "Clearing the override must restore Metro's default");
                    root.check(Qt.colorEqual(Theme.themePanel, root.defaultPanel), "Clearing the override must restore Metro's panel");
                    console.log("PASS QML regression tests: shared wallpaper palette across " + Theme.themes.map(theme => theme.id).join(", "));
                    root.wallpaper("blue", "0 0 255");
                    root.phase = 3;
                } else if (root.phase === 3 && Math.abs(Theme.sampledWallpaperHue - 2 / 3) < 0.01) {
                    Settings.set("accent", "wallpaper");
                    root.check(root.contrast(Theme.primaryIndicator, Theme.surfaceContainer) >= 4.5,
                        "A blue accent indicator must stay readable on a dark surface");
                    Settings.reset("accent");
                    root.loadLightFillTheme();
                    root.check(String(Theme.textPrimaryContainer) === "#111111" && String(Theme.textButtonDefault) === "#111111",
                        "Custom theme must retain its own text colors in Theme mode");
                    var panelAlpha = Theme.themePanel.a;
                    Settings.set("accent", "wallpaper");
                    root.check(Theme.themePanel.b > Theme.themePanel.r && Math.abs(Theme.themePanel.a - panelAlpha) < 0.001,
                        "The palette must keep a custom panel's translucency");
                    root.check(root.contrast(Theme.textSurface, Qt.tint(Theme.surface, Theme.themePanel)) >= 4.5,
                        "Dark body text must remain readable under the wallpaper palette");
                    root.check(root.contrast(Theme.textPrimaryContainer, Theme.primaryContainer) >= 4.5,
                        "A pinned dark label must not disappear on the wallpaper-tinted container");
                    root.check(root.contrast(Theme.textButtonDefault, Theme.buttonDefault) >= 4.5,
                        "A pinned dark label must not disappear on the wallpaper-tinted button");
                    console.log("PASS QML regression tests: wallpaper accents preserve foreground contrast");
                    root.check(Theme.setTheme("aero") === "aero", "Aero theme must load for wallpaper sampling");
                    root.sampleWallpaper("mostly-dark", Array(31).fill("32 32 32").concat("0 0 255"));
                    root.phase = 4;
                } else if (root.phase >= 4 && !Qt.colorEqual(Theme.wallpaperColor, root.previousSample)) {
                    var panel = Theme.themePanel;
                    if (root.phase === 4) {
                        root.check(panel.hslSaturation < 0.08 && panel.hslLightness < 0.14,
                            "A small bright detail must not tint a mostly dark wallpaper: " + panel);
                        root.sampleWallpaper("dark-blue", Array(32).fill("12 39 76"));
                        root.phase = 5;
                    } else if (root.phase === 5) {
                        root.darkBlueLightness = panel.hslLightness;
                        root.sampleWallpaper("bright-blue", Array(32).fill("33 138 214"));
                        root.phase = 6;
                    } else if (root.phase === 6) {
                        root.check(panel.hslHue > 0.53 && panel.hslHue < 0.62 && panel.hslLightness > root.darkBlueLightness + 0.04,
                            "A brighter blue wallpaper must produce a lighter blue panel: " + panel);
                        root.check(Theme.themeBar.hslLightness > 0.23 && Theme.themeBar.hslHue > 0.53 && Theme.themeBar.hslHue < 0.62,
                            "The visible bar must also follow a bright blue wallpaper: " + Theme.themeBar);
                        root.check(root.contrast(Theme.textPanelError, Qt.tint(Qt.tint(Theme.surface, Theme.panel), Theme.surfaceContainerHighest)) >= 4.5,
                            "Error labels must remain readable on the brighter palette");
                        root.sampleWallpaper("pastel", Array(15).fill("178 195 236").concat(Array(16).fill("238 189 228"), "0 0 255"));
                        root.phase = 7;
                    } else if (root.phase === 7) {
                        root.check(panel.b > panel.r && panel.r > panel.g + 0.025,
                            "Blue and pink wallpaper regions must blend into a lavender tint: " + panel);
                        for (var theme of Theme.themes) {
                            var foreground = Theme.specColor(theme.spec, "textSurface", "#ffffff");
                            var secondary = Theme.specColor(theme.spec, "textSurfaceVariant", "#ffffff");
                            for (var key of ["panel", "bar"]) {
                                var face = Theme.specColor(theme.spec, key, "transparent");
                                root.check(Math.abs(face.hslLightness - Theme.wallpaperColor.hslLightness) < 0.08,
                                    theme.id + " must preserve the brightness of a pale lavender " + key + ": " + face);
                                var painted = Qt.tint(Qt.rgba(0, 0, 0, 1), face);
                                root.check(root.contrast(foreground, painted) >= 4.5 && root.contrast(secondary, painted) >= 4.5,
                                    theme.id + " must keep body text and labels readable on its pastel " + key);
                            }
                            var panelFace = Theme.specColor(theme.spec, "panel", "transparent");
                            var errorText = Theme.specColor(theme.spec, "error", "#ff6b5e");
                            for (var statusRole of ["errorContainer", "criticalContainer"]) {
                                var statusFace = Qt.tint(Qt.tint(Qt.rgba(0, 0, 0, 1), panelFace),
                                    Theme.specColor(theme.spec, statusRole, "transparent"));
                                root.check(root.contrast(foreground, statusFace) >= 4.5 && root.contrast(errorText, statusFace) >= 4.5,
                                    theme.id + " must keep error messages readable on a pastel " + statusRole);
                            }
                        }
                        Settings.set("panelOpacity", 0.3);
                        root.check(Math.abs(Theme.panel.a - 0.3) < 0.001, "A pastel palette must honor explicit opacity");
                        Settings.reset("panelOpacity");
                        root.check(Theme.setTheme("ink") === "ink", "Ink theme must load for custom color contrast");
                        Settings.set("accent", "#202020");
                        root.check(String(Theme.primary) === "#202020" && root.contrast(Theme.textPrimary, Theme.primary) >= 4.5,
                            "A dark custom color must keep the selected wallpaper checkmark readable");
                        root.check(Theme.setTheme("aero") === "aero", "Aero theme must load for custom palette isolation");
                        Settings.set("accent", "#527de0");
                        root.customPanel = Theme.themePanel;
                        root.sampleWallpaper("unrelated", Array(32).fill("45 200 195"));
                        root.phase = 8;
                    } else if (root.phase === 8) {
                        root.check(Qt.colorEqual(Theme.themePanel, root.customPanel),
                            "Changing wallpaper must not recolor a Custom palette");
                        Settings.reset("accent");
                        root.themePalettes = root.defaultPalettes();
                        root.sampleWallpaper("another-default", Array(32).fill("235 76 123"));
                        root.phase = 9;
                    } else if (root.phase === 9) {
                        var after = root.defaultPalettes();
                        for (var id of Object.keys(after))
                            root.check(JSON.stringify(after[id]) === JSON.stringify(root.themePalettes[id]),
                                id + " palette must not change with wallpaper in Theme mode");
                        root.check(Theme.setTheme("liquid") === "liquid", "Liquid Glass must load in Theme mode");
                        var glassPanel = Qt.tint(Qt.rgba(0, 0, 0, 1), Theme.panel);
                        root.check(root.contrast(Theme.primaryIndicator, glassPanel) >= 4.5,
                            "Fixed frosted panels must keep notification names readable");
                        Settings.set("accent", "#999999");
                        root.check(Theme.primary.hslSaturation < 0.02 && Theme.buttonDefault.hslSaturation < 0.02,
                            "A gray Custom color must not introduce red-tinted Liquid Glass controls");
                        Settings.set("accent", "wallpaper");
                        root.sampleWallpaper("legacy-dark", Array(32).fill("32 32 32"));
                        root.phase = 10;
                    } else if (Theme.wallpaperColor.hslLightness < 0.2) {
                        var legacy = { accent: "wallpaper", colors: { rim: { h: 0, s: 0.55, l: 0.72 } } };
                        var rim = Theme.specColor(legacy, "rim", "transparent");
                        root.check(Math.abs(rim.hslLightness - 0.72) < 0.01,
                            "Opting into Wallpaper must preserve a legacy theme's decorative tone lightness");
                        console.log("PASS QML regression tests: wallpaper composition and fixed theme palettes");
                        Qt.quit();
                    }
                }
            } catch (error) {
                console.error("FAIL " + error.message);
                Qt.quit();
            }
        }
    }

    function loadLightFillTheme() {
        var path = writeFixture("theme.json", JSON.stringify({
            name: "Light fills",
            colors: { surface: "#eeeeee", panel: "#aaeeeeee", textSurface: "#111111", primaryContainer: "#eeeeee", buttonDefault: "#eeeeee", textPrimaryContainer: "#111111", textButtonDefault: "#111111" }
        }));
        Theme.setTheme(path.slice(0, -"/theme.json".length));
        check(Theme.name === "Light fills", "Custom light-fill theme must load");
    }
}
