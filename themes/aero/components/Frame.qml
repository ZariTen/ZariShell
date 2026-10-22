import QtQuick

// Aero frame: a glass reflection over the top 45% of the picture, a bit
// stronger on matted frames (avatars) than on bare ones (cover art).
Item {
    readonly property bool matted: control.padding > 0

    Rectangle {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        height: parent.height * 0.45
        gradient: Gradient {
            GradientStop { position: 0.0; color: Qt.rgba(1, 1, 1, matted ? 0.28 : 0.22) }
            GradientStop { position: 1.0; color: Qt.rgba(1, 1, 1, matted ? 0.02 : 0.03) }
        }
    }
}
