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
    property real cpuTemp: -1     // deg C, -1 = unknown
    // [{ vendor, state, name, busy, temp, memUsed, memTotal, freq, maxFreq }]
    // busy 0..1, temp in C, mem in bytes, freq in MHz; -1 = unknown.
    property var gpus: []
    readonly property bool hasGpu: gpus.length > 0
    property var disks: []        // [{ mount, used, size }]
    property var lastCpu: null

    Timer {
        running: true
        interval: root.detailed ? 2000 : 3000
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            basic.running = true;
            if (root.detailed) {
                extra.running = true;
                gpu.running = true;
            }
        }
    }

    onDetailedChanged: if (detailed) {
        extra.running = true;
        gpu.running = true;
    }

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

    // Sections: CPU temp (millidegrees), df output.
    Process {
        id: extra
        command: ["sh", "-c",
            "for d in /sys/class/hwmon/hwmon*; do case $(cat $d/name 2>/dev/null) in coretemp|k10temp|zenpower|cpu_thermal) cat $d/temp1_input; break;; esac; done; echo ---; "
            + "df -B1 --output=target,size,used / /home 2>/dev/null | tail -n +2"]
        stdout: StdioCollector {
            onStreamFinished: {
                var parts = text.split("---\n");
                var t = parseInt((parts[0] || "").trim());
                root.cpuTemp = isNaN(t) ? -1 : t / 1000;

                var seen = {};
                var disks = [];
                (parts[1] || "").trim().split("\n").forEach(l => {
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

    // GPUs, auto-detected from /sys/class/drm (see scripts/gpustat.sh).
    Process {
        id: gpu
        command: ["sh", Quickshell.shellDir + "/scripts/gpustat.sh"]
        stdout: StdioCollector {
            onStreamFinished: {
                var list = [];
                text.trim().split("\n").forEach(l => {
                    var f = l.split("\t");
                    if (f.length < 9)
                        return;
                    var busy = Number(f[2]);
                    list.push({
                        vendor: f[0],
                        state: f[1],
                        busy: busy >= 0 ? Math.min(1, busy / 100) : -1,
                        temp: Number(f[3]),
                        memUsed: Number(f[4]),
                        memTotal: Number(f[5]),
                        freq: Number(f[6]),
                        maxFreq: Number(f[7]),
                        name: f.slice(8).join(" ")
                    });
                });
                root.gpus = list;
            }
        }
    }
}
