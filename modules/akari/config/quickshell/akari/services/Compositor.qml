pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Hyprland

// ============================================================================
// Compositor: Hyprland access layer for the Akari shell.
// Keeps a single place for workspace / focused-window queries so the rest of
// the QML does not import Quickshell.Hyprland directly.
// ============================================================================
QtObject {
    id: root

    // --- Workspaces ---------------------------------------------------------
    // Normalised: [{ id, index, name, isActive, isOccupied, windowCount, output }]
    readonly property var workspaceList: {
        var out = []
        var list = Hyprland.workspaces.values
        for (var i = 0; i < list.length; i++) {
            var ws = list[i]
            var toplevels = (ws.toplevels && ws.toplevels.values) ? ws.toplevels.values : []
            out.push({
                id: ws.id,
                index: ws.id,
                name: ws.name || "",
                isActive: (Hyprland.focusedWorkspace && Hyprland.focusedWorkspace.id === ws.id),
                isOccupied: toplevels.length > 0,
                windowCount: toplevels.length,
                output: ws.monitor ? ws.monitor.name : ""
            })
        }
        out.sort(function (a, b) { return a.index - b.index })
        return out
    }

    function workspaceAt(index) {
        for (var i = 0; i < workspaceList.length; i++) {
            if (workspaceList[i].index === index) return workspaceList[i]
        }
        return null
    }

    readonly property int focusedWorkspaceIndex: {
        for (var i = 0; i < workspaceList.length; i++) {
            if (workspaceList[i].isActive) return workspaceList[i].index
        }
        return 1
    }

    // --- Active window ------------------------------------------------------
    readonly property string activeAppId: {
        if (!Hyprland.activeToplevel) return ""
        var t = Hyprland.activeToplevel
        if (t.wayland && t.wayland.appId) return t.wayland.appId
        if (t.lastIpcObject && t.lastIpcObject.class) return t.lastIpcObject.class
        return ""
    }

    readonly property string activeTitle:
        (Hyprland.activeToplevel && Hyprland.activeToplevel.title) ? Hyprland.activeToplevel.title : ""

    // --- Outputs ------------------------------------------------------------
    readonly property string focusedOutputName:
        (Hyprland.focusedMonitor && Hyprland.focusedMonitor.name) ? Hyprland.focusedMonitor.name : ""

    // --- Actions ------------------------------------------------------------
    function focusWorkspace(index) {
        Hyprland.dispatch("hl.dsp.focus({ workspace = " + index + " })")
    }

    function focusWorkspaceDown() {
        Hyprland.dispatch("hl.dsp.focus({ workspace = 'e+1' })")
    }

    function focusWorkspaceUp() {
        Hyprland.dispatch("hl.dsp.focus({ workspace = 'e-1' })")
    }

    function closeWindow() {
        Hyprland.dispatch("hl.dsp.window.close()")
    }

    function quitSession() {
        Hyprland.dispatch("hl.dsp.exit()")
    }

    function dpms(on) {
        Hyprland.dispatch("hl.dsp.dpms({ action = \"" + (on ? "on" : "off") + "\" })")
    }
}
