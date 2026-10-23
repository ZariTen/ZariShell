pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// System stats. CPU/RAM always (every 3s, 2s while the panel is open);
// GPU/temps/disks only while the system monitor panel is open.
Singleton {
    id: root

    // -- Public properties --------------------------------------------------
    readonly property bool detailed: ShellState.panel === "sysmon"
    property real cpu: 0          // 0..1
    property real mem: 0          // 0..1
    property real memUsedGb: 0
    property real memTotalGb: 0
    property real cpuTemp: -1     // deg C, -1 = unknown
    // [{ vendor, state, name, busy, temp, memUsed, memTotal, freq, maxFreq }]
    // busy 0..1, temp in C, mem in bytes, freq in MHz; -1 = unknown.
    property var gpus: []
    readonly property bool hasGpu: gpus.length > 0
    property var disks: []        // [{ mount, used, size }]

    // -- Internal state -----------------------------------------------------
    readonly property string sysstatsScriptPath: Quickshell.shellDir + "/scripts/sysstats.sh"
    readonly property string gpustatScriptPath: Quickshell.shellDir + "/scripts/gpustat.sh"
    property var previousCpuSample: null

    // -- Helper functions ---------------------------------------------------
    function parseBasicStats(outputText) {
        let lines = outputText.trim().split("\n");
        let cpuFields = lines[0].trim().split(/\s+/).slice(1).map(Number);
        let idleTicks = cpuFields[3] + (cpuFields[4] || 0);
        let totalTicks = cpuFields.reduce((sum, ticks) => sum + ticks, 0);

        if (previousCpuSample) {
            let deltaTotal = totalTicks - previousCpuSample.total;
            let deltaIdle = idleTicks - previousCpuSample.idle;
            if (deltaTotal > 0)
                cpu = Math.max(0, Math.min(1, 1 - deltaIdle / deltaTotal));
        }
        previousCpuSample = { idle: idleTicks, total: totalTicks };

        let memTotalKb = 0;
        let memAvailableKb = 0;
        lines.slice(1).forEach(line => {
            let match = /^(\w+):\s+(\d+)/.exec(line);
            if (!match)
                return;
            if (match[1] === "MemTotal")
                memTotalKb = Number(match[2]);
            else if (match[1] === "MemAvailable")
                memAvailableKb = Number(match[2]);
        });

        if (memTotalKb > 0) {
            let memUsedKb = memTotalKb - memAvailableKb;
            mem = memUsedKb / memTotalKb;
            memUsedGb = memUsedKb / 1048576;
            memTotalGb = memTotalKb / 1048576;
        }
    }

    function parseExtraStats(outputText) {
        let sections = outputText.split("---\n");
        let rawTempMilliC = parseInt((sections[0] || "").trim());
        cpuTemp = isNaN(rawTempMilliC) ? -1 : rawTempMilliC / 1000;

        let seenMounts = {};
        let parsedDisks = [];
        (sections[1] || "").trim().split("\n").forEach(line => {
            let fields = line.trim().split(/\s+/);
            if (fields.length >= 3 && !seenMounts[fields[0]]) {
                seenMounts[fields[0]] = true;
                parsedDisks.push({
                    mount: fields[0],
                    size: Number(fields[1]),
                    used: Number(fields[2])
                });
            }
        });
        disks = parsedDisks;
    }

    function parseGpuStats(outputText) {
        let parsedGpus = [];
        outputText.trim().split("\n").forEach(line => {
            let fields = line.split("\t");
            if (fields.length < 9)
                return;
            let busyPercent = Number(fields[2]);
            parsedGpus.push({
                vendor: fields[0],
                state: fields[1],
                busy: busyPercent >= 0 ? Math.min(1, busyPercent / 100) : -1,
                temp: Number(fields[3]),
                memUsed: Number(fields[4]),
                memTotal: Number(fields[5]),
                freq: Number(fields[6]),
                maxFreq: Number(fields[7]),
                name: fields.slice(8).join(" ")
            });
        });
        gpus = parsedGpus;
    }

    onDetailedChanged: if (detailed) {
        extraStatsProcess.running = true;
        gpuStatsProcess.running = true;
    }

    // -- Background objects -------------------------------------------------
    Timer {
        running: true
        interval: root.detailed ? 2000 : 3000
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            basicStatsProcess.running = true;
            if (root.detailed) {
                extraStatsProcess.running = true;
                gpuStatsProcess.running = true;
            }
        }
    }

    Process {
        id: basicStatsProcess
        command: ["sh", root.sysstatsScriptPath, "basic"]
        stdout: StdioCollector {
            onStreamFinished: root.parseBasicStats(text)
        }
    }

    Process {
        id: extraStatsProcess
        command: ["sh", root.sysstatsScriptPath, "extra"]
        stdout: StdioCollector {
            onStreamFinished: root.parseExtraStats(text)
        }
    }

    Process {
        id: gpuStatsProcess
        command: ["sh", root.gpustatScriptPath]
        stdout: StdioCollector {
            onStreamFinished: root.parseGpuStats(text)
        }
    }
}
