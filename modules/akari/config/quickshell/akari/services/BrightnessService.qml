pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

QtObject {
    id: root

    property bool available: true
    property bool hardwareBacklight: false
    property int level: 100
    property bool pendingOsd: false

    function refresh() {
        if (!readProc.running) readProc.running = true
    }

    function refreshAndShow() {
        pendingOsd = true
        refresh()
    }

    function setBrightness(pct) {
        var clamped = Math.max(15, Math.min(100, Math.round(pct)))
        level = clamped
        if (hardwareBacklight) {
            Quickshell.execDetached(["brightnessctl", "-c", "backlight", "-q", "set", clamped + "%"])
        } else {
            if (clamped >= 99) {
                Quickshell.execDetached(["bash", "-c", "pkill -x hyprsunset 2>/dev/null || true"])
            } else {
                Quickshell.execDetached(["bash", "-c", "pkill -x hyprsunset 2>/dev/null || true; hyprsunset -i -g " + clamped])
            }
        }
    }

    property Process readProc: Process {
        command: ["brightnessctl", "-c", "backlight", "-m"]
        property bool _foundBacklight: false
        stdout: SplitParser {
            onRead: data => {
                var parts = data.trim().split(",")
                if (parts.length >= 4 && parts[1] === "backlight") {
                    var pctStr = parts[3].replace("%", "")
                    var val = parseInt(pctStr)
                    if (!isNaN(val)) {
                        readProc._foundBacklight = true
                        root.hardwareBacklight = true
                        root.available = true
                        root.level = val
                    }
                }
            }
        }
        onExited: {
            if (!readProc._foundBacklight) {
                root.hardwareBacklight = false
                root.available = true
            }
            readProc._foundBacklight = false
            if (root.pendingOsd) {
                root.pendingOsd = false
                ShellState.showOsd("brightness")
            }
        }
    }

    Component.onCompleted: refresh()
}
