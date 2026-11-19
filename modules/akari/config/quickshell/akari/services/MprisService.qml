pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.Mpris

QtObject {
    id: root

    property int revision: 0
    property var players: Mpris.players.values
    property var activePlayer: selectPlayer(players, revision)

    readonly property bool available: activePlayer !== null
    readonly property bool playing: available && activePlayer.isPlaying
    readonly property string title: available ? (activePlayer.trackTitle || activePlayer.identity || "再生中") : ""
    readonly property string artist: available ? (activePlayer.trackArtist || "") : ""
    readonly property string artUrl: {
        if (!available) return ""
        var u = activePlayer.trackArtUrl || ""
        if (u === "") return ""
        if (u.startsWith("/")) return "file://" + u
        return u
    }
    readonly property string badgeCode: {
        if (!available) return "MPRIS"
        var id = (activePlayer.identity || activePlayer.trackTitle || "AUD").toUpperCase().replace(/[^A-Z0-9]/g, "")
        return id.length >= 3 ? id.slice(0, 3) : (id || "AUD")
    }

    property real positionSec: 0
    property real lengthSec: 0
    readonly property real progressRatio: (lengthSec > 0) ? Math.max(0.0, Math.min(1.0, positionSec / lengthSec)) : 0.0
    readonly property string positionText: formatTime(positionSec)
    readonly property string lengthText: formatTime(lengthSec)

    function formatTime(sec) {
        if (!sec || isNaN(sec) || sec < 0) return "00:00"
        var s = Math.floor(sec)
        var m = Math.floor(s / 60)
        var r = s % 60
        return ("0" + m).slice(-2) + ":" + ("0" + r).slice(-2)
    }

    function syncProgress() {
        if (!activePlayer) {
            positionSec = 0
            lengthSec = 0
            return
        }
        positionSec = activePlayer.position || 0
        lengthSec = activePlayer.length || 0
    }

    function selectPlayer(list, _rev) {
        if (!list) return null
        var valid = []
        for (var i = 0; i < list.length; i++) {
            var p = list[i]
            if (p && p.playbackState !== MprisPlaybackState.Stopped) valid.push(p)
        }
        valid.sort(function(a, b) {
            if (a.isPlaying !== b.isPlaying) return a.isPlaying ? -1 : 1
            return (a.dbusName || "") < (b.dbusName || "") ? -1 : 1
        })
        return valid.length > 0 ? valid[0] : null
    }

    function togglePlaying() {
        if (activePlayer && activePlayer.canTogglePlaying) activePlayer.togglePlaying()
    }

    function next() {
        if (activePlayer && activePlayer.canGoNext) activePlayer.next()
    }

    function previous() {
        if (activePlayer && activePlayer.canGoPrevious) activePlayer.previous()
    }

    property Timer posTimer: Timer {
        interval: 1000
        repeat: true
        running: root.available
        triggeredOnStart: true
        onTriggered: root.syncProgress()
    }

    property Instantiator watcher: Instantiator {
        model: Mpris.players
        delegate: QtObject {
            required property var modelData
            property Connections conn: Connections {
                target: modelData
                function onPlaybackStateChanged() { root.revision++; root.syncProgress() }
                function onTrackTitleChanged() { root.revision++; root.syncProgress() }
                function onTrackArtistChanged() { root.revision++; root.syncProgress() }
                function onTrackArtUrlChanged() { root.revision++ }
            }
        }
    }
}
