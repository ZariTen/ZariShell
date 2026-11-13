import QtQuick
import Quickshell
import "UserAccounts.js" as UserAccounts

ShellRoot {
    Timer {
        interval: 30
        running: true
        onTriggered: {
            try {
                var limits = UserAccounts.uidRange("200000", "4294967294");
                var users = UserAccounts.loginUsers("directory:x:200000:1:Remote Person,office:/srv/person:/bin/sh\nservice:x:200001:1:Service:/srv/service:/bin/false\n", limits[0], limits[1]);
                if (users.length !== 1 || users[0].real !== "Remote Person") throw new Error("NSS helper must preserve remote identities and exclude non-login shells");
                if (JSON.stringify(UserAccounts.uidRange("90000", "60000")) !== "[1000,60000]") throw new Error("Inverted environment bounds must fall back");
                console.log("PASS QML regression tests: shared NSS account helper");
            } catch(error) { console.error("FAIL QML regression tests: " + error.message); }
            Qt.quit();
        }
    }
}
