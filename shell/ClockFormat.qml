pragma Singleton
import QtQuick
import Quickshell

QtObject {
    readonly property string timePattern: Settings.get("clockFormat", Quickshell.env("QS_GREETER_CLOCK_FORMAT") || "")
    readonly property string datePattern: Settings.get("dateFormat", Quickshell.env("QS_GREETER_DATE_FORMAT") || "")
    readonly property string longDatePattern: Settings.get("longDateFormat", Quickshell.env("QS_GREETER_LONG_DATE_FORMAT") || "")

    function time(value, locale) {
        var language = locale || Qt.locale();
        return language.toString(value, timePattern || language.timeFormat(Locale.ShortFormat));
    }

    function date(value, longForm, locale) {
        var language = locale || Qt.locale();
        var pattern = longForm ? longDatePattern : datePattern;
        return language.toString(value, pattern || language.dateFormat(longForm ? Locale.LongFormat : Locale.ShortFormat));
    }
}
