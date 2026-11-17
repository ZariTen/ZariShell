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
                var restore = find(accent, item => item.codepoint === 0xF099B);
                check(restore && restore.visible && !restore.enabled, "Default values must show a disabled restore action");
                Settings.set("accent", "#aabbcc");
                check(restore.visible && restore.enabled, "Modified values must enable the restore action");
                restore.Accessible.pressAction();
                check(!Settings.has("accent") && restore.visible && !restore.enabled, "Accessible restore must remove the override and disable the action");
                ShellState.settingsSection = "layout";
                Settings.reset("barFloating");
                Settings.set("barHeight", 50);
                check(panel.sectionModified, "Section restore must include changed values");
                Settings.set("barHeight", spec("barHeight").def);
                check(!panel.sectionModified, "Returning manually to the default must clear section restore");
                var heightRow = component.createObject(scene, {modelData: spec("barHeight"), width: 480});
                var heightEditor = find(heightRow, item => typeof item.commitValue === "function");
                check(heightEditor, "Slider values must offer numeric editing");
                heightEditor.commitValue("51");
                check(Settings.get("barHeight", 42) === 51, "Typed pixels must update the setting");
                check(!heightEditor.commitValue("not a number") && Settings.get("barHeight", 42) === 51, "Invalid text must not change a setting");
                heightEditor.commitValue("999");
                check(Settings.get("barHeight", 42) === spec("barHeight").max, "Typed values must respect the slider range");
                heightEditor.startEditing();
                Settings.set("barHeight", 60);
                check(!heightEditor.editing, "A newer slider or reset value must cancel a pending numeric edit");
                var scaleRow = component.createObject(scene, {modelData: spec("scale"), width: 480});
                var scaleEditor = find(scaleRow, item => typeof item.commitValue === "function");
                scaleEditor.commitValue("113");
                check(Math.abs(Settings.get("scale", 1) - 1.15) < 0.000001, "Typed percentages must use slider units and steps");
                var groupComponent = Qt.createComponent(Qt.resolvedUrl("SettingsGroup.qml"));
                var group = groupComponent.createObject(scene, {rows: [spec("spacing")], width: 480});
                var spacingEditor = find(group, item => typeof item.commitValue === "function");
                check(group && spacingEditor, "Grouped numeric controls must load");
                spacingEditor.startEditing();
                group.cancelEdits();
                check(!spacingEditor.editing, "Cancelling a group must close every numeric edit");
                console.log("PASS QML regression tests: dependent controls, accent, restore and numeric editing");
            } catch(error) {
                console.error("FAIL QML regression tests: " + error.message);
            }
            Qt.quit();
        }
    }
}
