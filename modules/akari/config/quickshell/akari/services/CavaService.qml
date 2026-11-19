pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

QtObject {
    id: root

    // ========================================================================
    // Persistent Bottom Cava Bar State & Live 60fps PipeWire Spectrum Stream
    // ========================================================================
    property bool enabled: true
    property int barCount: 64
    property int barHeight: 64
    // "overlay" = WlrLayer.Top click-through | "desktop" = WlrLayer.Bottom | "reserve" = WlrLayer.Top with exclusiveZone
    property string layerMode: "overlay"
    property bool autoHideSilent: false

    property bool stateLoaded: false
    property bool activeAudio: false
    property string lastRawLine: ""

    property var values: {
        var arr = []
        for (var i = 0; i < 64; i++) arr.push(0)
        return arr
    }

    readonly property string stateFilePath: (Quickshell.env("XDG_STATE_HOME") || (Quickshell.env("HOME") + "/.local/state")) + "/akari-theme/cava.json"
    readonly property string rawConfPath: Qt.resolvedUrl("cava-raw.conf").toString().replace(/^file:\/\//, "")

    function zeroValues() {
        var arr = []
        for (var i = 0; i < root.barCount; i++) arr.push(0)
        root.values = arr
        root.activeAudio = false
        root.lastRawLine = ""
    }

    function toggle() {
        setEnabled(!root.enabled)
    }

    function setEnabled(v) {
        if (root.enabled === v) return
        root.enabled = v
        if (!v) root.zeroValues()
        root.saveState()
    }

    function setLayerMode(mode) {
        if (mode !== "overlay" && mode !== "desktop" && mode !== "reserve") return
        if (root.layerMode === mode) return
        root.layerMode = mode
        root.saveState()
    }

    function setBarHeight(px) {
        var clamped = Math.max(32, Math.min(160, Math.round(px)))
        if (root.barHeight === clamped) return
        root.barHeight = clamped
        root.saveState()
    }

    function toggleAutoHideSilent() {
        root.autoHideSilent = !root.autoHideSilent
        root.saveState()
    }

    function saveState() {
        if (!root.stateLoaded) return
        var payload = JSON.stringify({
            enabled: root.enabled,
            barHeight: root.barHeight,
            layerMode: root.layerMode,
            autoHideSilent: root.autoHideSilent
        })
        Quickshell.execDetached([
            "python3", "-c",
            "import os, sys; p = sys.argv[1]; os.makedirs(os.path.dirname(p), exist_ok=True); open(p, 'w').write(sys.argv[2])",
            root.stateFilePath,
            payload
        ])
    }

    property Process loadProc: Process {
        command: [
            "python3", "-c",
            "import os, sys; p = sys.argv[1]; print(open(p).read().strip() if os.path.exists(p) else '{}')",
            root.stateFilePath
        ]
        stdout: SplitParser {
            onRead: data => {
                try {
                    var obj = JSON.parse(data.trim())
                    if (typeof obj.enabled === "boolean") root.enabled = obj.enabled
                    if (typeof obj.barHeight === "number") root.barHeight = Math.max(32, Math.min(160, Math.round(obj.barHeight)))
                    if (obj.layerMode === "overlay" || obj.layerMode === "desktop" || obj.layerMode === "reserve") {
                        root.layerMode = obj.layerMode
                    }
                    if (typeof obj.autoHideSilent === "boolean") root.autoHideSilent = obj.autoHideSilent
                } catch (e) {}
            }
        }
        onExited: {
            root.stateLoaded = true
        }
    }

    property Process cavaProc: Process {
        command: ["cava", "-p", root.rawConfPath]
        running: root.stateLoaded && root.enabled

        stdout: SplitParser {
            onRead: data => {
                // Strip any initial OSC terminal title sequence emitted by cava 1.0.0
                var clean = data.replace(/\x1b\][^\x07]*\x07/g, "").trim()
                if (clean === "") return
                if (clean === root.lastRawLine) return
                root.lastRawLine = clean

                var parts = clean.split(";")
                var next = []
                var anySound = false
                var count = root.barCount
                for (var i = 0; i < count; i++) {
                    var raw = i < parts.length ? parseInt(parts[i], 10) : 0
                    if (isNaN(raw) || raw < 0) raw = 0
                    else if (raw > 1000) raw = 1000
                    if (raw > 8) anySound = true
                    next.push(raw)
                }
                root.activeAudio = anySound
                root.values = next
            }
        }

        onExited: {
            if (root.enabled && root.stateLoaded) {
                restartTimer.restart()
            }
        }
    }

    property Timer restartTimer: Timer {
        interval: 1500
        repeat: false
        onTriggered: {
            if (root.enabled && root.stateLoaded && !cavaProc.running) {
                cavaProc.running = true
            }
        }
    }

    Component.onCompleted: {
        loadProc.running = true
    }
}
