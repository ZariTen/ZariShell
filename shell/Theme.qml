pragma Singleton
import QtQuick
import Quickshell

// Material 3-style tonal palette derived from the current wallpaper. A
// ColorQuantizer samples the image; the most vivid sampled color gives the
// seed hue, and every token is a fixed tone of that hue (mid-tone glass scheme).
Singleton {
    id: root

    readonly property real hue: {
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

    function tone(h, s, l, a) {
        return Qt.hsla(((h % 1) + 1) % 1, s, l, a === undefined ? 1 : a);
    }

    // Windows 7 Aero palette: translucent blue-ish glass that follows the
    // wallpaper hue (like Win7's "color of windows"); everything else is
    // fixed tones of it. Mid-tone glass keeps white text readable while the
    // sheen/edge highlights still pop.
    // Note: never name a property on<Capital>…; QML parses that as a signal
    // handler (e.g. "onSurface" for "surface"), leaving it unset (black).
    readonly property color glassTint: tone(hue - 0.02, 0.55, 0.36, 0.52)
    readonly property color glassTintStrong: tone(hue, 0.5, 0.28, 0.80)
    readonly property color glow: tone(hue - 0.06, 0.95, 0.64)          // Aero hover glow (cyan)
    readonly property color glowSoft: tone(hue - 0.06, 0.95, 0.64, 0.35)
    readonly property color sheenTop: Qt.rgba(1, 1, 1, 0.20)
    readonly property color sheenMid: Qt.rgba(1, 1, 1, 0.07)
    readonly property color edgeLight: Qt.rgba(1, 1, 1, 0.26)            // 1px inner border
    readonly property color edgeDark: Qt.rgba(0, 0, 0, 0.75)             // 1px outer border

    readonly property color primary: tone(hue - 0.03, 0.9, 0.55)
    readonly property color textPrimary: "#ffffff"
    readonly property color primaryContainer: tone(hue, 0.75, 0.32, 0.85)
    readonly property color textPrimaryContainer: "#ffffff"
    readonly property color secondary: tone(hue, 0.35, 0.72)
    readonly property color secondaryContainer: tone(hue, 0.6, 0.42, 0.45)
    readonly property color textSecondaryContainer: "#ffffff"
    readonly property color tertiary: "#b4d455"                          // wallpaper's leaf green
    readonly property color tertiaryContainer: "#3d5a12"
    readonly property color surface: tone(hue, 0.4, 0.12)
    readonly property color surfaceContainerLow: tone(hue, 0.6, 0.62, 0.10)
    readonly property color surfaceContainer: tone(hue, 0.6, 0.62, 0.16)
    readonly property color surfaceContainerHigh: tone(hue, 0.6, 0.62, 0.26)
    readonly property color surfaceContainerHighest: Qt.rgba(1, 1, 1, 0.12)
    // Recessed wells (slider tracks, search/password fields, list wells):
    // a deeper, hue-tinted tone of the glass instead of pure black.
    readonly property color inset: tone(hue, 0.55, 0.16, 0.50)
    readonly property color insetBorder: tone(hue, 0.5, 0.10, 0.65)
    readonly property color textSurface: "#ffffff"
    readonly property color textSurfaceVariant: Qt.rgba(1, 1, 1, 0.72)
    readonly property color outline: Qt.rgba(1, 1, 1, 0.45)
    readonly property color outlineVariant: Qt.rgba(1, 1, 1, 0.16)
    readonly property color scrim: Qt.rgba(0, 0, 0, 0.35)
    readonly property color error: "#ff6b5e"
    readonly property color errorContainer: "#6e0f0a"
    readonly property color success: "#7fd45a"
    readonly property color warning: "#f2c94c"

    readonly property color glass: glassTint
    readonly property color glassStrong: glassTintStrong

    // Shape, spacing, type
    readonly property int radiusSmall: 3
    readonly property int radius: 5
    readonly property int radiusLarge: 8
    readonly property int radiusFull: 999
    readonly property int spacingXs: 4
    readonly property int spacingS: 8
    readonly property int spacingM: 12
    readonly property int spacingL: 16
    readonly property int spacingXl: 24
    readonly property int barHeight: 42
    readonly property int gap: 8
    readonly property string font: "Noto Sans"
    readonly property string iconFont: "JetBrainsMono Nerd Font"
    readonly property int fontSmall: 11
    readonly property int fontBody: 13
    readonly property int fontTitle: 15
    readonly property int fontHeadline: 22

    // Motion (M3 emphasized / standard)
    readonly property int durShort: 150
    readonly property int durMedium: 280
    readonly property int durLong: 420
    readonly property var emphasized: [0.05, 0, 0.133, 0.06, 0.166, 0.4, 0.208, 0.82, 0.25, 1, 1, 1]
    readonly property var standard: [0.2, 0, 0, 1, 1, 1]

    // Nerd Font Material Design glyphs.
    function icon(codepoint) {
        return String.fromCodePoint(codepoint);
    }

    function fileUrl(path) {
        return path === "" ? "" : "file://" + encodeURIComponent(path).replace(/%2F/g, "/");
    }

    ColorQuantizer {
        id: quantizer
        source: root.fileUrl(Wallpaper.path)
        depth: 3
        rescaleSize: 96
    }
}
