import QtQuick

// Liquid Glass frame: the specular rim over the picture, as if under glass.
// `control` is the generic Frame.
GlassEdge {
    radius: control.padding > 0 ? control.innerRadius : control.radius
    strength: 0.8
}
