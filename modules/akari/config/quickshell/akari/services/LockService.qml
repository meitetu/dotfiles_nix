pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pam

QtObject {
    id: root

    property bool locked: false
    property string wallpaperUrl: ""
    property string inputText: ""
    property string errorText: ""
    property bool hasError: false
    property bool authenticating: false
    property bool faceScanning: false
    property string _pendingPassword: ""

    function refreshWallpaper() {
        if (!wallProc.running) wallProc.running = true
    }

    property Process wallProc: Process {
        command: [
            "bash", "-c",
            "p=$(awww query 2>/dev/null | sed -n 's/.*image: //p' | head -n 1); " +
            "if [ -n \"$p\" ] && [ -f \"$p\" ]; then echo \"$p\"; exit 0; fi; " +
            "if [ -f \"$HOME/.local/state/akari-theme/wallpaper\" ]; then " +
            "  s=$(head -n 1 \"$HOME/.local/state/akari-theme/wallpaper\"); " +
            "  [ -f \"$s\" ] && echo \"$s\" && exit 0; " +
            "fi; " +
            "[ -f \"$HOME/.local/share/wallpapers/akari.jpg\" ] && echo \"$HOME/.local/share/wallpapers/akari.jpg\""
        ]
        stdout: SplitParser {
            onRead: line => {
                var clean = line.trim()
                if (clean !== "") {
                    root.wallpaperUrl = clean.startsWith("file://") ? clean : ("file://" + clean)
                }
            }
        }
    }

    function activate() {
        if (locked) return
        ShellState.closeAllModals()
        refreshWallpaper()
        inputText = ""
        _pendingPassword = ""
        errorText = ""
        hasError = false
        authenticating = false
        faceScanning = true
        locked = true

        if (!pwPam.active) pwPam.start()
        if (!facePam.active) facePam.start()
    }

    function unlock() {
        if (facePam.active) facePam.abort()
        if (pwPam.active) pwPam.abort()
        _pendingPassword = ""
        inputText = ""
        errorText = ""
        hasError = false
        authenticating = false
        faceScanning = false
        locked = false
    }

    function retryFace() {
        if (!locked) return
        if (facePam.active) facePam.abort()
        hasError = false
        errorText = ""
        faceScanning = true
        faceRestartTimer.restart()
    }

    property Timer faceRestartTimer: Timer {
        interval: 80
        repeat: false
        onTriggered: {
            if (root.locked && !facePam.active) {
                facePam.start()
            }
        }
    }

    function submit() {
        if (!locked) return
        if (inputText === "") {
            retryFace()
            return
        }

        hasError = false
        errorText = ""
        authenticating = true
        _pendingPassword = inputText

        if (pwPam.active && pwPam.responseRequired) {
            var pw = _pendingPassword
            _pendingPassword = ""
            pwPam.respond(pw)
        } else if (!pwPam.active) {
            pwPam.start()
        }
    }

    // 1. Gaze Face Authentication
    property PamContext facePam: PamContext {
        configDirectory: "/etc/pam.d"
        config: "hyprlock-gaze"

        onMessageChanged: {
            var msg = (message || "").toLowerCase()
            if (msg.indexOf("look at the camera") >= 0) {
                root.faceScanning = true
            } else if (msg.indexOf("not recognized") >= 0 || msg.indexOf("not detected") >= 0 || msg.indexOf("timed out") >= 0 || msg.indexOf("too dark") >= 0) {
                root.faceScanning = false
            }
        }

        onResponseRequiredChanged: {
            if (responseRequired) {
                root.faceScanning = false
                facePam.abort()
            }
        }

        onCompleted: result => {
            root.faceScanning = false
            if (result === PamResult.Success) {
                if (pwPam.active) pwPam.abort()
                root._pendingPassword = ""
                root.inputText = ""
                root.errorText = ""
                root.hasError = false
                root.authenticating = false
                root.locked = false
            }
        }

        onError: err => {
            root.faceScanning = false
        }
    }

    // 2. Instant Password Authentication
    property PamContext pwPam: PamContext {
        configDirectory: "/etc/pam.d"
        config: "hyprlock"

        onResponseRequiredChanged: {
            if (responseRequired && root._pendingPassword !== "") {
                var pw = root._pendingPassword
                root._pendingPassword = ""
                pwPam.respond(pw)
            }
        }

        onCompleted: result => {
            root.authenticating = false
            if (result === PamResult.Success) {
                if (facePam.active) facePam.abort()
                root._pendingPassword = ""
                root.inputText = ""
                root.errorText = ""
                root.hasError = false
                root.faceScanning = false
                root.locked = false
            } else {
                root._pendingPassword = ""
                root.inputText = ""
                root.hasError = true
                root.errorText = "パスワードが正しくありません"
                pwRestartTimer.restart()
            }
        }

        onError: err => {
            root.authenticating = false
            root._pendingPassword = ""
            root.hasError = true
            root.errorText = "認証エラーが発生しました"
            pwRestartTimer.restart()
        }
    }

    property Timer pwRestartTimer: Timer {
        interval: 120
        repeat: false
        onTriggered: {
            if (root.locked && !pwPam.active) {
                pwPam.start()
            }
        }
    }

    Component.onCompleted: refreshWallpaper()
}
