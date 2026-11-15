import QtQuick
import Quickshell

ShellRoot {
    Item { id: hostContent; width: 400; height: 300 }
    QtObject { id: host; property var contentItem: hostContent }
    QtObject {
        id: app
        property string icon: ""
        property string title: "Test app"
        property bool hasMenu: true
        property bool onlyMenu: false
        property var calls: []
        function activate() { calls.push("activate"); }
        function secondaryActivate() { calls.push("secondary"); }
        function display(window, x, y) {
            if (window !== host || !isFinite(x) || !isFinite(y))
                throw new Error("Invalid tray menu anchor");
            calls.push("menu");
        }
        function scroll(delta, horizontal) { calls.push("scroll:" + delta + ":" + horizontal); }
    }
    Timer {
        interval: 150; running: true
        onTriggered: {
            try {
                var component = Qt.createComponent("TrayItems.qml");
                if (component.status !== Component.Ready)
                    throw new Error("Tray popup items unavailable: " + component.errorString());
                var grid = component.createObject(hostContent, { model: [app], menuWindow: host });
                if (!grid)
                    throw new Error("Cannot create tray popup items");
                grid.forceLayout();
                var button = grid.itemAtIndex(0);
                if (!button)
                    throw new Error("Tray app is inaccessible");
                ShellState.panel = "tray";
                button.clicked({ button: Qt.LeftButton, x: 8, y: 8 });
                if (ShellState.panel !== "")
                    throw new Error("App activation leaves the tray overlay open");
                ShellState.panel = "tray";
                button.clicked({ button: Qt.RightButton, x: 8, y: 8 });
                if (ShellState.panel !== "tray")
                    throw new Error("Tray closed while its native menu needs its parent window");
                button.clicked({ button: Qt.MiddleButton, x: 8, y: 8 });
                if (ShellState.panel !== "")
                    throw new Error("Secondary activation leaves the tray overlay open");
                button.wheel({ angleDelta: Qt.point(0, -120) });
                app.onlyMenu = true;
                button.clicked({ button: Qt.LeftButton, x: 8, y: 8 });
                app.onlyMenu = false;
                app.hasMenu = false;
                button.clicked({ button: Qt.RightButton, x: 8, y: 8 });
                button.Accessible.pressAction();
                var expected = ["activate", "menu", "secondary", "scroll:-120:false", "menu", "activate", "activate"];
                if (JSON.stringify(app.calls) !== JSON.stringify(expected))
                    throw new Error("Tray actions changed: " + JSON.stringify(app.calls));
                grid.model = [];
                grid.forceLayout();
                if (grid.count !== 0)
                    throw new Error("Removed tray apps remain visible");
                grid.destroy();
                console.log("PASS QML regression tests");
            } catch (error) {
                console.error("FAIL", error.message);
            }
            Qt.quit();
        }
    }
}
