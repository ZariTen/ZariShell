pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.Notifications

// Notification server plus two views of it:
//  - popups:  what Toasts shows right now (expire after a few seconds)
//  - history: everything received, newest first, for the notification center
// Expiring a popup keeps the notification in history; dismissing or clearing
// from the center closes it for real.
Singleton {
    id: root

    // -- Public properties --------------------------------------------------
    property var popups: []
    property var history: []
    property int unread: 0
    property bool dnd: false   // Do Not Disturb: no toasts, history still kept
    property var times: ({})

    // -- Helper functions ---------------------------------------------------
    function timeOf(notification) {
        return times[notification.id] || new Date();
    }

    // Turns an icon name, absolute path or file:// URL into an image source.
    function resolveIcon(iconName) {
        if (!iconName)
            return "";
        if (iconName.indexOf("/") === 0)
            return "file://" + iconName;
        var normalizedName = iconName;
        if (normalizedName.indexOf("image://icon/") === 0)
            normalizedName = normalizedName.substring(13);
        if (/^(file|image|qrc|https?):/.test(normalizedName))
            return normalizedName;
        return Quickshell.iconPath(normalizedName, true);
    }

    function isPath(iconName) {
        return !!iconName && (iconName.indexOf("/") === 0 || iconName.indexOf("file://") === 0);
    }

    // Desktop entry by desktop-entry hint, then by app name (id/name/startupClass).
    function entryFor(notification) {
        var desktopId = notification.desktopEntry || "";
        if (desktopId !== "") {
            var directEntry = DesktopEntries.byId(desktopId) || DesktopEntries.heuristicLookup(desktopId);
            if (directEntry)
                return directEntry;
        }
        var appNameLower = (notification.appName || "").toLowerCase();
        if (appNameLower === "" || appNameLower === "notify-send")
            return null;
        var allEntries = DesktopEntries.applications.values;
        for (var i = 0; i < allEntries.length; i++) {
            var candidateEntry = allEntries[i];
            if ((candidateEntry.id || "").toLowerCase() === appNameLower
                || (candidateEntry.name || "").toLowerCase() === appNameLower
                || (candidateEntry.startupClass || "").toLowerCase() === appNameLower) {
                return candidateEntry;
            }
        }
        return DesktopEntries.heuristicLookup(notification.appName) || null;
    }

    // App icon: named appIcon, else the desktop entry's icon.
    function appIconFor(notification) {
        var namedIcon = isPath(notification.appIcon) ? "" : resolveIcon(notification.appIcon);
        if (namedIcon !== "")
            return namedIcon;
        var desktopEntry = entryFor(notification);
        return desktopEntry && desktopEntry.icon ? resolveIcon(desktopEntry.icon) : "";
    }

    // Large picture: notification image, else an appIcon given as a file path.
    function imageFor(notification) {
        if (notification.image)
            return resolveIcon(notification.image);
        return isPath(notification.appIcon) ? resolveIcon(notification.appIcon) : "";
    }

    function appLabel(notification) {
        var rawAppName = notification.appName || "";
        if (rawAppName === "" || rawAppName === "notify-send")
            return "System";
        return rawAppName;
    }

    function iconFor(notification) {
        return imageFor(notification) || appIconFor(notification);
    }

    function without(list, targetNotification) {
        return list.filter(item => item !== targetNotification);
    }

    function expirePopup(notification) {
        popups = without(popups, notification);
    }

    function dismiss(notification) {
        popups = without(popups, notification);
        history = without(history, notification);
        notification.dismiss();
    }

    function clearAll() {
        var previousHistory = history.slice();
        popups = [];
        history = [];
        unread = 0;
        for (var i = 0; i < previousHistory.length; i++)
            previousHistory[i].dismiss();
    }

    function markRead() {
        unread = 0;
    }

    function relativeTime(timestamp, now) {
        var elapsedSeconds = Math.max(0, Math.floor((now - timestamp) / 1000));
        if (elapsedSeconds < 60)
            return "now";
        if (elapsedSeconds < 3600)
            return Math.floor(elapsedSeconds / 60) + "m ago";
        if (elapsedSeconds < 86400)
            return Math.floor(elapsedSeconds / 3600) + "h ago";
        return Qt.formatDateTime(timestamp, "d MMM HH:mm");
    }

    // -- Background objects -------------------------------------------------
    NotificationServer {
        id: server
        bodySupported: true
        actionsSupported: true
        imageSupported: true

        onNotification: notification => {
            notification.tracked = true;
            root.times[notification.id] = new Date();
            // Sender closed it (or we dismissed it): drop it everywhere.
            notification.closed.connect(() => {
                root.popups = root.without(root.popups, notification);
                root.history = root.without(root.history, notification);
            });
            root.history = [notification].concat(root.history).slice(0, 50);
            if (!root.dnd || notification.urgency === NotificationUrgency.Critical) {
                let nextPopups = root.popups.concat([notification]);
                root.popups = nextPopups.slice(Math.max(0, nextPopups.length - 4));
            }
            if (ShellState.panel !== "notifications")
                root.unread++;
        }
    }
}
