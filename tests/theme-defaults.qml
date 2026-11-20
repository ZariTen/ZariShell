import QtQuick
import Quickshell

ShellRoot {
    function checkTypography() {
        if (Theme.font !== "Noto Sans")
            throw new Error("Modern must default to Noto Sans; got " + Theme.font);
        var displayWeight = Theme.fontDisplayWeight;
        if (Theme.setTheme("ink") !== "ink" || Theme.font !== "Noto Sans" || Theme.fontDisplayWeight !== displayWeight)
            throw new Error("Switching themes must not change typography");
        Settings.set("font", "Noto Serif");
        if (Theme.setTheme("modern") !== "modern" || Theme.font !== "Noto Serif")
            throw new Error("Switching themes must preserve the user's font override");
    }

    Timer {
        interval: 10
        repeat: true
        running: true
        onTriggered: {
            if (Theme.themes.length === 0)
                return;
            if (Theme.currentId !== "modern" || Theme.themes.some(theme => theme.id === "base")) {
                console.error("FAIL expected Modern by default with no bundled Base; got " + Theme.currentId);
            } else {
                try {
                    checkTypography();
                    console.log("PASS QML regression tests: Modern default and consistent typography");
                } catch (error) {
                    console.error("FAIL " + error.message);
                }
            }
            Qt.quit();
        }
    }
}
