import QtQuick

// User picture: AccountsService icon, then ~/.face (often unreadable to the
// greeter), then a glyph, in a matted Frame scaled to the avatar size.
Frame {
    id: av
    property string user: ""
    property string home: ""
    property real frame: Theme.spacingS

    padding: av.frame
    radius: Theme.radiusFrame * av.width / 112
    innerRadius: Theme.radius

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
}
