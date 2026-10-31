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
// Active theme: the folder at <XDG_CONFIG_HOME>/zarishell/current (a symlink
// updated by the theme picker or `quickshell -c shell ipc call theme ...`),
// else the packaged themes/<$ZARISHELL_THEME or "aero"> next to this file.
// Every token falls back to the neutral defaults below, so an empty theme
// (such as themes/base) gives the plain flat base look.
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

    // -- Active theme identity and discovered themes ------------------------
    property var themes: []

    readonly property string dir: activeTheme.dir
    readonly property var spec: activeTheme.spec
    readonly property string currentId: activeTheme.id
    readonly property string name: typeof spec.name === "string" && spec.name !== "" ? spec.name : currentId

    // -- Colors (neutral defaults: flat translucent slate, white text) ------
    readonly property color surface: color("surface", "#24282e")              // desktop behind the wallpaper
    readonly property color themeBar: color("bar", [0.21, 0.23, 0.26, 0.92])
    readonly property color themePanel: color("panel", [0.24, 0.26, 0.30, 0.96])
    readonly property color bar: withAlpha(themeBar, Settings.get("barOpacity", themeBar.a))         // taskbar
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

    // -- User scale factors (settings.json; 1 = as the theme says) ----------
    readonly property real uiScale: clamp(Settings.get("scale", 1), 0.5, 2)
    readonly property real radiusScale: clamp(Settings.get("radius", 1), 0, 3)
    readonly property real spacingScale: clamp(Settings.get("spacing", 1), 0.25, 3)
    readonly property real fontScale: clamp(Settings.get("fontSize", themeFontBody) / themeFontBody, 0.5, 3)
    readonly property real iconScale: clamp(Settings.get("iconSize", 16) / 16, 0.5, 3)
    readonly property real widthScale: clamp(Settings.get("panelWidth", 1), 0.5, 2)
    readonly property real dimLevel: clamp(Settings.get("dim", 0.5), 0.05, 1)
    readonly property real speed: clamp(Settings.get("animationSpeed", 1), 0.1, 5)
    readonly property bool reduceMotion: Settings.get("reduceMotion", false)

    // -- Shape and spacing --------------------------------------------------
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
    readonly property int shadowRoom: px(metric("shadowRoom", 0))        // extra bar window height for a theme's shadow
    // Bar layout: "full" (edge-to-edge strip) or "pills" (one floating pill per
    // group of bar content). settings.json wins over theme.json "barStyle".
    readonly property string themeBarStyle: spec.barStyle === "pills" ? "pills" : "full"
    readonly property string userBarStyle: Settings.get("barStyle", "")
    readonly property string barStyle: userBarStyle === "pills" || userBarStyle === "full" ? userBarStyle : themeBarStyle
    readonly property bool barPills: barStyle === "pills"
    readonly property int barMargin: barPills ? spacingS : 0             // pill gap from the screen edges
    readonly property int barSpace: barHeight + barMargin                // screen height the bar reserves
    readonly property int gap: spacingMetric("gap", 8)
    readonly property int avatarSize: px(clamp(Settings.get("avatarSize", 112), 48, 256)) // lock screen avatar

    // -- Typography ---------------------------------------------------------
    readonly property int themeFontBody: fontValue("fontBody", 13)
    readonly property string themeFont: fontValue("font", "sans-serif")
    readonly property string font: Settings.get("font", "") !== "" ? Settings.get("font", "") : themeFont
    readonly property string iconFont: fontValue("iconFont", "JetBrainsMono Nerd Font Propo")
    readonly property int fontSmall: fontSize("fontSmall", 11)
    readonly property int fontBody: fontSize("fontBody", 13)
    readonly property int fontTitle: fontSize("fontTitle", 15)
    readonly property int fontHeadline: fontSize("fontHeadline", 22)
    readonly property int fontLarge: fontSize("fontLarge", 34)          // calendar clock
    readonly property int fontDisplay: fontSize("fontDisplay", 112)     // lock / login clock
    readonly property int fontDisplayWeight: fontValue("fontDisplayWeight", Font.Light)

    // -- Motion (M3 emphasized / standard) ----------------------------------
    readonly property int durShort: dur(motion("durShort", 150))
    readonly property int durMedium: dur(motion("durMedium", 280))
    readonly property int durLong: dur(motion("durLong", 420))
    readonly property var emphasized: motion("emphasized", [0.05, 0, 0.133, 0.06, 0.166, 0.4, 0.208, 0.82, 0.25, 1, 1, 1])
    readonly property var standard: motion("standard", [0.2, 0, 0, 1, 1, 1])

    // -- Internal paths and active-theme state ------------------------------
    readonly property string configDir: (Quickshell.env("XDG_CONFIG_HOME") || (Quickshell.env("HOME") + "/.config")) + "/zarishell"
    readonly property string userThemeLink: configDir + "/current"
    readonly property string userThemesDir: configDir + "/themes"
    readonly property string packagedThemesDir: Quickshell.shellDir + "/themes"
    readonly property string packagedThemeName: Quickshell.env("ZARISHELL_THEME") || "aero"
    readonly property string packagedThemePath: packagedThemesDir + "/" + packagedThemeName
    readonly property string themesScriptPath: Quickshell.shellDir + "/scripts/themes.sh"

    // Atomic active-theme snapshot { id, source, dir, spec, revision } so
    // component() never observes a mismatched (dir, spec.components) pair.
    property var loadedThemeState: null
    property bool isReloadingFile: false
    property string pendingSymlinkTarget: ""

    readonly property var initialUserSpec: parseThemeJson(activeThemeFile.text(), activeThemeFile.path)
    readonly property var initialPackagedSpec: parseThemeJson(packagedThemeFile.text(), packagedThemeFile.path)
    readonly property var fallbackThemeState: ({
        id: initialUserSpec !== null ? "current" : packagedThemeName,
        source: initialUserSpec !== null ? "user" : "packaged",
        dir: initialUserSpec !== null ? userThemeLink : packagedThemePath,
        spec: (initialUserSpec !== null ? initialUserSpec : initialPackagedSpec) || ({}),
        revision: 0
    })
    readonly property var activeTheme: loadedThemeState !== null ? loadedThemeState : fallbackThemeState

    // -- Internal accent derivation -----------------------------------------
    readonly property string themeAccent: typeof spec.accent === "string" && spec.accent !== "" ? spec.accent : "#7a9cc6"
    readonly property string userAccentOverride: Settings.get("accent", "")
    readonly property string accentMode: userAccentOverride !== "" ? userAccentOverride : themeAccent
    readonly property bool wallpaperAccent: accentMode === "wallpaper"
    readonly property color accentSeed: wallpaperAccent ? tone(hue, 0.6, 0.6) : accentMode

    // Hue of the most vivid wallpaper color, or -1 when none has a hue.
    readonly property real sampledWallpaperHue: {
        var bestScore = -1;
        var selectedHue = -1;
        var palette = quantizer.colors;
        for (var i = 0; i < palette.length; i++) {
            var sampleColor = palette[i];
            var vividnessScore = sampleColor.hslSaturation * (1 - Math.abs(sampleColor.hslLightness - 0.5) * 1.6);
            if (sampleColor.hslHue >= 0 && vividnessScore > bestScore) {
                bestScore = vividnessScore;
                selectedHue = sampleColor.hslHue;
            }
        }
        return selectedHue;
    }
    readonly property real wallpaperHue: sampledWallpaperHue >= 0 ? sampledWallpaperHue : 0.62
    readonly property color fixedSeed: wallpaperAccent ? "#000000" : accentMode
    // A user accent whose RGB channels spread less than this (chroma, 0..1,
    // about 8/255) is a gray, white or black: its hue is noise, so hue tones
    // follow the wallpaper hue instead, else the theme's own accent hue.
    readonly property real grayAccentChroma: 0.03
    readonly property bool grayUserAccent: userAccentOverride !== "" && !wallpaperAccent && fixedSeed.hsvSaturation * fixedSeed.hsvValue < grayAccentChroma
    readonly property real themeAccentHue: themeAccent === "wallpaper" ? wallpaperHue : Math.max(0, Qt.lighter(themeAccent, 1).hslHue)
    readonly property real hue: {
        if (wallpaperAccent)
            return wallpaperHue;
        if (!grayUserAccent)
            return Math.max(0, fixedSeed.hslHue);
        return sampledWallpaperHue >= 0 ? sampledWallpaperHue : themeAccentHue;
    }

    // -- Public API helpers -------------------------------------------------
    // URL of the look for a generic component: the theme's override when the
    // theme lists it, else the neutral one in base/.
    function component(componentName) {
        var snapshot = activeTheme;
        var componentNames = Array.isArray(snapshot.spec.components) ? snapshot.spec.components : [];
        if (componentNames.indexOf(componentName) >= 0)
            return fileUrl(snapshot.dir + "/components/" + componentName + ".qml") + "?r=" + snapshot.revision;
        return Qt.resolvedUrl("base/" + componentName + ".qml");
    }

    // Optional layer effect a theme may provide (e.g. "Glow"); null when the
    // theme has none, so `layer.enabled: Theme.effect(..) !== null` is a no-op.
    function effect(effectName) {
        var snapshot = activeTheme;
        var componentNames = Array.isArray(snapshot.spec.components) ? snapshot.spec.components : [];
        if (componentNames.indexOf(effectName) >= 0)
            return Qt.createComponent(component(effectName));
        return null;
    }

    // Theme color by name (also for theme-specific extras used by a theme's
    // own components), with a fallback.
    function color(key, fallbackValue) {
        var rawValue = lookup("colors", key);
        return rawValue === undefined ? toColor(fallbackValue) : toColor(rawValue);
    }

    // Resolve a color token from an arbitrary theme.json object (used by the
    // theme picker to render preview swatches for inactive themes).
    function specColor(themeSpec, key, fallbackValue) {
        var specAccentMode = "#7a9cc6";
        if (themeSpec && typeof themeSpec.accent === "string" && themeSpec.accent !== "")
            specAccentMode = themeSpec.accent;

        var usesWallpaper = specAccentMode === "wallpaper";
        var previewSeed = usesWallpaper ? tone(wallpaperHue, 0.6, 0.6, 1) : Qt.lighter(specAccentMode, 1);
        var previewHue = usesWallpaper ? wallpaperHue : Math.max(0, previewSeed.hslHue);
        var colorSection = themeSpec && themeSpec.colors;
        var rawValue = fallbackValue;
        if (colorSection !== null && typeof colorSection === "object" && colorSection[key] !== undefined)
            rawValue = colorSection[key];

        var resolved = resolveColorValue(rawValue, previewHue, previewSeed);
        return typeof resolved === "string" ? Qt.lighter(resolved, 1) : resolved;
    }

    // Whether a theme.json's colors follow the accent setting: its
    // "accentColor" flag when set, else true when a color is "accent" or a
    // hue tone, or when an accent-based token is left at its default.
    function followsAccent(themeSpec) {
        if (!themeSpec)
            return true;
        if (typeof themeSpec.accentColor === "boolean")
            return themeSpec.accentColor;
        var colorSection = themeSpec.colors !== null && typeof themeSpec.colors === "object" ? themeSpec.colors : ({});
        var accentTokens = ["accent", "highlight", "primary", "primaryContainer", "buttonDefault"];
        for (var i = 0; i < accentTokens.length; i++) {
            if (colorSection[accentTokens[i]] === undefined)
                return true;
        }
        for (var key in colorSection) {
            var rawValue = colorSection[key];
            if (rawValue === "accent" || (rawValue !== null && typeof rawValue === "object" && !Array.isArray(rawValue)))
                return true;
        }
        return false;
    }

    // Layout size (px at scale 1) at the current UI scale.
    function px(pixels) {
        return Math.round(pixels * uiScale);
    }

    // Icon glyph size: UI scale and the icon size setting.
    function iconPx(pixels) {
        return Math.round(pixels * uiScale * iconScale);
    }

    // Literal text size: UI scale and the font size setting.
    function fontPx(pixels) {
        return Math.round(pixels * uiScale * fontScale);
    }

    // Panel / card width: UI scale and the panel width setting.
    function widthPx(pixels) {
        return Math.round(pixels * uiScale * widthScale);
    }

    // Opacity of a disabled / hint element (baseOpacity = its value at the
    // default dim level 0.5).
    function dim(baseOpacity) {
        return clamp(baseOpacity * dimLevel / 0.5, 0, 1);
    }

    // Transition duration (ms): animation speed, 0 with reduce motion.
    function dur(milliseconds) {
        return reduceMotion ? 0 : Math.round(milliseconds / speed);
    }

    // Nerd Font Material Design glyphs.
    function icon(codepoint) {
        return String.fromCodePoint(codepoint);
    }

    function fileUrl(filePath) {
        return filePath === "" ? "" : "file://" + encodeURIComponent(filePath).replace(/%2F/g, "/");
    }

    function setTheme(nameOrPath) {
        var query = (nameOrPath || "").trim();
        if (query === "")
            return currentId;

        var candidates = [];
        for (var i = 0; i < themes.length; i++) {
            var knownTheme = themes[i];
            var queryLower = query.toLowerCase();
            if (knownTheme.id === query
                || knownTheme.path === query
                || knownTheme.realPath === query
                || knownTheme.id.toLowerCase() === queryLower
                || knownTheme.name.toLowerCase() === queryLower) {
                candidates.push({ id: knownTheme.id, path: knownTheme.path, source: knownTheme.source });
                break;
            }
        }

        if (query.indexOf("/") === 0 || query.indexOf("~/") === 0) {
            var expandedPath = query.indexOf("~/") === 0 ? (Quickshell.env("HOME") + query.slice(1)) : query;
            var cleanPath = expandedPath.replace(/\/+$/, "");
            candidates.push({ id: directoryName(cleanPath), path: cleanPath, source: classifyThemePath(cleanPath) });
        } else {
            candidates.push({ id: query, path: userThemesDir + "/" + query, source: "user" });
            candidates.push({ id: query, path: packagedThemesDir + "/" + query, source: "packaged" });
        }

        for (var j = 0; j < candidates.length; j++) {
            var candidate = candidates[j];
            if (loadThemeDirectory(candidate.path, candidate.id, candidate.source, true)) {
                writeThemeSymlink(candidate.path);
                return currentId;
            }
        }

        console.warn("Theme: unknown or invalid theme '" + query + "'");
        return currentId;
    }

    function stepTheme(stepDelta) {
        if (themes.length === 0)
            return currentId;
        var currentIndex = -1;
        for (var i = 0; i < themes.length; i++) {
            if (themes[i].id === currentId) {
                currentIndex = i;
                break;
            }
        }
        var nextIndex = currentIndex >= 0 ? (currentIndex + stepDelta + themes.length) % themes.length : 0;
        return setTheme(themes[nextIndex].id);
    }

    function reload() {
        loadThemeDirectory(activeTheme.dir, activeTheme.id, activeTheme.source, true);
        scan();
        return currentId;
    }

    function scan() {
        if (!scanProcess.running)
            scanProcess.running = true;
    }

    // -- Internal token helpers ---------------------------------------------
    function clamp(value, minValue, maxValue) {
        return Math.max(minValue, Math.min(maxValue, value));
    }

    function tone(hueValue, saturation, lightness, alpha) {
        return Qt.hsla(((hueValue % 1) + 1) % 1, saturation, lightness, alpha === undefined ? 1 : alpha);
    }

    function lookup(sectionName, key) {
        var section = spec[sectionName];
        if (section !== null && typeof section === "object" && section[key] !== undefined)
            return section[key];
        return undefined;
    }

    function resolveColorValue(rawValue, baseHue, seedColor) {
        if (rawValue === "accent")
            return seedColor;
        if (Array.isArray(rawValue)) {
            var alpha = rawValue.length > 3 ? rawValue[3] : 1;
            return Qt.rgba(rawValue[0], rawValue[1], rawValue[2], alpha);
        }
        if (rawValue !== null && typeof rawValue === "object" && rawValue.hslHue === undefined) {
            var hueOffset = rawValue.h || 0;
            var saturation = rawValue.s === undefined ? 0.5 : rawValue.s;
            var lightness = rawValue.l === undefined ? 0.5 : rawValue.l;
            return tone(baseHue + hueOffset, saturation, lightness, rawValue.a);
        }
        return rawValue;
    }

    function toColor(rawValue) {
        return resolveColorValue(rawValue, hue, accentSeed);
    }

    function withAlpha(colorValue, alphaValue) {
        if (alphaValue === colorValue.a)
            return colorValue;
        return Qt.rgba(colorValue.r, colorValue.g, colorValue.b, clamp(alphaValue, 0, 1));
    }

    function metric(key, fallbackValue) {
        var rawValue = lookup("metrics", key);
        return typeof rawValue === "number" ? rawValue : fallbackValue;
    }

    function fontValue(key, fallbackValue) {
        var rawValue = lookup("fonts", key);
        return rawValue === undefined ? fallbackValue : rawValue;
    }

    function motion(key, fallbackValue) {
        var rawValue = lookup("motion", key);
        return rawValue === undefined ? fallbackValue : rawValue;
    }

    function radiusMetric(key, fallbackValue) {
        return Math.round(metric(key, fallbackValue) * uiScale * radiusScale);
    }

    function spacingMetric(key, fallbackValue) {
        return Math.round(metric(key, fallbackValue) * uiScale * spacingScale);
    }

    function fontSize(key, fallbackValue) {
        return Math.round(fontValue(key, fallbackValue) * uiScale * fontScale);
    }

    // -- Internal theme discovery and loading helpers -----------------------
    function parseThemeJson(jsonText, filePath) {
        if (!jsonText || jsonText.trim() === "")
            return null;
        try {
            var parsed = JSON.parse(jsonText);
            if (parsed !== null && typeof parsed === "object" && !Array.isArray(parsed))
                return parsed;
            return null;
        } catch (parseError) {
            console.warn("Theme: invalid JSON in " + filePath + ": " + parseError);
            return null;
        }
    }

    function directoryName(dirPath) {
        var cleanPath = dirPath.replace(/\/+$/, "");
        var slashIndex = cleanPath.lastIndexOf("/");
        return slashIndex >= 0 ? cleanPath.slice(slashIndex + 1) : cleanPath;
    }

    function classifyThemePath(dirPath) {
        if (dirPath.indexOf(userThemesDir + "/") === 0)
            return "user";
        if (dirPath.indexOf(packagedThemesDir + "/") === 0)
            return "packaged";
        return "custom";
    }

    function sortThemes(themeList) {
        var builtinRank = { "aero": 0, "base": 1 };
        themeList.sort(function(first, second) {
            var firstRank = builtinRank[first.id] !== undefined ? builtinRank[first.id] : 2;
            var secondRank = builtinRank[second.id] !== undefined ? builtinRank[second.id] : 2;
            if (firstRank !== secondRank)
                return firstRank - secondRank;
            if (first.id < second.id)
                return -1;
            return first.id > second.id ? 1 : 0;
        });
        return themeList;
    }

    function createThemeEntry(themeId, themePath, realPath, sourceType, parsedSpec) {
        var displayName = typeof parsedSpec.name === "string" && parsedSpec.name !== "" ? parsedSpec.name : themeId;
        var description = typeof parsedSpec.description === "string" ? parsedSpec.description : "";
        var componentList = Array.isArray(parsedSpec.components) ? parsedSpec.components : [];
        return {
            id: themeId,
            name: displayName,
            description: description,
            source: sourceType,
            path: themePath,
            realPath: realPath,
            spec: parsedSpec,
            componentsCount: componentList.length
        };
    }

    function watchThemeFile(jsonPath) {
        isReloadingFile = true;
        if (activeThemeFile.path !== jsonPath)
            activeThemeFile.path = jsonPath;
        else
            activeThemeFile.reload();
        activeThemeFile.waitForJob();
        isReloadingFile = false;
    }

    function loadThemeDirectory(targetDir, themeId, sourceType, incrementRevision) {
        var jsonPath = targetDir + "/theme.json";
        var previousSnapshot = activeTheme;
        watchThemeFile(jsonPath);

        var parsedSpec = parseThemeJson(activeThemeFile.text(), jsonPath);
        if (parsedSpec === null)
            return false;

        var nextRevision = previousSnapshot.revision + (incrementRevision ? 1 : 0);
        loadedThemeState = {
            id: themeId,
            source: sourceType,
            dir: targetDir,
            spec: parsedSpec,
            revision: nextRevision
        };

        var updatedThemes = themes.slice();
        var updatedExisting = false;
        for (var i = 0; i < updatedThemes.length; i++) {
            if (updatedThemes[i].id === themeId) {
                var resolvedPath = updatedThemes[i].realPath || targetDir;
                updatedThemes[i] = createThemeEntry(themeId, targetDir, resolvedPath, sourceType, parsedSpec);
                updatedExisting = true;
                break;
            }
        }
        if (!updatedExisting)
            updatedThemes.push(createThemeEntry(themeId, targetDir, targetDir, sourceType, parsedSpec));
        themes = sortThemes(updatedThemes);
        return true;
    }

    function writeThemeSymlink(targetDir) {
        pendingSymlinkTarget = targetDir;
        if (symlinkProcess.running)
            symlinkProcess.running = false;
        symlinkProcess.running = true;
    }

    function resolveActiveThemeEntry(currentLinkPath, currentRealPath, themesById) {
        if (currentRealPath !== "") {
            for (var i = 0; i < themes.length; i++) {
                var candidate = themes[i];
                if (candidate.realPath === currentRealPath || candidate.path === currentRealPath || candidate.path === currentLinkPath)
                    return candidate;
            }
        }
        if (currentLinkPath !== "") {
            var linkId = directoryName(currentLinkPath);
            if (themesById[linkId])
                return themesById[linkId];
        }
        if (themesById[packagedThemeName])
            return themesById[packagedThemeName];
        return themes.length > 0 ? themes[0] : null;
    }

    function applyScannedTheme(matchedTheme, currentLinkPath, currentRealPath) {
        var isFirstLoad = loadedThemeState === null;
        var previousSnapshot = activeTheme;
        var hasUserTheme = initialUserSpec !== null;
        var isSameTarget = false;

        if (isFirstLoad) {
            var matchesUserLink = hasUserTheme && (currentRealPath === matchedTheme.realPath || currentLinkPath === matchedTheme.path);
            var matchesPackagedDefault = !hasUserTheme && matchedTheme.path === packagedThemePath;
            isSameTarget = matchesUserLink || matchesPackagedDefault;
        } else {
            isSameTarget = previousSnapshot.dir === matchedTheme.path
                && JSON.stringify(previousSnapshot.spec) === JSON.stringify(matchedTheme.spec);
        }

        loadedThemeState = {
            id: matchedTheme.id,
            source: matchedTheme.source,
            dir: matchedTheme.path,
            spec: matchedTheme.spec,
            revision: previousSnapshot.revision + (isSameTarget ? 0 : 1)
        };

        var targetJsonPath = matchedTheme.path + "/theme.json";
        if (activeThemeFile.path !== targetJsonPath)
            watchThemeFile(targetJsonPath);

        var needsSymlinkRepair = currentLinkPath !== ""
            && matchedTheme.path !== ""
            && (currentRealPath === "" || (matchedTheme.source === "packaged" && currentRealPath !== matchedTheme.realPath));
        if (needsSymlinkRepair)
            writeThemeSymlink(matchedTheme.path);
    }

    function ingestScanOutput(outputText) {
        var lines = outputText.split("\n");
        var currentLinkPath = "";
        var currentRealPath = "";
        var discoveredThemes = [];
        var themesById = {};
        var themesByRealPath = {};

        for (var i = 0; i < lines.length; i++) {
            var line = lines[i];
            if (line.indexOf("CURRENT\t") === 0) {
                var currentParts = line.split("\t");
                currentLinkPath = currentParts[1] || "";
                currentRealPath = currentParts[2] || "";
                continue;
            }
            if (line.indexOf("THEME\t") !== 0)
                continue;

            var parts = line.split("\t");
            var themePath = parts[1] || "";
            var realPath = parts[2] || themePath;
            var jsonText = parts.slice(3).join("\t");
            var parsedSpec = parseThemeJson(jsonText, themePath + "/theme.json");
            if (parsedSpec === null)
                continue;

            var themeId = directoryName(themePath);
            if (themesById[themeId] || themesByRealPath[realPath])
                continue;

            var entry = createThemeEntry(themeId, themePath, realPath, classifyThemePath(themePath), parsedSpec);
            themesById[themeId] = entry;
            themesByRealPath[realPath] = entry;
            discoveredThemes.push(entry);
        }

        themes = sortThemes(discoveredThemes);
        if (symlinkProcess.running)
            return;

        var matchedTheme = resolveActiveThemeEntry(currentLinkPath, currentRealPath, themesById);
        if (matchedTheme !== null)
            applyScannedTheme(matchedTheme, currentLinkPath, currentRealPath);
    }

    // -- Lifecycle and background objects -----------------------------------
    Component.onCompleted: scan()

    ColorQuantizer {
        id: quantizer
        source: root.wallpaperAccent || root.grayUserAccent ? root.fileUrl(Wallpaper.path) : ""
        depth: 3
        rescaleSize: 96
    }

    FileView {
        id: activeThemeFile
        path: root.userThemeLink + "/theme.json"
        blockLoading: true
        watchChanges: true
        printErrors: false
        onFileChanged: if (!root.isReloadingFile) root.reload()
    }

    FileView {
        id: packagedThemeFile
        path: root.packagedThemePath + "/theme.json"
        blockLoading: true
        printErrors: false
    }

    Process {
        id: symlinkProcess
        command: ["sh", root.themesScriptPath, "link", root.configDir, root.pendingSymlinkTarget, root.userThemeLink]
        onExited: root.scan()
    }

    Process {
        id: scanProcess
        command: ["sh", root.themesScriptPath, "scan", root.userThemeLink, root.userThemesDir, root.packagedThemesDir]
        stdout: StdioCollector {
            onStreamFinished: root.ingestScanOutput(text)
        }
    }

    IpcHandler {
        target: "theme"

        function list(): string { return root.themes.map(themeEntry => themeEntry.id).join("\n"); }
        function current(): string { return root.currentId; }
        function set(name: string): string { return root.setTheme(name); }
        function next(): string { return root.stepTheme(1); }
        function prev(): string { return root.stepTheme(-1); }
        function reload(): string { return root.reload(); }
    }
}
