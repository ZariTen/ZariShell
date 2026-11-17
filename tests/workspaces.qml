import QtQuick
import Quickshell

ShellRoot {
    function check(condition, message) {
        if (!condition)
            throw new Error(message);
    }

    function findItem(item, name) {
        if (item.objectName === name)
            return item;
        var children = item.children || [];
        for (var i = 0; i < children.length; i++) {
            var found = findItem(children[i], name);
            if (found)
                return found;
        }
        return null;
    }

    Item { id: scene; width: 600; height: 200 }

    Timer {
        id: rowTest
        property var rowItem
        interval: 100
        function options(item) {
            var result = [];
            if (item.visible && item.modelData && item.modelData.value !== undefined && item.clicked !== undefined)
                result.push(item);
            (item.children || []).forEach(child => { result = result.concat(options(child)); });
            return result;
        }
        onTriggered: {
            try {
                var choice = options(rowItem).find(option => option.modelData.value === "diamonds");
                check(choice !== undefined, "workspace style must offer a nondefault choice");
                choice.clicked({ button: Qt.LeftButton });
                check(Settings.get("workspaceStyle", "") === "diamonds" && Theme.workspaceStyle === "diamonds", "settings choice must update the workspace style");
                Settings.resetKeys(["workspaceStyle"]);
                check(Theme.workspaceStyle === rowItem.modelData.def, "reset must restore the default workspace style");
                Settings.set("workspaceStyle", "diamonds");
                saveTest.start();
            } catch (error) {
                console.error("FAIL workspace tests: " + error.message);
                Qt.quit();
            }
        }
    }

    Timer {
        id: saveTest
        interval: 600
        onTriggered: {
            console.log("PASS workspace tests");
            Qt.quit();
        }
    }

    Timer {
        interval: 600
        running: true
        onTriggered: {
            try {
                if (Quickshell.env("ZARISHELL_TEST_RELOAD") === "1") {
                    check(Settings.get("workspaceStyle", "") === "diamonds" && Theme.workspaceStyle === "diamonds", "selected style must survive a shell restart");
                    check(Settings.get("workspaceTestUnrelated", "") === "preserved", "saving workspace style must preserve unrelated settings");
                    console.log("PASS workspace tests");
                    Qt.quit();
                    return;
                }
                Settings.set("workspaceTestUnrelated", "preserved");
                Settings.set("reduceMotion", true);
                var component = Qt.createComponent(Qt.resolvedUrl("WorkspaceButton.qml"));
                check(component.status === Component.Ready, component.errorString());
                var workspace = Qt.createQmlObject('import QtQuick; QtObject { property string name: "dev"; property bool active: true; property bool urgent: true; property var toplevels: ({ values: [{}] }); property int activations: 0; function activate() { activations++; } }', scene);
                var button = component.createObject(scene, { modelData: workspace });
                check(button !== null, "workspace button must load");
                var marker = findItem(button, "workspaceMarker");
                var label = findItem(button, "workspaceLabel");
                var urgency = findItem(button, "workspaceUrgency");
                ["dots", "numbers"].forEach(style => {
                    Settings.set("workspaceStyle", style);
                    var content = style === "numbers" ? label : marker;
                    check(content !== null && content.visible, "switching style must not hide the workspace: " + style);
                    if (style === "numbers")
                        check(label.text === "dev", "numbered mode must preserve custom workspace names");
                });
                check(urgency !== null && urgency.visible && urgency.opacity > 0, "urgent workspace must show a warning indicator");
                check(urgency.color.a > 0 && urgency.color.toString() === Theme.error.toString(), "urgency indicator must retain the semantic warning color");
                workspace.urgent = false;
                check(!urgency.visible, "cleared urgency must remove the warning indicator");
                button.clicked({ button: Qt.LeftButton });
                check(workspace.activations === 1, "clicking a workspace must activate it");
                console.log("PASS workspace activation and urgency regressions (" + Theme.currentId + ")");
                var panelComponent = Qt.createComponent(Qt.resolvedUrl("SettingsPanel.qml"));
                check(panelComponent.status === Component.Ready, "settings panel must load: " + panelComponent.errorString());
                var panel = panelComponent.createObject(null);
                check(panel !== null, "settings panel must be created");
                var layoutSection = panel.sections.find(section => section.id === "layout");
                var styleRow = layoutSection.rows.find(row => row.key === "workspaceStyle");
                check(styleRow !== undefined, "layout settings must include workspace style");
                var rowComponent = Qt.createComponent(Qt.resolvedUrl("SettingsRow.qml"));
                check(rowComponent.status === Component.Ready, "settings row must load: " + rowComponent.errorString());
                rowTest.rowItem = rowComponent.createObject(scene, { modelData: styleRow, width: 480 });
                check(rowTest.rowItem !== null, "workspace style row must be created");
                rowTest.start();
                return;
            } catch (error) {
                console.error("FAIL workspace tests: " + error.message);
            }
            Qt.quit();
        }
    }
}
