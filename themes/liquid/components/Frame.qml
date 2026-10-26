import QtQuick

// Liquid Glass frame: the specular rim over the picture, as if under glass.
// With a mat (padding) the mat's rim is the only edge, so none is drawn here.
// `control` is the generic Frame.
GlassEdge {
    visible: control.padding === 0
    radius: control.radius
    strength: 0.8
}
