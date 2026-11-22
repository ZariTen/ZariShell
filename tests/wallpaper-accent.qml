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
    function contrast(foreground, background) {
        var fg = Theme.relativeLuminance(Qt.tint(background, foreground));
        var bg = Theme.relativeLuminance(background);
        return (Math.max(fg, bg) + 0.05) / (Math.min(fg, bg) + 0.05);
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
                    root.check(root.contrast(Theme.error, Qt.tint(Theme.surface, Theme.bar)) >= 4.5,
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
                    Qt.quit();
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
