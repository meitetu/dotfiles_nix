pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

QtObject {
    id: root

    property int volume: 50
    property bool muted: false
    property int micVolume: 50
    property bool micMuted: false
    property bool pendingOsd: false
    property string pendingOsdMode: "volume"

    readonly property string iconName: {
        if (muted || volume === 0) return "volume_off"
        if (volume < 40) return "volume_down"
        return "volume_up"
    }

    readonly property string micIconName: {
        if (micMuted || micVolume === 0) return "mic_off"
        return "mic"
    }

    function refresh() {
        if (!sinkProc.running) sinkProc.running = true
        if (!micProc.running) micProc.running = true
    }

    function refreshAndShow(mode) {
        pendingOsd = true
        pendingOsdMode = mode
        refresh()
    }

    function stepVolume(delta) {
        var op = delta >= 0 ? (Math.abs(delta) + "%+") : (Math.abs(delta) + "%-")
        cmdProc.command = ["wpctl", "set-volume", "-l", "1.0", "@DEFAULT_AUDIO_SINK@", op]
        pendingOsd = true
        pendingOsdMode = "volume"
        cmdProc.running = true
    }

    function setVolume(pct) {
        var clamped = Math.max(0, Math.min(100, Math.round(pct)))
        volume = clamped
        Quickshell.execDetached(["wpctl", "set-volume", "@DEFAULT_AUDIO_SINK@", (clamped / 100.0).toFixed(2)])
    }

    function toggleMute() {
        cmdProc.command = ["wpctl", "set-mute", "@DEFAULT_AUDIO_SINK@", "toggle"]
        pendingOsd = true
        pendingOsdMode = "volume"
        cmdProc.running = true
    }

    function stepMicVolume(delta) {
        var op = delta >= 0 ? (Math.abs(delta) + "%+") : (Math.abs(delta) + "%-")
        cmdProc.command = ["wpctl", "set-volume", "-l", "1.0", "@DEFAULT_AUDIO_SOURCE@", op]
        pendingOsd = true
        pendingOsdMode = "mic"
        cmdProc.running = true
    }

    function setMicVolume(pct) {
        var clamped = Math.max(0, Math.min(100, Math.round(pct)))
        micVolume = clamped
        Quickshell.execDetached(["wpctl", "set-volume", "@DEFAULT_AUDIO_SOURCE@", (clamped / 100.0).toFixed(2)])
    }

    function toggleMicMute() {
        cmdProc.command = ["wpctl", "set-mute", "@DEFAULT_AUDIO_SOURCE@", "toggle"]
        pendingOsd = true
        pendingOsdMode = "mic"
        cmdProc.running = true
    }

    function openMixer() {
        Quickshell.execDetached(["bash", "-c", "command -v pavucontrol-qt >/dev/null && pavucontrol-qt || pavucontrol"])
    }

    property Process cmdProc: Process {
        onExited: root.refresh()
    }

    property Process sinkProc: Process {
        command: ["wpctl", "get-volume", "@DEFAULT_AUDIO_SINK@"]
        stdout: SplitParser {
            onRead: data => {
                var line = data.trim()
                if (!line.startsWith("Volume:")) return
                var v = parseFloat(line.split(" ")[1])
                if (!isNaN(v)) root.volume = Math.round(v * 100)
                root.muted = line.indexOf("[MUTED]") >= 0
                if (root.pendingOsd && root.pendingOsdMode === "volume") {
                    root.pendingOsd = false
                    ShellState.showOsd("volume")
                }
            }
        }
    }

    property Process micProc: Process {
        command: ["wpctl", "get-volume", "@DEFAULT_AUDIO_SOURCE@"]
        stdout: SplitParser {
            onRead: data => {
                var line = data.trim()
                if (!line.startsWith("Volume:")) return
                var v = parseFloat(line.split(" ")[1])
                if (!isNaN(v)) root.micVolume = Math.round(v * 100)
                root.micMuted = line.indexOf("[MUTED]") >= 0
                if (root.pendingOsd && root.pendingOsdMode === "mic") {
                    root.pendingOsd = false
                    ShellState.showOsd("mic")
                }
            }
        }
    }

    property Timer pollTimer: Timer {
        interval: 2500
        repeat: true
        running: true
        onTriggered: root.refresh()
    }

    Component.onCompleted: refresh()
}
