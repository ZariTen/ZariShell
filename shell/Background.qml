import QtQuick
import Quickshell
import Quickshell.Wayland

Scope {
    Variants {
        model: Quickshell.screens

        PanelWindow {
            required property var modelData
            screen: modelData
            color: Theme.surface
            aboveWindows: false
            exclusionMode: ExclusionMode.Ignore
            exclusiveZone: 0

            anchors {
                top: true
                bottom: true
                left: true
                right: true
            }

            WlrLayershell.layer: WlrLayer.Background
            WlrLayershell.namespace: "shell-bg"
            mask: Region {
                item: bg
                intersection: Intersection.Xor
            }

            Image {
                id: bg
                anchors.fill: parent
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                cache: false
                source: Wallpaper.path === "" ? "" : "file://" + encodeURIComponent(Wallpaper.path).replace(/%2F/g, "/")
            }
        }
    }
}
