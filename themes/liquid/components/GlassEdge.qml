import QtQuick
import QtQuick.Shapes
import qs

// Liquid Glass edge, shared by the looks in this folder: the bright specular
// rim of a glass shape plus a soft band of light just inside it. Light falls
// from the top left, so the rim is brightest there, fades along the sides and
// catches again at the bottom right; `recessed` flips it for wells. Fill the
// shape it outlines and set `radius` to its corner.
Shape {
    id: edge

    property real radius: 0
    property real strength: 1          // 0..1, scales every highlight
    property bool recessed: false

    readonly property real cornerRadius: Math.max(0, Math.min(radius, width / 2, height / 2))
    readonly property real rimWidth: 1.8
    readonly property real glowWidth: Math.max(1.5, Math.min(10, Math.min(width, height) / 4))
    readonly property color rimLight: Theme.color("rimLight", [1, 1, 1, 0.9])
    readonly property color rimShade: Theme.color("rimShade", [1, 1, 1, 0.14])
    readonly property color innerGlow: Theme.color("innerGlow", [1, 1, 1, 0.09])

    function light(baseColor, factor) {
        return Qt.rgba(baseColor.r, baseColor.g, baseColor.b, baseColor.a * factor * edge.strength);
    }

    preferredRendererType: Shape.CurveRenderer

    // Soft inner light: a wide faint band and a narrow brighter one.
    ShapePath {
        strokeWidth: edge.glowWidth
        fillColor: "transparent"
        strokeGradient: LinearGradient {
            x1: 0; y1: 0
            x2: edge.width; y2: edge.height
            GradientStop { position: 0.0; color: edge.light(edge.innerGlow, edge.recessed ? 0.3 : 1) }
            GradientStop { position: 0.4; color: "transparent" }
            GradientStop { position: 0.6; color: "transparent" }
            GradientStop { position: 1.0; color: edge.light(edge.innerGlow, edge.recessed ? 1 : 0.6) }
        }
        PathRectangle {
            width: edge.width
            height: edge.height
            radius: edge.cornerRadius
            strokeAdjustment: edge.glowWidth
        }
    }

    ShapePath {
        strokeWidth: edge.glowWidth / 2
        fillColor: "transparent"
        strokeGradient: LinearGradient {
            x1: 0; y1: 0
            x2: edge.width; y2: edge.height
            GradientStop { position: 0.0; color: edge.light(edge.innerGlow, edge.recessed ? 0.3 : 1) }
            GradientStop { position: 0.3; color: "transparent" }
            GradientStop { position: 0.7; color: "transparent" }
            GradientStop { position: 1.0; color: edge.light(edge.innerGlow, edge.recessed ? 1 : 0.5) }
        }
        PathRectangle {
            width: edge.width
            height: edge.height
            radius: edge.cornerRadius
            strokeAdjustment: edge.glowWidth / 2
        }
    }

    // Specular rim.
    ShapePath {
        strokeWidth: edge.rimWidth
        fillColor: "transparent"
        strokeGradient: LinearGradient {
            x1: 0; y1: 0
            x2: edge.width; y2: edge.height
            GradientStop { position: 0.0; color: edge.recessed ? edge.light(edge.rimShade, 1) : edge.light(edge.rimLight, 1) }
            GradientStop { position: 0.35; color: edge.light(edge.rimShade, 1) }
            GradientStop { position: 0.65; color: edge.light(edge.rimShade, 1) }
            GradientStop { position: 1.0; color: edge.light(edge.rimLight, edge.recessed ? 0.8 : 0.85) }
        }
        PathRectangle {
            width: edge.width
            height: edge.height
            radius: edge.cornerRadius
            strokeAdjustment: edge.rimWidth
        }
    }
}
