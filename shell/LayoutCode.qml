import QtQuick

// Active keyboard layout code ("US", "BR") at a fixed width: the widest of
// the configured codes, so switching layouts never moves the neighbours.
// Same font and weight as the bar's other small text.
Item {
    id: root

    implicitWidth: {
        metrics.font; // re-measure when the font changes
        var widest = 0;
        for (var i = 0; i < KeyboardLayout.codes.length; i++)
            widest = Math.max(widest, metrics.advanceWidth(KeyboardLayout.codes[i]));
        return Math.ceil(widest);
    }
    implicitHeight: label.implicitHeight

    StyledText {
        id: label
        anchors.centerIn: parent
        text: KeyboardLayout.code
        font.pixelSize: Theme.fontSmall
        elide: Text.ElideNone
    }

    FontMetrics {
        id: metrics
        font: label.font
    }
}
