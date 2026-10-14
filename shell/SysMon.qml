import QtQuick
import QtQuick.Layouts
import Quickshell

// System monitor panel with glossy meter bars.
Scope {
    id: root

    function gb(bytes) {
        return (bytes / 1073741824).toFixed(bytes >= 107374182400 ? 0 : 1) + " GB";
    }

    // Meter colors shift green → amber → red with load (Win7 progress bar states).
    function fill(v) {
        if (v > 0.85)
            return ["#ffb0a0", "#e0412b", "#b8240f", "#ef5a3f"];
        if (v > 0.6)
            return ["#ffe9a0", "#e8b52a", "#c48d0c", "#f0c43c"];
        return ["#b6f39a", "#4fc22a", "#2f9e12", "#5fd23a"];
    }

    component Meter: ColumnLayout {
        property string label: ""
        property string detail: ""
        property real value: 0
        readonly property var colors: root.fill(value)

        Layout.fillWidth: true
        spacing: 3

        RowLayout {
            Layout.fillWidth: true
            StyledText {
                Layout.fillWidth: true
                text: parent.parent.label
                font.weight: Font.DemiBold
            }
            StyledText {
                text: parent.parent.detail
                color: Theme.textSurfaceVariant
                font.pixelSize: Theme.fontSmall
            }
        }
        GlossySlider {
            Layout.fillWidth: true
            interactive: false
            value: parent.value
            fillTop: parent.colors[0]
            fillMid: parent.colors[1]
            fillDark: parent.colors[2]
            fillBottom: parent.colors[3]
        }
    }

    DropPanel {
        name: "sysmon"
        align: "right"
        cardWidth: 360

        PanelHeader {
            codepoint: 0xF04C5 // md-speedometer
            title: "System monitor"
        }

        Meter {
            label: "CPU"
            value: SysStats.cpu
            detail: Math.round(SysStats.cpu * 100) + "%" + (SysStats.cpuTemp >= 0 ? "  ·  " + Math.round(SysStats.cpuTemp) + " °C" : "")
        }

        Meter {
            label: "Memory"
            value: SysStats.mem
            detail: SysStats.memUsedGb.toFixed(1) + " / " + SysStats.memTotalGb.toFixed(1) + " GB  ·  " + Math.round(SysStats.mem * 100) + "%"
        }

        Meter {
            visible: SysStats.hasGpu
            label: "GPU"
            value: SysStats.gpu
            detail: Math.round(SysStats.gpu * 100) + "%  ·  " + Math.round(SysStats.gpuTemp) + " °C"
        }

        Meter {
            visible: SysStats.hasGpu
            label: "Video memory"
            value: SysStats.gpuMem
            detail: SysStats.gpuMemUsedGb.toFixed(1) + " / " + SysStats.gpuMemTotalGb.toFixed(1) + " GB"
        }

        StyledText {
            visible: SysStats.hasGpu
            Layout.topMargin: -Theme.spacingS
            text: SysStats.gpuName
            font.pixelSize: Theme.fontSmall
            color: Theme.textSurfaceVariant
        }

        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 1
            color: Theme.outlineVariant
        }

        Repeater {
            model: SysStats.disks
            delegate: Meter {
                required property var modelData
                label: "Disk " + modelData.mount
                value: modelData.size > 0 ? modelData.used / modelData.size : 0
                detail: root.gb(modelData.used) + " / " + root.gb(modelData.size)
            }
        }
    }
}
