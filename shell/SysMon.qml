pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell

// System monitor panel: one row per resource (icon well, label, figures and a
// meter bar). GPU rows only appear when a GPU is detected.
Scope {
    id: root

    readonly property string dot: "  \u00b7  "

    function gb(bytes) {
        return (bytes / 1073741824).toFixed(bytes >= 107374182400 ? 0 : 1) + " GB";
    }

    function temp(c) {
        return c >= 0 ? root.dot + Math.round(c) + " \u00b0C" : "";
    }

    function pct(v) {
        return Math.round(v * 100) + "%";
    }

    // Meter tone shifts normal -> warning -> critical with load.
    function tone(v) {
        return v > 0.85 ? "critical" : (v > 0.6 ? "warning" : "normal");
    }

    component Meter: RowLayout {
        id: meter

        property int codepoint: 0
        property string label: ""
        property string sublabel: ""    // e.g. the GPU model, elided
        property string detail: ""
        property real value: 0
        property bool showBar: true

        Layout.fillWidth: true
        spacing: Theme.spacingM

        Rectangle {
            Layout.preferredWidth: 32
            Layout.preferredHeight: 32
            Layout.alignment: Qt.AlignVCenter
            radius: Theme.radius
            color: Theme.surfaceContainer
            border.width: 1
            border.color: Theme.borderLight

            MdIcon {
                anchors.centerIn: parent
                codepoint: meter.codepoint
                font.pixelSize: 18
                color: Theme.textSurface
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            spacing: Theme.spacingXs

            RowLayout {
                Layout.fillWidth: true
                spacing: Theme.spacingS

                StyledText {
                    text: meter.label
                    font.weight: Font.DemiBold
                }
                StyledText {
                    Layout.fillWidth: true
                    text: meter.sublabel
                    color: Theme.textSurfaceVariant
                    font.pixelSize: Theme.fontSmall
                }
                StyledText {
                    text: meter.detail
                    color: Theme.textSurfaceVariant
                    font.pixelSize: Theme.fontSmall
                }
            }

            Slider {
                Layout.fillWidth: true
                visible: meter.showBar
                interactive: false
                value: meter.value
                tone: root.tone(meter.value)
            }
        }
    }

    component Divider: Rectangle {
        Layout.fillWidth: true
        implicitHeight: 1
        color: Theme.outlineVariant
    }

    DropPanel {
        name: "sysmon"
        align: "right"
        cardWidth: 380

        PanelHeader {
            codepoint: 0xF04C5 // md-speedometer
            title: "System monitor"
        }

        Meter {
            codepoint: 0xF0EE0 // md-cpu-64-bit
            label: "CPU"
            value: SysStats.cpu
            detail: root.pct(SysStats.cpu) + root.temp(SysStats.cpuTemp)
        }

        Meter {
            codepoint: 0xF035B // md-memory
            label: "Memory"
            value: SysStats.mem
            detail: SysStats.memUsedGb.toFixed(1) + " / " + SysStats.memTotalGb.toFixed(1) + " GB" + root.dot + root.pct(SysStats.mem)
        }

        // Model is the count, so delegates survive the 2s refresh and the
        // bars animate instead of being recreated.
        Repeater {
            model: SysStats.gpus.length

            delegate: ColumnLayout {
                id: gpuRow

                required property int index
                readonly property var g: SysStats.gpus[index] || ({})
                readonly property bool asleep: g.state === "suspended"
                readonly property bool hasBusy: g.busy >= 0
                readonly property bool hasClock: !hasBusy && g.freq >= 0 && g.maxFreq > 0

                Layout.fillWidth: true
                spacing: Theme.spacingM

                Meter {
                    codepoint: 0xF08AE // md-expansion-card
                    label: SysStats.gpus.length > 1 ? "GPU " + (gpuRow.index + 1) : "GPU"
                    sublabel: gpuRow.g.name || ""
                    showBar: gpuRow.hasBusy || gpuRow.hasClock
                    value: gpuRow.hasBusy ? gpuRow.g.busy : (gpuRow.hasClock ? gpuRow.g.freq / gpuRow.g.maxFreq : 0)
                    detail: gpuRow.asleep ? "Sleeping"
                        : gpuRow.hasBusy ? root.pct(gpuRow.g.busy) + root.temp(gpuRow.g.temp)
                        : gpuRow.hasClock ? gpuRow.g.freq + " MHz" + root.temp(gpuRow.g.temp)
                        : (gpuRow.g.temp >= 0 ? Math.round(gpuRow.g.temp) + " \u00b0C" : "No data")
                }

                Meter {
                    visible: !gpuRow.asleep && gpuRow.g.memTotal > 0
                    codepoint: 0xF061A // md-chip
                    label: "Video memory"
                    value: gpuRow.g.memTotal > 0 ? gpuRow.g.memUsed / gpuRow.g.memTotal : 0
                    detail: root.gb(gpuRow.g.memUsed) + " / " + root.gb(gpuRow.g.memTotal)
                }
            }
        }

        Divider {
            visible: SysStats.disks.length > 0
        }

        Repeater {
            model: SysStats.disks.length

            delegate: Meter {
                id: disk

                required property int index
                readonly property var d: SysStats.disks[index] || ({ mount: "", size: 0, used: 0 })

                codepoint: 0xF02CA // md-harddisk
                label: d.mount === "/" ? "System" : (d.mount === "/home" ? "Home" : "Disk")
                sublabel: d.mount
                value: d.size > 0 ? d.used / d.size : 0
                detail: root.gb(d.used) + " / " + root.gb(d.size) + root.dot + root.pct(disk.value)
            }
        }
    }
}
