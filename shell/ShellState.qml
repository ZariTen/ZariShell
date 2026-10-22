pragma Singleton
import QtQuick
import Quickshell.Services.Mpris

QtObject {
    property string panel: ""
    property string settingsSection: "appearance"   // open page of the settings panel

    // Media player picked in the media panel; falls back to the playing one.
    property var chosenPlayer: null
    readonly property var player: {
        var all = Mpris.players.values;
        if (chosenPlayer && all.indexOf(chosenPlayer) !== -1)
            return chosenPlayer;
        for (var i = 0; i < all.length; i++) {
            if (all[i].isPlaying)
                return all[i];
        }
        return all.length > 0 ? all[0] : null;
    }

    signal lockRequested

    function toggle(name) {
        panel = panel === name ? "" : name;
    }

    function close() {
        panel = "";
    }
}
