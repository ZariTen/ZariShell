import QtQuick
import Quickshell.Widgets

// Picture frame for avatars and cover art. Children are clipped to the
// picture area. `padding` > 0 adds a mat (a Surface) around the picture:
// `radius` is then the mat's corner and `innerRadius` the picture's;
// without padding `radius` is the picture's corner. `bordered` draws a 1px
// borderLight edge around the picture. A theme may decorate the picture
// (e.g. a reflection) through Theme.component("Frame"); the look is laid
// over the content, inside the clip.
Item {
    id: control

    default property alias content: picture.data
    property real padding: 0
    property real radius: Theme.radiusLarge
    property real innerRadius: Theme.radius
    property color color: Theme.primaryContainer
    property bool bordered: false

    Surface {
        anchors.fill: parent
        visible: control.padding > 0
        radius: control.radius
        color: Theme.surfaceContainerHighest
    }

    ClippingRectangle {
        id: picture
        anchors.fill: parent
        anchors.margins: control.padding
        radius: control.padding > 0 ? control.innerRadius : control.radius
        color: control.color
        border.width: control.bordered ? 1 : 0
        border.color: Theme.borderLight

        Loader {
            anchors.fill: parent
            z: 1
            source: Theme.component("Frame")
        }
    }
}
