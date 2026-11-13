import QtQuick
import Quickshell

ShellRoot {
    Timer {
        interval: 30
        running: true
        onTriggered: {
            try {
                var sample = new Date(2024, 6, 14, 17, 9, 0);
                var us = Qt.locale("en_US"), de = Qt.locale("de_DE");
                for (var locale of [us, de]) {
                    if (ClockFormat.time(sample, locale) !== locale.toString(sample, locale.timeFormat(Locale.ShortFormat)))
                        throw new Error("Default clock must follow locale short time");
                    if (ClockFormat.date(sample, false, locale) !== locale.toString(sample, locale.dateFormat(Locale.ShortFormat)))
                        throw new Error("Default date must follow locale short date");
                    if (ClockFormat.date(sample, true, locale) !== locale.toString(sample, locale.dateFormat(Locale.LongFormat)))
                        throw new Error("Long date must follow locale");
                }
                Settings.set("clockFormat", "HH:mm");
                Settings.set("dateFormat", "yyyy-MM-dd");
                Settings.set("longDateFormat", "dddd");
                if (ClockFormat.time(sample, us) !== "17:09" || ClockFormat.date(sample, false, us) !== "2024-07-14" || ClockFormat.date(sample, true, us) !== "Sunday")
                    throw new Error("Settings overrides must update actual formatter bindings");
                console.log("PASS QML regression tests: locale clocks and reactive overrides");
            } catch (error) { console.error("FAIL QML regression tests: " + error.message); }
            Qt.quit();
        }
    }
}
