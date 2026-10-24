import QtQuick
import qs

// Metro: a flat tile. Framed buttons are solid grey tiles; hover lightens
// the tile; `active` fills it with the accent (or the tint); press darkens it
// and scales the whole button down a little, like a pressed Start tile.
// `control` is the generic Button.
Rectangle {
    id: look

    readonly property color rest: control.framed ? Theme.surfaceContainer : "transparent"
    readonly property color hover: Theme.color("tileHover", "#3d3d3d")

    radius: control.radius
    color: {
        if (control.active)
            return control.pressed ? Qt.darker(control.tint, 1.25) : (control.hovered ? Qt.lighter(control.tint, 1.15) : control.tint);
        if (control.pressed)
            return Theme.surfaceContainerHigh;
        if (control.hovered)
            return Qt.tint(look.hover, Qt.rgba(control.tint.r, control.tint.g, control.tint.b, 0.18));
        return look.rest;
    }
    Behavior on color { ColorAnimation { duration: Theme.durShort } }

    // Press: scale the whole button (face and content) down while held.
    Binding {
        target: control
        property: "scale"
        value: 0.96
        when: control.pressed
        restoreMode: Binding.RestoreBindingOrValue
    }
}
