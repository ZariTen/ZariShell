pragma Singleton
import QtQuick
import Quickshell

// Wallpaper folder and default image. Set by the Home Manager module through
// ZARISHELL_WALLPAPER_DIR / ZARISHELL_WALLPAPER; the picker's saved choice
// (statePath("wallpaper")) overrides the default at runtime.
QtObject {
    readonly property string dir: Quickshell.env("ZARISHELL_WALLPAPER_DIR")
        || (Quickshell.env("HOME") + "/Pictures/Wallpapers")
    property string path: Quickshell.env("ZARISHELL_WALLPAPER") || ""
}
