import QtQuick
import QtQuick.Shapes

Item {
    id: root

    visible: KeyboardLayout.capsLock
    implicitWidth: implicitHeight + Theme.spacingXs * 2
    implicitHeight: Theme.iconPx(16)
    Accessible.role: Accessible.StaticText
    Accessible.name: qsTr("Caps Lock is on")

    Shape {
        anchors.centerIn: parent
        width: 16
        height: 16
        scale: root.implicitHeight / height

        ShapePath {
            fillColor: "transparent"
            strokeColor: Theme.textSurface
            strokeWidth: 1.2
            joinStyle: ShapePath.RoundJoin
            capStyle: ShapePath.RoundCap
            PathSvg { path: "M 4 1.5 H 12 Q 14.5 1.5 14.5 4 V 12 Q 14.5 14.5 12 14.5 H 4 Q 1.5 14.5 1.5 12 V 4 Q 1.5 1.5 4 1.5 Z M 5 11 L 8 4.75 L 11 11 M 6 9 H 10" }
        }
    }
}
