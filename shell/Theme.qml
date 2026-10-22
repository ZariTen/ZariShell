pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Design tokens and component looks for the shell and the greeter.
//
// A theme is a folder: theme.json (tokens) plus optional components/<Name>.qml
// files that replace the look of a generic component (Backdrop, Button,
// Divider, Field, Fill, Frame, Highlight, Slider, Surface, Switch) or add an
// optional effect (Glow). theme.json lists those names in "components".
//
// Active theme: the folder at <XDG_CONFIG_HOME>/zarishell/current (meant to be
// a user-writable symlink), else the packaged themes/<$ZARISHELL_THEME or
// "aero"> next to this file. Every token falls back to the neutral defaults
// below, so an empty theme gives the plain flat base look.
//
// theme.json colors accept "#rrggbb" / "#aarrggbb", [r, g, b, a] (0..1),
// "accent" (the accent seed) or { "h", "s", "l", "a" }: a tone whose hue is
// offset by h from the accent hue. "accent" is "wallpaper" (hue sampled from
// the current wallpaper) or a color. Every token is listed in README.md.
//
// User settings (Settings.qml, settings.json) sit on top: scale factors and
// overrides applied here, so shell code only ever reads Theme.*.
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

    // Optional layer effect a theme may provide (e.g. "Glow"); null when the
    // theme has none, so `layer.enabled: Theme.effect(..) !== null` is a no-op.
    function effect(name) {
        return overrides.indexOf(name) >= 0 ? Qt.createComponent(component(name)) : null;
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
    readonly property string themeAccent: typeof spec.accent === "string" && spec.accent !== "" ? spec.accent : "#7a9cc6"
    readonly property string accentMode: Settings.get("accent", "") !== "" ? Settings.get("accent", "") : themeAccent
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
        if (v !== null && typeof v === "object" && v.hslHue === undefined)
            return tone(hue + (v.h || 0), v.s === undefined ? 0.5 : v.s, v.l === undefined ? 0.5 : v.l, v.a);
        return v;
    }

    // Theme color by name (also for theme-specific extras used by a theme's
    // own components), with a fallback.
    function color(key, fallback) {
        var v = lookup("colors", key);
        return v === undefined ? toColor(fallback) : toColor(v);
    }

    function withAlpha(c, a) {
        return a === c.a ? c : Qt.rgba(c.r, c.g, c.b, Math.max(0, Math.min(1, a)));
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
    readonly property color themeBar: color("bar", [0.21, 0.23, 0.26, 0.92])
    readonly property color themePanel: color("panel", [0.24, 0.26, 0.30, 0.96])
    readonly property color bar: withAlpha(themeBar, Settings.get("barOpacity", themeBar.a))       // taskbar
    readonly property color panel: withAlpha(themePanel, Settings.get("panelOpacity", themePanel.a)) // panels, dialogs, toasts
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
    readonly property color scrim: color("scrim", [0, 0, 0, 0.35])              // dim behind popups
    readonly property color scrimStrong: color("scrimStrong", [0, 0, 0, 0.6])   // dim behind modal dialogs
    readonly property color backdrop: color("backdrop", "#000000")             // behind the lock / login backdrop
    readonly property color divider: color("divider", [1, 1, 1, 0.12])
    readonly property color dividerStrong: color("dividerStrong", [1, 1, 1, 0.22])
    readonly property color outlineFaint: color("outlineFaint", [1, 1, 1, 0.08]) // list cards, inner well edge
    readonly property color insetEdge: color("insetEdge", [1, 1, 1, 0.10])     // edge of framed bar trays
    readonly property color buttonDefault: color("buttonDefault", { "h": 0, "s": 0.4, "l": 0.38, "a": 0.63 }) // default dialog button
    readonly property color badge: color("badge", "#d9463a")                   // unread count badge
    readonly property color textSoft: color("textSoft", [1, 1, 1, 0.85])       // secondary display text
    readonly property color textShadow: color("textShadow", "transparent")     // shadow under body text
    readonly property color error: color("error", "#ff6b5e")
    readonly property color success: color("success", "#7fd45a")
    readonly property color warning: color("warning", "#f2c94c")
    readonly property color errorContainer: color("errorContainer", Qt.rgba(error.r, error.g, error.b, 0.22))
    readonly property color errorOutline: color("errorOutline", Qt.rgba(error.r, error.g, error.b, 0.6))
    readonly property color criticalContainer: color("criticalContainer", Qt.rgba(error.r, error.g, error.b, 0.3)) // critical notification card
    readonly property color danger: color("danger", error)                     // destructive action icon
    readonly property color dangerHighlight: color("dangerHighlight", error)   // destructive action hover

    // ---- User scale factors (settings.json; 1 = as the theme says) -------
    readonly property real uiScale: clamp(Settings.get("scale", 1), 0.5, 2)
    readonly property real radiusScale: clamp(Settings.get("radius", 1), 0, 3)
    readonly property real spacingScale: clamp(Settings.get("spacing", 1), 0.25, 3)
    readonly property real fontScale: clamp(Settings.get("fontSize", themeFontBody) / themeFontBody, 0.5, 3)
    readonly property real iconScale: clamp(Settings.get("iconSize", 16) / 16, 0.5, 3)
    readonly property real widthScale: clamp(Settings.get("panelWidth", 1), 0.5, 2)
    readonly property real dimLevel: clamp(Settings.get("dim", 0.5), 0.05, 1)
    readonly property real speed: clamp(Settings.get("animationSpeed", 1), 0.1, 5)
    readonly property bool reduceMotion: Settings.get("reduceMotion", false)

    function clamp(v, lo, hi) {
        return Math.max(lo, Math.min(hi, v));
    }
    // Layout size (px at scale 1) at the current UI scale.
    function px(n) {
        return Math.round(n * uiScale);
    }
    // Icon glyph size: UI scale and the icon size setting.
    function iconPx(n) {
        return Math.round(n * uiScale * iconScale);
    }
    // Literal text size: UI scale and the font size setting.
    function fontPx(n) {
        return Math.round(n * uiScale * fontScale);
    }
    // Panel / card width: UI scale and the panel width setting.
    function widthPx(n) {
        return Math.round(n * uiScale * widthScale);
    }
    // Opacity of a disabled / hint element (v = its value at the default
    // dim level 0.5).
    function dim(v) {
        return clamp(v * dimLevel / 0.5, 0, 1);
    }
    // Transition duration (ms): animation speed, 0 with reduce motion.
    function dur(ms) {
        return reduceMotion ? 0 : Math.round(ms / speed);
    }

    // ---- Shape and spacing ------------------------------------------------
    function radiusMetric(key, d) {
        return Math.round(metric(key, d) * uiScale * radiusScale);
    }
    function spacingMetric(key, d) {
        return Math.round(metric(key, d) * uiScale * spacingScale);
    }
    readonly property int radiusSmall: radiusMetric("radiusSmall", 3)
    readonly property int radius: radiusMetric("radius", 5)
    readonly property int radiusLarge: radiusMetric("radiusLarge", 8)
    readonly property int radiusFull: metric("radiusFull", 999)
    readonly property int radiusFrame: radiusMetric("radiusFrame", 10)   // matted picture frames (avatars)
    readonly property int barRadius: radiusMetric("barRadius", 0)        // full-width edge bars
    readonly property int spacingXs: spacingMetric("spacingXs", 4)
    readonly property int spacingS: spacingMetric("spacingS", 8)
    readonly property int spacingM: spacingMetric("spacingM", 12)
    readonly property int spacingL: spacingMetric("spacingL", 16)
    readonly property int spacingXl: spacingMetric("spacingXl", 24)
    readonly property int themeBarHeight: metric("barHeight", 42)
    readonly property int barHeight: px(clamp(Settings.get("barHeight", themeBarHeight), 24, 96))
    readonly property int shadowRoom: px(metric("shadowRoom", 0))      // extra bar window height for a theme's shadow
    readonly property int gap: spacingMetric("gap", 8)
    readonly property int avatarSize: px(clamp(Settings.get("avatarSize", 112), 48, 256)) // lock screen avatar

    // ---- Type -------------------------------------------------------------
    readonly property int themeFontBody: fontValue("fontBody", 13)
    function fontSize(key, d) {
        return Math.round(fontValue(key, d) * uiScale * fontScale);
    }
    readonly property string themeFont: fontValue("font", "sans-serif")
    readonly property string font: Settings.get("font", "") !== "" ? Settings.get("font", "") : themeFont
    readonly property string iconFont: fontValue("iconFont", "JetBrainsMono Nerd Font Propo")
    readonly property int fontSmall: fontSize("fontSmall", 11)
    readonly property int fontBody: fontSize("fontBody", 13)
    readonly property int fontTitle: fontSize("fontTitle", 15)
    readonly property int fontHeadline: fontSize("fontHeadline", 22)
    readonly property int fontLarge: fontSize("fontLarge", 34)       // calendar clock
    readonly property int fontDisplay: fontSize("fontDisplay", 112)  // lock / login clock
    readonly property int fontDisplayWeight: fontValue("fontDisplayWeight", Font.Light)

    // ---- Motion (M3 emphasized / standard) ---------------------------------
    readonly property int durShort: dur(motion("durShort", 150))
    readonly property int durMedium: dur(motion("durMedium", 280))
    readonly property int durLong: dur(motion("durLong", 420))
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
