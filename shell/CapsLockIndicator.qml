import QtQuick

StyledText {
    visible: KeyboardLayout.capsLock
    text: qsTr("Caps")
    Accessible.role: Accessible.StaticText
    Accessible.name: qsTr("Caps Lock is on")
    font.pixelSize: Theme.fontSmall
    font.weight: Font.DemiBold
    leftPadding: Theme.spacingXs
    rightPadding: Theme.spacingXs
}