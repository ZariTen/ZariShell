import QtQuick
import Quickshell

ShellRoot {
    Item { id: scene }
    SettingsPanel { id: panel }

    function check(value, message) {
        if (!value) throw new Error(message);
    }
    function spec(key) {
        for (var section of panel.sections) {
            var found = section.rows.find(row => row.key === key);
            if (found) return found;
        }
        throw new Error("Missing setting: " + key);
    }
    function find(item, predicate) {
        if (predicate(item)) return item;
        for (var child of item.children || []) {
            var found = find(child, predicate);
            if (found) return found;
        }
        return null;
    }

    Timer {
        interval: 100
        running: true
        onTriggered: {
            try {
                check(spec("barGap").available === false, "Docked bars must hide floating gap");
                Settings.set("barFloating", true);
                check(spec("barGap").available === true, "Floating bars must expose their gap");
                Settings.set("reduceMotion", true);
                check(spec("animationSpeed").available === false, "Reduced motion must hide animation speed");
                Settings.set("reduceMotion", false);
                check(spec("animationSpeed").available === true, "Animation speed must return when motion is enabled");

                var component = Qt.createComponent(Qt.resolvedUrl("SettingsRow.qml"));
                check(component.status === Component.Ready, component.errorString());
                var accent = component.createObject(scene, {modelData: spec("accent"), width: 480});
                check(accent !== null, "Accent row must load");
                var custom = find(accent, item => item.accentSource === "custom");
                var wallpaper = find(accent, item => item.accentSource === "wallpaper");
                var theme = find(accent, item => item.accentSource === "theme");
                check(custom && wallpaper && theme, "All accent sources must be selectable");
                check(accent.accentMode === "theme", "Unset accent follows theme");
                custom.clicked({button: Qt.LeftButton});
                check(accent.accentMode === "custom" && /^#/.test(Settings.get("accent", "")), "Custom must seed a real color");
                check(accent.colorPickerOpen, "Custom must open color editing");
                wallpaper.clicked({button: Qt.LeftButton});
                check(Settings.get("accent", "") === "wallpaper" && !accent.colorPickerOpen, "Wallpaper must close custom editing");
                theme.clicked({button: Qt.LeftButton});
                check(!Settings.has("accent") && accent.accentMode === "theme", "Theme must remove the override");
                console.log("PASS QML regression tests: dependent settings and accent sources");
            } catch(error) {
                console.error("FAIL QML regression tests: " + error.message);
            }
            Qt.quit();
        }
    }
}
