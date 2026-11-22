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
    border.width: Theme.wallpaperPastel && control.active ? 1 : 0
    border.color: Theme.accent
    color: {
        if (control.active) {
            if (Theme.wallpaperPastel)
                return Qt.tint(Theme.surfaceContainer, Theme.withAlpha(control.tint, control.pressed ? 0.75 : (control.hovered ? 0.55 : 0.35)));
            // Keep Metro's light labels legible over the shared bright highlight.
            var fill = Theme.wallpaperAccentOverride ? Qt.darker(control.tint, 2.7) : control.tint;
            return control.pressed ? Qt.darker(fill, 1.25) : (control.hovered ? Qt.lighter(fill, 1.15) : fill);
        }
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
