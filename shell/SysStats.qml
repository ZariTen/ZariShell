pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// System stats. CPU/RAM always (every 3s, 2s while the panel is open);
// GPU/temps/disks only while the system monitor panel is open.
Singleton {
    id: root

    readonly property bool detailed: ShellState.panel === "sysmon"
    property real cpu: 0          // 0..1
    property real mem: 0          // 0..1
    property real memUsedGb: 0
    property real memTotalGb: 0
    property real cpuTemp: -1     // °C
    property bool hasGpu: false
    property string gpuName: ""
    property real gpu: 0
    property real gpuTemp: 0
    property real gpuMem: 0
    property real gpuMemUsedGb: 0
    property real gpuMemTotalGb: 0
    property var disks: []        // [{ mount, used, size }]
    property var lastCpu: null

    Timer {
        running: true
        interval: root.detailed ? 2000 : 3000
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            basic.running = true;
            if (root.detailed)
                extra.running = true;
        }
    }

    onDetailedChanged: if (detailed) extra.running = true

    Process {
        id: basic
        command: ["sh", "-c", "head -1 /proc/stat; grep -E '^(MemTotal|MemAvailable):' /proc/meminfo"]
        stdout: StdioCollector {
            onStreamFinished: {
                var lines = text.trim().split("\n");
                var f = lines[0].trim().split(/\s+/).slice(1).map(Number);
                var idle = f[3] + (f[4] || 0);
                var total = f.reduce((a, b) => a + b, 0);
                if (root.lastCpu) {
                    var dt = total - root.lastCpu.total;
                    if (dt > 0)
                        root.cpu = Math.max(0, Math.min(1, 1 - (idle - root.lastCpu.idle) / dt));
                }
                root.lastCpu = { idle: idle, total: total };
                var memTotal = 0, memAvail = 0;
                lines.slice(1).forEach(l => {
                    var m = /^(\w+):\s+(\d+)/.exec(l);
                    if (m && m[1] === "MemTotal") memTotal = Number(m[2]);
                    if (m && m[1] === "MemAvailable") memAvail = Number(m[2]);
                });
                if (memTotal > 0) {
                    root.mem = (memTotal - memAvail) / memTotal;
                    root.memUsedGb = (memTotal - memAvail) / 1048576;
                    root.memTotalGb = memTotal / 1048576;
                }
            }
        }
    }

    // Sections: CPU temp (millidegrees), nvidia-smi CSV, df output.
    Process {
        id: extra
        command: ["sh", "-c",
            "for d in /sys/class/hwmon/hwmon*; do case $(cat $d/name 2>/dev/null) in coretemp|k10temp|zenpower|cpu_thermal) cat $d/temp1_input; break;; esac; done; echo ---; "
            + "command -v nvidia-smi >/dev/null && nvidia-smi --query-gpu=utilization.gpu,temperature.gpu,memory.used,memory.total,name --format=csv,noheader,nounits 2>/dev/null | head -1; echo ---; "
            + "df -B1 --output=target,size,used / /home 2>/dev/null | tail -n +2"]
        stdout: StdioCollector {
            onStreamFinished: {
                var parts = text.split("---\n");
                var t = parseInt((parts[0] || "").trim());
                root.cpuTemp = isNaN(t) ? -1 : t / 1000;

                var g = (parts[1] || "").trim().split(",").map(s => s.trim());
                root.hasGpu = g.length >= 5 && g[0] !== "";
                if (root.hasGpu) {
                    root.gpu = Number(g[0]) / 100;
                    root.gpuTemp = Number(g[1]);
                    root.gpuMemUsedGb = Number(g[2]) / 1024;
                    root.gpuMemTotalGb = Number(g[3]) / 1024;
                    root.gpuMem = Number(g[3]) > 0 ? Number(g[2]) / Number(g[3]) : 0;
                    root.gpuName = g.slice(4).join(",");
                }

                var seen = {};
                var disks = [];
                (parts[2] || "").trim().split("\n").forEach(l => {
                    var f = l.trim().split(/\s+/);
                    if (f.length >= 3 && !seen[f[0]]) {
                        seen[f[0]] = true;
                        disks.push({ mount: f[0], size: Number(f[1]), used: Number(f[2]) });
                    }
                });
                root.disks = disks;
            }
        }
    }
}
