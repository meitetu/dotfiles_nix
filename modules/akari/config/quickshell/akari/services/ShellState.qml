pragma Singleton
import QtQuick

QtObject {
    id: root

    property bool barVisible: true
    property bool launcherOpen: false
    property bool panelOpen: false
    property bool powerOpen: false
    property bool cheatsheetOpen: false
    property bool sysmonOpen: false
    property bool trayExpanded: false
    property string activeScreenName: ""

    // Hardware OSD only ("volume" | "mic" | "brightness") — no IME popup
    property bool osdVisible: false
    property string osdMode: "volume"

    function resolveScreen(explicitScreen) {
        if (explicitScreen && explicitScreen !== "") return explicitScreen
        if (Compositor.focusedOutputName !== "") return Compositor.focusedOutputName
        return "DP-3"
    }

    function closeAllModals() {
        launcherOpen = false
        panelOpen = false
        powerOpen = false
        cheatsheetOpen = false
        sysmonOpen = false
    }

    function toggleLauncher(screenName) {
        var next = !launcherOpen
        closeAllModals()
        if (next) activeScreenName = resolveScreen(screenName)
        launcherOpen = next
    }

    function togglePanel(screenName) {
        var next = !panelOpen
        closeAllModals()
        if (next) activeScreenName = resolveScreen(screenName)
        panelOpen = next
    }

    function togglePower(screenName) {
        var next = !powerOpen
        closeAllModals()
        if (next) activeScreenName = resolveScreen(screenName)
        powerOpen = next
    }

    function toggleCheatsheet(screenName) {
        var next = !cheatsheetOpen
        closeAllModals()
        if (next) activeScreenName = resolveScreen(screenName)
        cheatsheetOpen = next
    }

    function toggleSysmon(screenName) {
        var next = !sysmonOpen
        closeAllModals()
        if (next) activeScreenName = resolveScreen(screenName)
        sysmonOpen = next
    }

    function toggleBar() {
        barVisible = !barVisible
    }

    function toggleTray() {
        trayExpanded = !trayExpanded
    }

    function showOsd(mode) {
        if (mode === "ime") return
        osdMode = mode
        osdVisible = true
        osdHideTimer.restart()
    }

    property Timer osdHideTimer: Timer {
        interval: 1350
        repeat: false
        onTriggered: root.osdVisible = false
    }
}
