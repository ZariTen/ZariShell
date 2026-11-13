import QtQuick
import Quickshell.Services.Notifications

Timer {
    id: expiry
    property var notification: null
    property bool hovered: false
    readonly property int timeout: !notification || notification.urgency === NotificationUrgency.Critical
        ? 0 : notification.expireTimeout >= 0 ? notification.expireTimeout : Theme.notificationTimeout
    signal expired()
    interval: Math.max(1, timeout)
    running: timeout > 0 && !hovered
    onTriggered: expired()
}
