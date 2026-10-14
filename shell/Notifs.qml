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

    property var popups: []
    property var history: []
    property int unread: 0
    property bool dnd: false   // Do Not Disturb: no toasts, history still kept
    property var times: ({})

    function timeOf(n) {
        return times[n.id] || new Date();
    }

    // ── Icon resolution ──────────────────────────────────────────────────
    // Turns an icon name, absolute path or file:// URL into an image source.
    function resolveIcon(name) {
        if (!name)
            return "";
        if (name.indexOf("/") === 0)
            return "file://" + name;
        if (name.indexOf("image://icon/") === 0)
            name = name.substring(13);
        if (/^(file|image|qrc|https?):/.test(name))
            return name;
        return Quickshell.iconPath(name, true);
    }

    function isPath(name) {
        return !!name && (name.indexOf("/") === 0 || name.indexOf("file://") === 0);
    }

    // Desktop entry by desktop-entry hint, then by app name (id/name/startupClass).
    function entryFor(n) {
        var key = n.desktopEntry || "";
        if (key !== "") {
            var e = DesktopEntries.byId(key) || DesktopEntries.heuristicLookup(key);
            if (e)
                return e;
        }
        var app = (n.appName || "").toLowerCase();
        if (app === "" || app === "notify-send")
            return null;
        var all = DesktopEntries.applications.values;
        for (var i = 0; i < all.length; i++) {
            var d = all[i];
            if ((d.id || "").toLowerCase() === app || (d.name || "").toLowerCase() === app || (d.startupClass || "").toLowerCase() === app)
                return d;
        }
        return DesktopEntries.heuristicLookup(n.appName) || null;
    }

    // App icon: named appIcon, else the desktop entry's icon.
    function appIconFor(n) {
        var named = isPath(n.appIcon) ? "" : resolveIcon(n.appIcon);
        if (named !== "")
            return named;
        var e = entryFor(n);
        return e && e.icon ? resolveIcon(e.icon) : "";
    }

    // Large picture: notification image, else an appIcon given as a file path.
    function imageFor(n) {
        if (n.image)
            return resolveIcon(n.image);
        return isPath(n.appIcon) ? resolveIcon(n.appIcon) : "";
    }

    function appLabel(n) {
        var a = n.appName || "";
        return a === "" || a === "notify-send" ? "System" : a;
    }

    function iconFor(n) {
        return imageFor(n) || appIconFor(n);
    }

    function without(list, n) {
        return list.filter(x => x !== n);
    }

    function expirePopup(n) {
        popups = without(popups, n);
    }

    function dismiss(n) {
        popups = without(popups, n);
        history = without(history, n);
        n.dismiss();
    }


    function clearAll() {
        var all = history.slice();
        popups = [];
        history = [];
        unread = 0;
        for (var i = 0; i < all.length; i++)
            all[i].dismiss();
    }

    function markRead() {
        unread = 0;
    }

    function relativeTime(date, now) {
        var secs = Math.max(0, Math.floor((now - date) / 1000));
        if (secs < 60)
            return "now";
        if (secs < 3600)
            return Math.floor(secs / 60) + "m ago";
        if (secs < 86400)
            return Math.floor(secs / 3600) + "h ago";
        return Qt.formatDateTime(date, "d MMM HH:mm");
    }

    NotificationServer {
        id: server
        bodySupported: true
        actionsSupported: true
        imageSupported: true

        onNotification: n => {
            n.tracked = true;
            root.times[n.id] = new Date();
            // Sender closed it (or we dismissed it): drop it everywhere.
            n.closed.connect(() => {
                root.popups = root.without(root.popups, n);
                root.history = root.without(root.history, n);
            });
            root.history = [n].concat(root.history).slice(0, 50);
            if (!root.dnd || n.urgency === NotificationUrgency.Critical) {
                var p = root.popups.concat([n]);
                root.popups = p.slice(Math.max(0, p.length - 4));
            }
            if (ShellState.panel !== "notifications")
                root.unread++;
        }
    }
}
