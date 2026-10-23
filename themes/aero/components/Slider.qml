import QtQuick
import qs

// Aero: Win7 progress-bar style glossy slider with a round thumb. `tone`
// maps to the Win7 bar states (green / amber / red) or the accent.
// `control` is the generic Slider.
Rectangle {
    id: look

    readonly property var stops: {
        if (control.tone === "critical")
            return ["#ffb0a0", "#e0412b", "#b8240f", "#ef5a3f"];
        if (control.tone === "warning")
            return ["#ffe9a0", "#e8b52a", "#c48d0c", "#f0c43c"];
        if (control.tone === "muted")
            return ["#9a9a9a", "#6b6b6b", "#555555", "#777777"];
        if (control.tone === "accent")
            return [Qt.lighter(Theme.accent, 1.35), Theme.accent, Qt.darker(Theme.accent, 1.5), Theme.accent];
        return ["#b6f39a", "#4fc22a", "#2f9e12", "#5fd23a"];
    }

    radius: 2
    color: Theme.inset
    border.width: 1
    border.color: Qt.rgba(1, 1, 1, 0.25)

    Rectangle {
        x: 1
        y: 1
        width: (parent.width - 2) * control.shown
        height: parent.height - 2
        radius: 1
        Behavior on width { enabled: !control.pressed; NumberAnimation { duration: Theme.durMedium; easing.type: Easing.OutCubic } }
        gradient: Gradient {
            GradientStop { position: 0.0; color: look.stops[0] }
            GradientStop { position: 0.45; color: look.stops[1] }
            GradientStop { position: 0.5; color: look.stops[2] }
            GradientStop { position: 1.0; color: look.stops[3] }
        }
    }

    Rectangle {
        visible: control.interactive
        x: Math.max(0, Math.min(parent.width - width, (parent.width - 2) * control.shown - width / 2))
        anchors.verticalCenter: parent.verticalCenter
        width: parent.height + 2
        height: width
        radius: width / 2
        border.width: 1
        border.color: Theme.border
        scale: control.hovered || control.pressed ? 1.15 : 1
        Behavior on scale { NumberAnimation { duration: Theme.durShort } }
        gradient: Gradient {
            GradientStop { position: 0.0; color: "#ffffff" }
            GradientStop { position: 1.0; color: "#9fb7c9" }
        }
    }
}
