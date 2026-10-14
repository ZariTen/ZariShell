import QtQuick
import Quickshell.Widgets

// User picture: AccountsService icon, then ~/.face (often unreadable to the
// greeter), then a glyph. Wrapped in a small glass frame.
Item {
    id: av
    property string user: ""
    property string home: ""
    property real frame: 8

    Glass { anchors.fill: parent; radius: 10 * av.width / 112; tint: Qt.rgba(1, 1, 1, 0.12) }
    ClippingRectangle {
        anchors.fill: parent
        anchors.margins: av.frame
        radius: 5
        color: Theme.primaryContainer
        Image {
            id: face
            property int attempt: 0
            readonly property var candidates: [
                "/var/lib/AccountsService/icons/" + av.user,
                (av.home || "/home/" + av.user) + "/.face"
            ]
            anchors.fill: parent
            fillMode: Image.PreserveAspectCrop
            sourceSize.width: 192
            sourceSize.height: 192
            asynchronous: true
            source: av.user !== "" && attempt < candidates.length ? Theme.fileUrl(candidates[attempt]) : ""
            visible: status === Image.Ready
            onStatusChanged: if (status === Image.Error) attempt++
        }
        Connections { target: av; function onUserChanged() { face.attempt = 0; } }
        MdIcon {
            anchors.centerIn: parent
            visible: !face.visible
            codepoint: 0xF0004 // md-account
            font.pixelSize: av.width * 0.5
        }
        Rectangle {
            anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top
            height: parent.height * 0.45
            gradient: Gradient {
                GradientStop { position: 0.0; color: Qt.rgba(1, 1, 1, 0.28) }
                GradientStop { position: 1.0; color: Qt.rgba(1, 1, 1, 0.02) }
            }
        }
    }
}
