import QtQuick

Text {
    color: Theme.textSurface
    font.family: Theme.font
    font.pixelSize: Theme.fontBody
    elide: Text.ElideRight
    verticalAlignment: Text.AlignVCenter
    style: Theme.textShadow.a > 0 ? Text.Raised : Text.Normal
    styleColor: Theme.textShadow

}
