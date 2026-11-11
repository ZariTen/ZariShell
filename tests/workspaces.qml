import QtQuick
import Quickshell
import QtQuick.Layouts

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
        property int scenario: 0
        readonly property var scenarios: [
            { width: 493, fontSize: null, spacing: 1 },
            { width: 493, fontSize: 20, spacing: 1 },
            { width: 493, fontSize: 20, spacing: 2 },
            { width: 360, fontSize: 20, spacing: 2 }
        ]
        interval: 100
        function polish(item) {
            // No mapped window: explicitly run real Qt layout polish.
            // Do not polish theme Shapes/effects, which require a renderer.
            (item.children || []).forEach(child => polish(child));
            if (item instanceof RowLayout || item instanceof ColumnLayout)
                item.ensurePolished();
            if (item instanceof Flow)
                item.forceLayout();
        }
        function matching(item, predicate) {
            var result = predicate(item) ? [item] : [];
            (item.children || []).forEach(child => { result = result.concat(matching(child, predicate)); });
            return result;
        }
        function bounds(item, target) {
            var position = item.mapToItem(target, 0, 0);
            return { x: position.x, y: position.y, width: item.width, height: item.height };
        }
        function overlaps(first, second) {
            return first.x < second.x + second.width - 0.1 && second.x < first.x + first.width - 0.1
                && first.y < second.y + second.height - 0.1 && second.y < first.y + first.height - 0.1;
        }
        function configure() {
            var spec = scenarios[scenario];
            Settings.set("spacing", spec.spacing);
            if (spec.fontSize === null)
                Settings.reset("fontSize");
            else
                Settings.set("fontSize", spec.fontSize);
            rowItem.width = Theme.px(spec.width);
            restart();
        }
        function options(item) {
            var result = [];
            if (item.visible && item.modelData && item.modelData.value !== undefined && item.clicked !== undefined)
                result.push(item);
            (item.children || []).forEach(child => { result = result.concat(options(child)); });
            return result;
        }
        onTriggered: {
            try {
                polish(rowItem);
                polish(rowItem);
                var buttons = options(rowItem);
                var context = " (scenario " + scenario + ": " + JSON.stringify(scenarios[scenario]) + ")";
                check(buttons.length === 4, "settings must render four style buttons");
                var rowLabel = matching(rowItem, item => item.visible && item.text === rowItem.modelData.label)[0];
                var reset = matching(rowItem, item => item.visible && item.codepoint === 0xF099B && item.clicked !== undefined)[0];
                check(rowLabel !== undefined && reset !== undefined, "workspace row label and reset must exist");
                var occupied = [rowLabel, reset].concat(buttons);
                occupied.forEach((item, index) => {
                    var box = bounds(item, rowItem);
                    check(box.x >= -0.1 && box.y >= -0.1 && box.x + box.width <= rowItem.width + 0.1 && box.y + box.height <= rowItem.height + 0.1, "row content must fit row bounds: " + index + " " + JSON.stringify(box) + context);
                    occupied.slice(index + 1).forEach(other => {
                        var otherBox = bounds(other, rowItem);
                        check(!overlaps(box, otherBox), "workspace row controls must not overlap: " + index + " " + JSON.stringify(box) + " vs " + JSON.stringify(otherBox) + context);
                    });
                });
                check(rowLabel.width + 0.1 >= rowLabel.implicitWidth, "workspace label must not be elided" + context);
                buttons.forEach(option => {
                    var text = matching(option, item => item.visible && item.text === option.modelData.label)[0];
                    check(text !== undefined, "style option text must exist");
                    var textBox = bounds(text, option);
                    check(text.width + 0.1 >= text.implicitWidth && textBox.x >= -0.1 && textBox.y >= -0.1 && textBox.x + textBox.width <= option.width + 0.1 && textBox.y + textBox.height <= option.height + 0.1, "style option must contain its full text: " + option.modelData.label + context);
                    option.clicked({ button: Qt.LeftButton });
                    check(Settings.get("workspaceStyle", "") === option.modelData.value && Theme.workspaceStyle === option.modelData.value, "settings choice must update the workspace style: " + option.modelData.label);
                });
                console.log("PASS workspace layout" + context + " height=" + rowItem.height);
                scenario++;
                if (scenario < scenarios.length) {
                    configure();
                    return;
                }
                Settings.resetKeys(["fontSize", "spacing", "reduceMotion"]);
                Settings.resetKeys(["workspaceStyle"]);
                check(Theme.workspaceStyle === "dots", "section reset must restore dots");
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
                check(marker.width === marker.height && marker.radius >= marker.width / 2, "Metro must not turn dots into squares");
                ["dots", "numbers", "pills", "diamonds"].forEach((style, index) => {
                    Settings.set("workspaceStyle", style);
                    var content = style === "numbers" ? label : marker;
                    check(content.visible, "switching style must not hide the workspace: " + style);
                    if (style === "numbers")
                        check(label.text === "dev", "numbered mode must preserve custom workspace names");
                    if (Theme.currentId === "metro") {
                        var face = button.children.find(child => child.item !== undefined && child.item !== null).item;
                        check(content.color.toString() !== face.color.toString(), "urgent workspace must not disappear into Metro's active face: " + style);
                    }
                    check(urgency !== null && urgency.visible && urgency.opacity > 0 && urgency.color.toString() === Theme.error.toString(), "Liquid must retain a visible urgency indicator: " + style);
                    check(!urgency.parent.layer.enabled, "theme effects must not recolor the urgency indicator");
                    workspace.urgent = false;
                    check(!urgency.visible, "cleared urgency must remove the warning indicator");
                    workspace.urgent = true;
                    button.clicked({ button: Qt.LeftButton });
                    check(workspace.activations === index + 1, "workspace activation must work in " + style);
                });
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
                rowTest.rowItem = rowComponent.createObject(scene, { modelData: styleRow, width: Theme.px(493) });
                check(rowTest.rowItem !== null, "workspace style row must be created");
                rowTest.rowItem.height = Qt.binding(() => rowTest.rowItem.implicitHeight);
                rowTest.configure();
                return;
            } catch (error) {
                console.error("FAIL workspace tests: " + error.message);
            }
            Qt.quit();
        }
    }
}
