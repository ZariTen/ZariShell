pragma Singleton
import QtQuick
import Quickshell

// Greeter override of the shell's Wallpaper singleton (same API, so the shared
// Theme.qml derives its hue from it). If dotfiles/greeter/wallpaper.* exists
// the Nix package renames it to "wallpaper" and sets hasWallpaper; otherwise
// path is empty and Greeter.qml shows the Theme gradient.
QtObject {
    readonly property bool hasWallpaper: false
    readonly property string dir: Quickshell.shellDir
    property string path: hasWallpaper ? Quickshell.shellPath("wallpaper") : ""
}
