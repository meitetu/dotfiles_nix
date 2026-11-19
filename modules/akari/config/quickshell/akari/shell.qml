//@ pragma UseQApplication
import QtQuick
import Quickshell
import Quickshell.Io
import "services"
import "bar"
import "osd"
import "panel"
import "overlays"
import "dashboard"

ShellRoot {
    id: root

    Component.onCompleted: {
        var _ime = ImeService.ready
        var _aud = AudioService.volume
        var _not = NotifService.count
        var _net = ConnectivityService.netConnected
        var _apps = AppCatalogService.apps
        var _cava = CavaService.enabled
        var _sysmon = SysMonitorService.historyLength
    }

    // IPC Endpoint for keybinds & akari-ctl
    IpcHandler {
        target: "akari"

        function ping(): string { return "pong" }
        function reload() { Quickshell.reload(false) }

        function lock() { LockService.activate() }
        function unlock() { LockService.unlock() }
        function toggleLauncher() { ShellState.toggleLauncher("") }
        function toggleLauncherOn(mon: string) { ShellState.toggleLauncher(mon) }
        function togglePanel() { ShellState.togglePanel("") }
        function togglePanelOn(mon: string) { ShellState.togglePanel(mon) }
        function togglePower() { ShellState.togglePower("") }
        function toggleCheatsheet() { ShellState.toggleCheatsheet("") }
        function toggleSysmon() { ShellState.toggleSysmon("") }
        function toggleSysmonOn(mon: string) { ShellState.toggleSysmon(mon) }
        function toggleBar() { ShellState.toggleBar() }
        function toggleTray() { ShellState.toggleTray() }
        function toggleDnd() { NotifService.toggleDnd() }
        function toggleDarkMode() { Theme.toggleDarkMode() }
        function toggleCava() { CavaService.toggle() }

        function showVolumeOsd() { AudioService.refreshAndShow("volume") }
        function showMicOsd() { AudioService.refreshAndShow("mic") }
        function showBrightnessOsd() { BrightnessService.refreshAndShow() }
    }

    Variants {
        model: Quickshell.screens
        TopBar {}
    }

    Variants {
        model: Quickshell.screens
        CavaBar {}
    }

    Variants {
        model: Quickshell.screens
        Launcher {}
    }

    Variants {
        model: Quickshell.screens
        OsdWindow {}
    }

    Variants {
        model: Quickshell.screens
        NotifToasts {}
    }

    Variants {
        model: Quickshell.screens
        ControlCenter {}
    }

    Variants {
        model: Quickshell.screens
        PowerOverlay {}
    }

    Variants {
        model: Quickshell.screens
        CheatSheet {}
    }

    Variants {
        model: Quickshell.screens
        SysMonitor {}
    }

    LockScreen {}
}
