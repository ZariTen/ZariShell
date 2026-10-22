pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Design tokens and component looks for the shell and the greeter.
//
// A theme is a folder: theme.json (tokens) plus optional components/<Name>.qml
// files that replace the look of a generic component (Button, Switch, Slider,
// Surface, Highlight, Field). theme.json lists those names in "components".
//
// Active theme: the folder at <XDG_CONFIG_HOME>/zarishell/current (meant to be
// a user-writable symlink), else the packaged themes/<$ZARISHELL_THEME or
// "aero"> next to this file. Every token falls back to the neutral defaults
// below, so an empty theme gives the plain flat base look.
//
// theme.json colors accept "#rrggbb" / "#aarrggbb", [r, g, b, a] (0..1),
// "accent" (the accent seed) or { "h", "s", "l", "a" }: a tone whose hue is
// offset by h from the accent hue. "accent" is "wallpaper" (hue sampled from
// the current wallpaper) or a color.
Singleton {
    id: root

    // ---- Theme resolution -------------------------------------------------
    readonly property string userPath: (Quickshell.env("XDG_CONFIG_HOME") || (Quickshell.env("HOME") + "/.config")) + "/zarishell/current"
    readonly property string packagedName: Quickshell.env("ZARISHELL_THEME") || "aero"
    readonly property string packagedPath: Quickshell.shellDir + "/themes/" + packagedName
    readonly property var userSpec: parse(userFile.text(), userFile.path)
    readonly property var packagedSpec: parse(packagedFile.text(), packagedFile.path)
    readonly property bool userActive: userSpec !== null
    // Folder of the active theme and its parsed theme.json.
    readonly property string dir: userActive ? userPath : packagedPath
    readonly property var spec: (userActive ? userSpec : packagedSpec) || ({})
    readonly property string name: typeof spec.name === "string" ? spec.name : ""
    readonly property var overrides: Array.isArray(spec.components) ? spec.components : []

    function parse(text, path) {
        if (!text || text.trim() === "")
            return null;
        try {
            var o = JSON.parse(text);
            return o !== null && typeof o === "object" && !Array.isArray(o) ? o : null;
        } catch (e) {
            console.warn("Theme: invalid JSON in " + path + ": " + e);
            return null;
        }
    }

    // URL of the look for a generic component: the theme's override when the
    // theme lists it, else the neutral one in base/.
    function component(name) {
        return overrides.indexOf(name) >= 0 ? fileUrl(dir + "/components/" + name + ".qml") : Qt.resolvedUrl("base/" + name + ".qml");
    }

    FileView {
        id: userFile
        path: root.userPath + "/theme.json"
        blockLoading: true
        printErrors: false
    }

    FileView {
        id: packagedFile
        path: root.packagedPath + "/theme.json"
        blockLoading: true
        printErrors: false
    }

    // ---- Accent -----------------------------------------------------------
    readonly property string accentMode: typeof spec.accent === "string" && spec.accent !== "" ? spec.accent : "#7a9cc6"
    readonly property bool wallpaperAccent: accentMode === "wallpaper"
    readonly property color accentSeed: wallpaperAccent ? tone(hue, 0.6, 0.6) : accentMode

    readonly property real wallpaperHue: {
        var best = -1;
        var picked = 0.62;
        var colors = quantizer.colors;
        for (var i = 0; i < colors.length; i++) {
            var c = colors[i];
            var score = c.hslSaturation * (1 - Math.abs(c.hslLightness - 0.5) * 1.6);
            if (c.hslHue >= 0 && score > best) {
                best = score;
                picked = c.hslHue;
            }
        }
        return picked;
    }
    readonly property color fixedSeed: wallpaperAccent ? "#000000" : accentMode
    readonly property real hue: wallpaperAccent ? wallpaperHue : Math.max(0, fixedSeed.hslHue)

    function tone(h, s, l, a) {
        return Qt.hsla(((h % 1) + 1) % 1, s, l, a === undefined ? 1 : a);
    }

    ColorQuantizer {
        id: quantizer
        source: root.wallpaperAccent ? root.fileUrl(Wallpaper.path) : ""
        depth: 3
        rescaleSize: 96
    }

    // ---- Token lookup -----------------------------------------------------
    function lookup(section, key) {
        var s = spec[section];
        return s !== null && typeof s === "object" && s[key] !== undefined ? s[key] : undefined;
    }

    function toColor(v) {
        if (v === "accent")
            return accentSeed;
        if (Array.isArray(v))
            return Qt.rgba(v[0], v[1], v[2], v.length > 3 ? v[3] : 1);
        if (v !== null && typeof v === "object")
            return tone(hue + (v.h || 0), v.s === undefined ? 0.5 : v.s, v.l === undefined ? 0.5 : v.l, v.a);
        return v;
    }

    // Theme color by name (also for theme-specific extras used by a theme's
    // own components), with a fallback.
    function color(key, fallback) {
        var v = lookup("colors", key);
        return v === undefined ? toColor(fallback) : toColor(v);
    }

    function metric(key, fallback) {
        var v = lookup("metrics", key);
        return typeof v === "number" ? v : fallback;
    }

    function fontValue(key, fallback) {
        var v = lookup("fonts", key);
        return v === undefined ? fallback : v;
    }

    function motion(key, fallback) {
        var v = lookup("motion", key);
        return v === undefined ? fallback : v;
    }

    // ---- Colors (neutral defaults: flat translucent slate, white text) ----
    readonly property color surface: color("surface", "#24282e")              // desktop behind the wallpaper
    readonly property color bar: color("bar", [0.21, 0.23, 0.26, 0.92])       // taskbar
    readonly property color panel: color("panel", [0.24, 0.26, 0.30, 0.96])   // panels, dialogs, toasts
    readonly property color panelError: color("panelError", [0.55, 0.16, 0.13, 0.94])
    readonly property color accent: color("accent", "accent")                 // accent icons and text
    readonly property color highlight: color("highlight", "accent")           // hover / selection / active fill
    readonly property color primary: color("primary", "accent")
    readonly property color textPrimary: color("textPrimary", "#ffffff")
    readonly property color primaryContainer: color("primaryContainer", { "h": 0, "s": 0.4, "l": 0.38, "a": 0.9 })
    readonly property color textPrimaryContainer: color("textPrimaryContainer", "#ffffff")
    readonly property color surfaceContainer: color("surfaceContainer", [1, 1, 1, 0.08])
    readonly property color surfaceContainerHigh: color("surfaceContainerHigh", [1, 1, 1, 0.14])
    readonly property color surfaceContainerHighest: color("surfaceContainerHighest", [1, 1, 1, 0.12])
    readonly property color inset: color("inset", [0, 0, 0, 0.22])             // recessed wells (tracks, fields)
    readonly property color insetBorder: color("insetBorder", [0, 0, 0, 0.30])
    readonly property color border: color("border", [0, 0, 0, 0.35])           // outer 1px edge
    readonly property color borderLight: color("borderLight", [1, 1, 1, 0.10]) // inner / subtle edge
    readonly property color textSurface: color("textSurface", "#ffffff")
    readonly property color textSurfaceVariant: color("textSurfaceVariant", [1, 1, 1, 0.70])
    readonly property color outline: color("outline", [1, 1, 1, 0.45])
    readonly property color outlineVariant: color("outlineVariant", [1, 1, 1, 0.16])
    readonly property color scrim: color("scrim", [0, 0, 0, 0.35])
    readonly property color error: color("error", "#ff6b5e")
    readonly property color success: color("success", "#7fd45a")
    readonly property color warning: color("warning", "#f2c94c")

    // ---- Shape and spacing ------------------------------------------------
    readonly property int radiusSmall: metric("radiusSmall", 3)
    readonly property int radius: metric("radius", 5)
    readonly property int radiusLarge: metric("radiusLarge", 8)
    readonly property int radiusFull: metric("radiusFull", 999)
    readonly property int spacingXs: metric("spacingXs", 4)
    readonly property int spacingS: metric("spacingS", 8)
    readonly property int spacingM: metric("spacingM", 12)
    readonly property int spacingL: metric("spacingL", 16)
    readonly property int spacingXl: metric("spacingXl", 24)
    readonly property int barHeight: metric("barHeight", 42)
    readonly property int gap: metric("gap", 8)

    // ---- Type -------------------------------------------------------------
    readonly property string font: fontValue("font", "sans-serif")
    readonly property string iconFont: fontValue("iconFont", "JetBrainsMono Nerd Font Propo")
    readonly property int fontSmall: fontValue("fontSmall", 11)
    readonly property int fontBody: fontValue("fontBody", 13)
    readonly property int fontTitle: fontValue("fontTitle", 15)
    readonly property int fontHeadline: fontValue("fontHeadline", 22)

    // ---- Motion (M3 emphasized / standard) ---------------------------------
    readonly property int durShort: motion("durShort", 150)
    readonly property int durMedium: motion("durMedium", 280)
    readonly property int durLong: motion("durLong", 420)
    readonly property var emphasized: motion("emphasized", [0.05, 0, 0.133, 0.06, 0.166, 0.4, 0.208, 0.82, 0.25, 1, 1, 1])
    readonly property var standard: motion("standard", [0.2, 0, 0, 1, 1, 1])

    // Nerd Font Material Design glyphs.
    function icon(codepoint) {
        return String.fromCodePoint(codepoint);
    }

    function fileUrl(path) {
        return path === "" ? "" : "file://" + encodeURIComponent(path).replace(/%2F/g, "/");
    }
}
