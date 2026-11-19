pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

QtObject {
    id: root

    property bool netConnected: true
    property string netKind: "wifi"       // "wifi" | "ethernet" | "offline"
    property string netTitle: "Wi-Fi"
    property string netSubtitle: "接続済"

    property bool hasBattery: false
    property int batteryPercent: 100
    property bool batteryCharging: false

    function refresh() {
        if (!probeProc.running) probeProc.running = true
    }

    function openNetworkSettings() {
        Quickshell.execDetached(["bash", "-c", "command -v nm-connection-editor >/dev/null && nm-connection-editor || kcmshell6 kcm_networkmanagement"])
    }

    property Process probeProc: Process {
        command: [
            "bash", "-c",
            "nmcli -t -f TYPE,STATE,CONNECTION dev 2>/dev/null | head -n 8; " +
            "echo '---BAT---'; for b in /sys/class/power_supply/BAT*; do [ -f \"$b/capacity\" ] && echo \"$(cat \"$b/capacity\"):$(cat \"$b/status\" 2>/dev/null)\"; done"
        ]
        property string _buf: ""
        stdout: SplitParser {
            onRead: line => { probeProc._buf += line + "\n" }
        }
        onExited: {
            var raw = probeProc._buf
            probeProc._buf = ""

            var batSplit = raw.split("---BAT---")
            var netPart = (batSplit[0] || "").trim()
            var batPart = (batSplit[1] || "").trim()

            // Parse Network
            var foundWifi = ""
            var foundEth = ""
            var netLines = netPart.split("\n")
            for (var i = 0; i < netLines.length; i++) {
                var cols = netLines[i].split(":")
                if (cols.length >= 3 && cols[1] === "connected") {
                    if (cols[0] === "wifi") foundWifi = cols.slice(2).join(":")
                    else if (cols[0] === "ethernet") foundEth = cols.slice(2).join(":")
                }
            }
            if (foundWifi !== "") {
                root.netConnected = true
                root.netKind = "wifi"
                root.netTitle = "Wi-Fi"
                root.netSubtitle = foundWifi + " · 接続済"
            } else if (foundEth !== "") {
                root.netConnected = true
                root.netKind = "ethernet"
                root.netTitle = "有線 LAN"
                root.netSubtitle = foundEth + " · 接続済"
            } else {
                root.netConnected = false
                root.netKind = "offline"
                root.netTitle = "ネットワーク"
                root.netSubtitle = "未接続"
            }

            // Parse Battery
            if (batPart !== "") {
                var firstBat = batPart.split("\n")[0].split(":")
                var cap = parseInt(firstBat[0])
                if (!isNaN(cap)) {
                    root.hasBattery = true
                    root.batteryPercent = Math.max(0, Math.min(100, cap))
                    root.batteryCharging = (firstBat[1] || "").indexOf("Charging") >= 0
                }
            } else {
                root.hasBattery = false
            }
        }
    }

    property Timer pollTimer: Timer {
        interval: 5000
        repeat: true
        running: true
        onTriggered: root.refresh()
    }

    Component.onCompleted: refresh()
}
