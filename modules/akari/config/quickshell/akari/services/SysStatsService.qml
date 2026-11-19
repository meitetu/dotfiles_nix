pragma Singleton
import QtQuick
import Quickshell.Io

QtObject {
    id: root

    property int cpuPercent: 0
    property int memPercent: 0
    property string memText: "0.0G"
    property string uptimeText: ""

    // GPU (AMD amdgpu via sysfs; 0 when no supported GPU is present)
    property int gpuPercent: 0
    property bool gpuAvailable: false
    property int vramPercent: 0
    property string vramText: "0.0G"

    property real _prevIdle: 0
    property real _prevTotal: 0

    function refresh() {
        if (!statsProc.running) statsProc.running = true
    }

    property Process statsProc: Process {
        command: ["bash", "-c",
            "head -n 1 /proc/stat; " +
            "grep -E '^(MemTotal|MemAvailable):' /proc/meminfo; " +
            "uptime -p; " +
            "for f in /sys/class/drm/card*/device/gpu_busy_percent; do " +
            "  if [ -r \"$f\" ]; then echo \"GPUBUSY: $(cat \"$f\")\"; break; fi; " +
            "done; " +
            "for d in /sys/class/drm/card*/device; do " +
            "  if [ -r \"$d/mem_info_vram_used\" ]; then " +
            "    echo \"VRAM: $(cat \"$d/mem_info_vram_used\") $(cat \"$d/mem_info_vram_total\")\"; " +
            "    break; " +
            "  fi; " +
            "done"
        ]
        stdout: SplitParser {
            onRead: data => {
                var line = data.trim()
                if (line.startsWith("cpu ")) {
                    var parts = line.split(/\s+/)
                    var user = parseFloat(parts[1]) || 0
                    var nice = parseFloat(parts[2]) || 0
                    var sys  = parseFloat(parts[3]) || 0
                    var idle = parseFloat(parts[4]) || 0
                    var iow  = parseFloat(parts[5]) || 0
                    var irq  = parseFloat(parts[6]) || 0
                    var sirq = parseFloat(parts[7]) || 0
                    var steal = parseFloat(parts[8]) || 0
                    var idleAll = idle + iow
                    var total = user + nice + sys + idleAll + irq + sirq + steal
                    if (root._prevTotal > 0 && total > root._prevTotal) {
                        var dTotal = total - root._prevTotal
                        var dIdle = idleAll - root._prevIdle
                        root.cpuPercent = Math.max(0, Math.min(100, Math.round((1.0 - dIdle / dTotal) * 100)))
                    }
                    root._prevTotal = total
                    root._prevIdle = idleAll
                } else if (line.startsWith("MemTotal:")) {
                    root._memTotalKb = parseFloat(line.split(/\s+/)[1]) || 1
                } else if (line.startsWith("MemAvailable:")) {
                    var availKb = parseFloat(line.split(/\s+/)[1]) || 0
                    var usedKb = Math.max(0, root._memTotalKb - availKb)
                    root.memPercent = Math.round((usedKb / root._memTotalKb) * 100)
                    root.memText = (usedKb / 1048576.0).toFixed(1) + "G"
                } else if (line.startsWith("GPUBUSY:")) {
                    var busy = parseFloat(line.substring(8))
                    if (!isNaN(busy)) {
                        root.gpuPercent = Math.max(0, Math.min(100, Math.round(busy)))
                        root.gpuAvailable = true
                    }
                } else if (line.startsWith("VRAM:")) {
                    var vparts = line.substring(5).trim().split(/\s+/)
                    var vUsed = parseFloat(vparts[0]) || 0
                    var vTotal = parseFloat(vparts[1]) || 0
                    if (vTotal > 0) {
                        root.vramPercent = Math.round((vUsed / vTotal) * 100)
                        root.vramText = (vUsed / 1073741824.0).toFixed(1) + "G"
                    }
                } else if (line.startsWith("up ")) {
                    root.uptimeText = line.substring(3)
                }
            }
        }
    }

    property real _memTotalKb: 1

    property Timer timer: Timer {
        interval: 3000
        repeat: true
        running: true
        onTriggered: root.refresh()
    }

    Component.onCompleted: refresh()
}
