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

    // Wi-Fi strength glyph for a 0..1 signal.
    function wifiGlyph(signalStrength) {
        if (signalStrength < 0.25)
            return 0xF091F;
        if (signalStrength < 0.5)
            return 0xF0922;
        if (signalStrength < 0.75)
            return 0xF0925;
        return 0xF0928;
    }

    // Battery glyph in tenths for a 0..1 charge level.
    function batteryGlyph(chargeLevel) {
        var decile = Math.floor(chargeLevel * 10);
        if (decile >= 10)
            return 0xF0079;
        if (decile < 1)
            return 0xF008E;
        return 0xF007A + decile - 1;
    }
}
