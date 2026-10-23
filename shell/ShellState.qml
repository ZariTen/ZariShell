pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Services.Mpris

QtObject {
    // -- Public state -------------------------------------------------------
    property string panel: ""
    property string settingsSection: "appearance"   // open page of the settings panel
    property var chosenPlayer: null                 // media player picked in the media panel

    readonly property var player: {
        var players = Mpris.players.values;
        if (chosenPlayer && players.indexOf(chosenPlayer) !== -1)
            return chosenPlayer;
        for (var i = 0; i < players.length; i++) {
            if (players[i].isPlaying)
                return players[i];
        }
        return players.length > 0 ? players[0] : null;
    }

    // -- Signals ------------------------------------------------------------
    signal lockRequested

    // -- Helper functions ---------------------------------------------------
    function toggle(panelName) {
        panel = panel === panelName ? "" : panelName;
    }

    function close() {
        panel = "";
    }

    function isFocusedScreen(screen) {
        if (!screen)
            return false;
        if (Hyprland.focusedMonitor === null)
            return screen === Quickshell.screens[0];
        var monitor = Hyprland.monitorFor(screen);
        return monitor !== null && monitor.name === Hyprland.focusedMonitor.name;
    }

    function focusedScreen() {
        var screens = Quickshell.screens;
        var focusedMonitor = Hyprland.focusedMonitor;
        for (var i = 0; focusedMonitor && i < screens.length; i++) {
            if (screens[i].name === focusedMonitor.name)
                return screens[i];
        }
        return screens[0];
    }

    function volumeGlyph(volumeLevel, isMuted) {
        if (isMuted || volumeLevel <= 0)
            return 0xF0581; // md-volume_off
        if (volumeLevel < 0.34)
            return 0xF057F; // md-volume_low
        if (volumeLevel < 0.67)
            return 0xF0580; // md-volume_medium
        return 0xF057E;     // md-volume_high
    }
}
