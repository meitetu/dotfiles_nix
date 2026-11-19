pragma Singleton
import QtQuick
import Quickshell.Io

// ============================================================================
// SysMonitorService: full-system telemetry for the System Monitor dashboard.
// Polls only while the dashboard is open (ShellState.sysmonOpen).
// ============================================================================
QtObject {
    id: root

    // --- CPU ---------------------------------------------------------------
    property int cpuPercent: 0
    property var cpuCores: []          // per-core utilisation percentages
    property real cpuTempC: 0
    property var cpuHistory: []

    // --- Memory / Swap -----------------------------------------------------
    property int memPercent: 0
    property string memUsedText: "0.0G"
    property string memTotalText: "0.0G"
    property string memFreeText: "0.0G"
    property int swapPercent: 0
    property string swapUsedText: "0.0G"
    property string swapTotalText: "0.0G"
    property var memHistory: []

    // --- GPU (amdgpu sysfs / hwmon) ---------------------------------------
    property bool gpuAvailable: false
    property int gpuPercent: 0
    property real gpuTempC: 0
    property real gpuPowerW: 0
    property int vramPercent: 0
    property string vramUsedText: "0.0G"
    property string vramTotalText: "0.0G"
    property var gpuHistory: []

    // --- Storage -----------------------------------------------------------
    property string diskUsedText: "0G"
    property string diskTotalText: "0G"
    property int diskPercent: 0
    property real diskReadRate: 0    // bytes/s
    property real diskWriteRate: 0   // bytes/s

    // --- Network -----------------------------------------------------------
    property real netRxRate: 0       // bytes/s, summed over physical interfaces
    property real netTxRate: 0
    property var netRxHistory: []
    property real netRxPeak: 1

    // --- Load / Uptime -----------------------------------------------------
    property real load1: 0
    property real load5: 0
    property real load15: 0
    property string uptimeText: ""

    // --- Processes ---------------------------------------------------------
    property var processes: []       // [{ cpu, pid, name }]

    readonly property int historyLength: 40
    readonly property int coreCount: cpuCores.length

    // --- Internal state ----------------------------------------------------
    property var _prevCoreIdle: []
    property var _prevCoreTotal: []
    property real _prevAllIdle: 0
    property real _prevAllTotal: 0
    property var _prevNetRx: ({})
    property var _prevNetTx: ({})
    property var _prevDiskRead: ({})
    property var _prevDiskWrite: ({})
    property var _procs: []
    property real _rxAccum: 0
    property real _txAccum: 0
    property real _readAccum: 0
    property real _writeAccum: 0
    property real _lastSampleMs: 0

    function pushHistory(list, value) {
        var out = list.slice()
        out.push(value)
        if (out.length > historyLength) out.shift()
        return out
    }

    function fmtBytes(bytes) {
        if (!isFinite(bytes) || bytes <= 0) return "0B"
        var units = ["B", "K", "M", "G", "T"]
        var i = 0
        var v = bytes
        while (v >= 1024 && i < units.length - 1) { v /= 1024; i++ }
        return (i === 0 ? String(Math.round(v)) : (v >= 100 ? String(Math.round(v)) : v.toFixed(1))) + units[i]
    }

    function fmtRate(bytesPerSec) {
        return fmtBytes(bytesPerSec) + "/s"
    }

    function refresh() {
        if (!probeProc.running) probeProc.running = true
    }

    property Process probeProc: Process {
        command: [
            "bash", "-c",
            "awk '/^cpu/ { idx = ($1 == \"cpu\") ? \"all\" : substr($1, 4); " +
            "  idle = $5 + $6; total = $2 + $3 + $4 + $5 + $6 + $7 + $8 + $9; " +
            "  print \"CPU\", idx, idle, total }' /proc/stat; " +
            "awk '/^MemTotal:/ { t = $2 } /^MemAvailable:/ { a = $2 } " +
            "  /^SwapTotal:/ { st = $2 } /^SwapFree:/ { sf = $2 } " +
            "  END { print \"MEM\", t - a, t; print \"SWAP\", st - sf, st }' /proc/meminfo; " +
            "awk '{ print \"LOAD\", $1, $2, $3 }' /proc/loadavg; " +
            "for h in /sys/class/hwmon/hwmon*; do " +
            "  n=$(cat \"$h/name\" 2>/dev/null) || continue; " +
            "  case \"$n\" in " +
            "    coretemp) echo \"CPUTEMP $(cat \"$h/temp1_input\" 2>/dev/null)\" ;; " +
            "    amdgpu) echo \"GPUTEMP $(cat \"$h/temp1_input\" 2>/dev/null)\"; " +
            "            echo \"GPUPWR $(cat \"$h/power1_average\" 2>/dev/null)\" ;; " +
            "  esac; " +
            "done; " +
            "for f in /sys/class/drm/card*/device/gpu_busy_percent; do " +
            "  [ -r \"$f\" ] && { echo \"GPUBUSY $(cat \"$f\")\"; break; }; " +
            "done; " +
            "for d in /sys/class/drm/card*/device; do " +
            "  [ -r \"$d/mem_info_vram_used\" ] && { " +
            "    echo \"VRAM $(cat \"$d/mem_info_vram_used\") $(cat \"$d/mem_info_vram_total\")\"; break; }; " +
            "done; " +
            "for i in /sys/class/net/*; do " +
            "  n=${i##*/}; [ \"$n\" = \"lo\" ] && continue; [ -e \"$i/device\" ] || continue; " +
            "  echo \"NET $n $(cat \"$i/statistics/rx_bytes\" 2>/dev/null) $(cat \"$i/statistics/tx_bytes\" 2>/dev/null)\"; " +
            "done; " +
            "for b in /sys/block/*; do " +
            "  n=${b##*/}; case \"$n\" in loop*|zram*|sr*|ram*) continue ;; esac; " +
            "  awk -v n=\"$n\" '{ print \"DISKIO\", n, $3, $7 }' \"$b/stat\" 2>/dev/null; " +
            "done; " +
            "df -B1 --output=used,size / 2>/dev/null | tail -n 1 | awk '{ print \"DISKROOT\", $1, $2 }'; " +
            "ps -eo pcpu=,pid=,comm= --sort=-pcpu 2>/dev/null | head -n 6 | sed 's/^/PROC /'; " +
            "awk '{ print \"UPTIME\", int($1) }' /proc/uptime"
        ]

        stdout: SplitParser {
            onRead: line => {
                var s = line.trim()
                if (s === "") return

                if (s.startsWith("CPU ")) {
                    var p = s.split(/\s+/)
                    var idx = p[1]
                    var idle = parseFloat(p[2]) || 0
                    var total = parseFloat(p[3]) || 0
                    if (idx === "all") {
                        if (root._prevAllTotal > 0 && total > root._prevAllTotal) {
                            var dTotal = total - root._prevAllTotal
                            var dIdle = idle - root._prevAllIdle
                            root.cpuPercent = Math.max(0, Math.min(100, Math.round((1 - dIdle / dTotal) * 100)))
                        }
                        root._prevAllTotal = total
                        root._prevAllIdle = idle
                    } else {
                        var ci = parseInt(idx)
                        if (isNaN(ci)) return
                        var cores = root.cpuCores.slice()
                        var prevIdle = root._prevCoreIdle.slice()
                        var prevTotal = root._prevCoreTotal.slice()
                        if (prevTotal[ci] > 0 && total > prevTotal[ci]) {
                            var ct = total - prevTotal[ci]
                            var cidle = idle - prevIdle[ci]
                            cores[ci] = Math.max(0, Math.min(100, Math.round((1 - cidle / ct) * 100)))
                        }
                        if (cores[ci] === undefined) cores[ci] = 0
                        prevIdle[ci] = idle
                        prevTotal[ci] = total
                        root.cpuCores = cores
                        root._prevCoreIdle = prevIdle
                        root._prevCoreTotal = prevTotal
                    }
                } else if (s.startsWith("CPUTEMP ")) {
                    var ctm = parseFloat(s.substring(8))
                    if (!isNaN(ctm) && ctm > 0) root.cpuTempC = ctm / 1000
                } else if (s.startsWith("GPUTEMP ")) {
                    var gtm = parseFloat(s.substring(8))
                    if (!isNaN(gtm) && gtm > 0) root.gpuTempC = gtm / 1000
                } else if (s.startsWith("GPUPWR ")) {
                    var gpw = parseFloat(s.substring(7))
                    if (!isNaN(gpw) && gpw > 0) root.gpuPowerW = gpw / 1000000
                } else if (s.startsWith("GPUBUSY ")) {
                    var busy = parseFloat(s.substring(8))
                    if (!isNaN(busy)) {
                        root.gpuPercent = Math.max(0, Math.min(100, Math.round(busy)))
                        root.gpuAvailable = true
                    }
                } else if (s.startsWith("VRAM ")) {
                    var vp = s.split(/\s+/)
                    var vUsed = parseFloat(vp[1]) || 0
                    var vTotal = parseFloat(vp[2]) || 0
                    if (vTotal > 0) {
                        root.vramPercent = Math.round((vUsed / vTotal) * 100)
                        root.vramUsedText = root.fmtBytes(vUsed)
                        root.vramTotalText = root.fmtBytes(vTotal)
                        root.gpuAvailable = true
                    }
                } else if (s.startsWith("MEM ")) {
                    var mp = s.split(/\s+/)
                    var usedKb = parseFloat(mp[1]) || 0
                    var totalKb = parseFloat(mp[2]) || 1
                    root.memPercent = Math.round((usedKb / totalKb) * 100)
                    root.memUsedText = (usedKb / 1048576).toFixed(1) + "G"
                    root.memTotalText = (totalKb / 1048576).toFixed(1) + "G"
                    root.memFreeText = (Math.max(0, totalKb - usedKb) / 1048576).toFixed(1) + "G"
                } else if (s.startsWith("SWAP ")) {
                    var sp = s.split(/\s+/)
                    var sUsed = parseFloat(sp[1]) || 0
                    var sTotal = parseFloat(sp[2]) || 0
                    root.swapPercent = sTotal > 0 ? Math.round((sUsed / sTotal) * 100) : 0
                    root.swapUsedText = (sUsed / 1048576).toFixed(1) + "G"
                    root.swapTotalText = (sTotal / 1048576).toFixed(1) + "G"
                } else if (s.startsWith("LOAD ")) {
                    var lp = s.split(/\s+/)
                    root.load1 = parseFloat(lp[1]) || 0
                    root.load5 = parseFloat(lp[2]) || 0
                    root.load15 = parseFloat(lp[3]) || 0
                } else if (s.startsWith("NET ")) {
                    var np = s.split(/\s+/)
                    var iface = np[1]
                    var rx = parseFloat(np[2]) || 0
                    var tx = parseFloat(np[3]) || 0
                    var prevRx = root._prevNetRx[iface]
                    var prevTx = root._prevNetTx[iface]
                    if (prevRx !== undefined) {
                        root._rxAccum += Math.max(0, rx - prevRx)
                        root._txAccum += Math.max(0, tx - prevTx)
                    }
                    root._prevNetRx[iface] = rx
                    root._prevNetTx[iface] = tx
                } else if (s.startsWith("DISKIO ")) {
                    var dp = s.split(/\s+/)
                    var dev = dp[1]
                    var rsec = parseFloat(dp[2]) || 0
                    var wsec = parseFloat(dp[3]) || 0
                    var pRead = root._prevDiskRead[dev]
                    var pWrite = root._prevDiskWrite[dev]
                    if (pRead !== undefined) {
                        root._readAccum += Math.max(0, rsec - pRead)
                        root._writeAccum += Math.max(0, wsec - pWrite)
                    }
                    root._prevDiskRead[dev] = rsec
                    root._prevDiskWrite[dev] = wsec
                } else if (s.startsWith("DISKROOT ")) {
                    var rp = s.split(/\s+/)
                    var usedB = parseFloat(rp[1]) || 0
                    var totalB = parseFloat(rp[2]) || 1
                    root.diskPercent = Math.round((usedB / totalB) * 100)
                    root.diskUsedText = root.fmtBytes(usedB)
                    root.diskTotalText = root.fmtBytes(totalB)
                } else if (s.startsWith("PROC ")) {
                    var pp = s.substring(5).trim().split(/\s+/)
                    if (pp.length >= 3) {
                        root._procs.push({
                            cpu: parseFloat(pp[0]) || 0,
                            pid: parseInt(pp[1]) || 0,
                            name: pp.slice(2).join(" ")
                        })
                    }
                } else if (s.startsWith("UPTIME ")) {
                    var secs = parseInt(s.substring(7)) || 0
                    var d = Math.floor(secs / 86400)
                    var h = Math.floor((secs % 86400) / 3600)
                    var m = Math.floor((secs % 3600) / 60)
                    var parts = []
                    if (d > 0) parts.push(d + "日")
                    if (h > 0) parts.push(h + "時間")
                    parts.push(m + "分")
                    root.uptimeText = parts.join(" ")
                }
            }
        }

        onExited: {
            var now = Date.now()
            var dt = root._lastSampleMs > 0 ? (now - root._lastSampleMs) / 1000 : 0
            if (dt > 0.05) {
                root.netRxRate = root._rxAccum / dt
                root.netTxRate = root._txAccum / dt
                root.diskReadRate = root._readAccum * 512 / dt
                root.diskWriteRate = root._writeAccum * 512 / dt
            } else {
                root.netRxRate = 0
                root.netTxRate = 0
                root.diskReadRate = 0
                root.diskWriteRate = 0
            }
            root._lastSampleMs = now
            root._rxAccum = 0
            root._txAccum = 0
            root._readAccum = 0
            root._writeAccum = 0

            root.cpuHistory = root.pushHistory(root.cpuHistory, root.cpuPercent)
            root.memHistory = root.pushHistory(root.memHistory, root.memPercent)
            root.gpuHistory = root.pushHistory(root.gpuHistory, root.gpuPercent)
            root.netRxHistory = root.pushHistory(root.netRxHistory, root.netRxRate)
            root.netRxPeak = Math.max(65536, root.netRxHistory.reduce(function (a, b) { return Math.max(a, b) }, 0))

            root.processes = root._procs.slice(0, 5)
            root._procs = []
        }
    }

    property Timer pollTimer: Timer {
        interval: 1000
        repeat: true
        running: ShellState.sysmonOpen
        onRunningChanged: if (running) root.refresh()
    }
}
