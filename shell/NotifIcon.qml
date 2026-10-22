import QtQuick
import Quickshell.Widgets

// Notification picture: image (large) with a small app-icon badge, or just
// the app icon, or a bell glyph fallback.
Item {
    id: root

    required property var notification
    property bool critical: false
    readonly property string image: Notifs.imageFor(notification)
    readonly property string appIcon: Notifs.appIconFor(notification)
    readonly property bool showImage: image !== "" && picture.status === Image.Ready

    implicitWidth: 40
    implicitHeight: 40

    ClippingRectangle {
        anchors.fill: parent
        radius: Theme.radius
        color: root.critical ? Theme.error : Theme.primaryContainer
        border.width: root.showImage ? 1 : 0
        border.color: Theme.borderLight

        Image {
            id: picture
            anchors.fill: parent
            visible: root.showImage
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            sourceSize.width: 128
            sourceSize.height: 128
            source: root.image
        }

        IconImage {
            id: icon
            anchors.fill: parent
            anchors.margins: 3
            visible: !root.showImage && root.appIcon !== "" && status === Image.Ready
            source: root.showImage ? "" : root.appIcon
            asynchronous: true
        }

        MdIcon {
            anchors.centerIn: parent
            visible: !root.showImage && !icon.visible
            codepoint: root.critical ? 0xF0026 : 0xF009A
            color: Theme.textSurface
            font.pixelSize: 20
        }
    }

    // App badge over the image
    Rectangle {
        visible: root.showImage && badgeIcon.status === Image.Ready
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: -4
        width: 20
        height: 20
        radius: Theme.radius
        color: Theme.panel
        border.width: 1
        border.color: Theme.borderLight

        IconImage {
            id: badgeIcon
            anchors.fill: parent
            anchors.margins: 2
            source: root.showImage ? root.appIcon : ""
            asynchronous: true
        }
    }
}
