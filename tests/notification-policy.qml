import QtQuick
import Quickshell
import Quickshell.Services.Notifications

ShellRoot {
    property int step: 0
    property int expirations: 0
    QtObject { id: fake; property int expireTimeout: 0; property int urgency: NotificationUrgency.Normal }
    Loader { id: loader; source: "PopupExpiry.qml"; onLoaded: { item.notification = fake; item.expired.connect(() => expirations++); } }
    Timer {
        interval: 40
        repeat: true
        running: true
        onTriggered: {
            try {
                if (!loader.item) throw new Error("A reusable notification expiry policy must load without NotificationServer");
                if (step === 0) {
                    Settings.set("notificationTimeout", 60);
                    if (Theme.notificationTimeout !== 60) throw new Error("Default timeout setting is not reactive");
                    loader.item.hovered = true;
                    loader.item.hovered = false;
                    if (loader.item.running) throw new Error("Sender-persistent notification restarted after hover");
                    fake.expireTimeout = -1;
                } else if (step === 3) {
                    if (expirations !== 1) throw new Error("Default timeout must expire once");
                    fake.expireTimeout = 80;
                    fake.urgency = NotificationUrgency.Critical;
                    if (loader.item.running) throw new Error("Critical notification must remain persistent");
                    fake.urgency = NotificationUrgency.Normal;
                } else if (step === 7) {
                    if (expirations !== 2) throw new Error("Sender timeout must be honored");
                    Settings.set("notificationHistoryLimit", -5);
                    Settings.set("notificationPopupLimit", 9999);
                    if (Theme.notificationHistoryLimit !== 1 || Theme.notificationPopupLimit !== 20) throw new Error("Caps must be bounded");
                    console.log("PASS QML regression tests: notification expiry, hover and settings bounds");
                    Qt.quit();
                }
                step++;
            } catch(error) { console.error("FAIL QML regression tests: " + error.message); Qt.quit(); }
        }
    }
}
