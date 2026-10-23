pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell

// System monitor panel: one row per resource (icon well, label, figures and a
// meter bar). GPU rows only appear when a GPU is detected.
Scope {
    id: root

    // -- Internal constants and helpers -------------------------------------
    readonly property string separatorDot: "  \u00b7  "

    function formatGigabytes(bytes) {
        var gigabytes = bytes / 1073741824;
        var decimals = bytes >= 107374182400 ? 0 : 1;
        return gigabytes.toFixed(decimals) + " GB";
    }

    function formatTemperature(celsius) {
        if (celsius < 0)
            return "";
        return root.separatorDot + Math.round(celsius) + " \u00b0C";
    }

    function formatPercent(ratio) {
        return Math.round(ratio * 100) + "%";
    }

    // Meter tone shifts normal -> warning -> critical with load.
    function meterTone(ratio) {
        if (ratio > 0.85)
            return "critical";
        if (ratio > 0.6)
            return "warning";
        return "normal";
    }

    function diskLabel(mountPoint) {
        if (mountPoint === "/")
            return "System";
        if (mountPoint === "/home")
            return "Home";
        return "Disk";
    }

    // -- Inline components --------------------------------------------------
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
            Layout.preferredWidth: Theme.px(32)
            Layout.preferredHeight: Theme.px(32)
            Layout.alignment: Qt.AlignVCenter
            radius: Theme.radius
            color: Theme.surfaceContainer
            border.width: 1
            border.color: Theme.borderLight

            MdIcon {
                anchors.centerIn: parent
                codepoint: meter.codepoint
                font.pixelSize: Theme.iconPx(18)
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
                tone: root.meterTone(meter.value)
            }
        }
    }

    component SectionDivider: Rectangle {
        Layout.fillWidth: true
        implicitHeight: 1
        color: Theme.outlineVariant
    }

    // -- Visual tree --------------------------------------------------------
    DropPanel {
        name: "sysmon"
        align: "right"
        cardWidth: Theme.widthPx(380)

        PanelHeader {
            codepoint: 0xF04C5 // md-speedometer
            title: "System monitor"
        }

        Meter {
            codepoint: 0xF0EE0 // md-cpu-64-bit
            label: "CPU"
            value: SysStats.cpu
            detail: root.formatPercent(SysStats.cpu) + root.formatTemperature(SysStats.cpuTemp)
        }

        Meter {
            codepoint: 0xF035B // md-memory
            label: "Memory"
            value: SysStats.mem
            detail: SysStats.memUsedGb.toFixed(1) + " / " + SysStats.memTotalGb.toFixed(1) + " GB" + root.separatorDot + root.formatPercent(SysStats.mem)
        }

        // Model is the count, so delegates survive the 2s refresh and the
        // bars animate instead of being recreated.
        Repeater {
            model: SysStats.gpus.length

            delegate: ColumnLayout {
                id: gpuRow

                required property int index
                readonly property var gpu: SysStats.gpus[index] || ({})
                readonly property bool isAsleep: gpu.state === "suspended"
                readonly property bool hasBusyRatio: gpu.busy >= 0
                readonly property bool hasClockRatio: !hasBusyRatio && gpu.freq >= 0 && gpu.maxFreq > 0

                Layout.fillWidth: true
                spacing: Theme.spacingM

                Meter {
                    codepoint: 0xF08AE // md-expansion-card
                    label: SysStats.gpus.length > 1 ? "GPU " + (gpuRow.index + 1) : "GPU"
                    sublabel: gpuRow.gpu.name || ""
                    showBar: gpuRow.hasBusyRatio || gpuRow.hasClockRatio
                    value: {
                        if (gpuRow.hasBusyRatio)
                            return gpuRow.gpu.busy;
                        if (gpuRow.hasClockRatio)
                            return gpuRow.gpu.freq / gpuRow.gpu.maxFreq;
                        return 0;
                    }
                    detail: {
                        if (gpuRow.isAsleep)
                            return "Sleeping";
                        if (gpuRow.hasBusyRatio)
                            return root.formatPercent(gpuRow.gpu.busy) + root.formatTemperature(gpuRow.gpu.temp);
                        if (gpuRow.hasClockRatio)
                            return gpuRow.gpu.freq + " MHz" + root.formatTemperature(gpuRow.gpu.temp);
                        if (gpuRow.gpu.temp >= 0)
                            return Math.round(gpuRow.gpu.temp) + " \u00b0C";
                        return "No data";
                    }
                }

                Meter {
                    visible: !gpuRow.isAsleep && gpuRow.gpu.memTotal > 0
                    codepoint: 0xF061A // md-chip
                    label: "Video memory"
                    value: gpuRow.gpu.memTotal > 0 ? gpuRow.gpu.memUsed / gpuRow.gpu.memTotal : 0
                    detail: root.formatGigabytes(gpuRow.gpu.memUsed) + " / " + root.formatGigabytes(gpuRow.gpu.memTotal)
                }
            }
        }

        SectionDivider {
            visible: SysStats.disks.length > 0
        }

        Repeater {
            model: SysStats.disks.length

            delegate: Meter {
                id: diskMeter

                required property int index
                readonly property var diskEntry: SysStats.disks[index] || ({ mount: "", size: 0, used: 0 })

                codepoint: 0xF02CA // md-harddisk
                label: root.diskLabel(diskEntry.mount)
                sublabel: diskEntry.mount
                value: diskEntry.size > 0 ? diskEntry.used / diskEntry.size : 0
                detail: root.formatGigabytes(diskEntry.used) + " / " + root.formatGigabytes(diskEntry.size) + root.separatorDot + root.formatPercent(diskMeter.value)
            }
        }
    }
}
