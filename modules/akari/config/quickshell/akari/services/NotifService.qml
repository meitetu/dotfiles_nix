pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.Notifications

QtObject {
    id: root

    property bool dnd: false
    property var history: []
    property var popups: []
    property int _seq: 1
    property var _handles: ({})

    readonly property int count: history.length

    property NotificationServer server: NotificationServer {
        bodySupported: true
        actionsSupported: true
        keepOnReload: true
        onNotification: notification => {
            notification.tracked = true
            root.accept(notification)
        }
    }

    function toggleDnd() {
        dnd = !dnd
        if (dnd) popups = []
    }

    function accept(n) {
        var id = _seq++
        _handles[id] = n
        var now = new Date()
        var hh = ("0" + now.getHours()).slice(-2)
        var mm = ("0" + now.getMinutes()).slice(-2)

        var acts = []
        if (n.actions) {
            var rawActs = n.actions.values ? n.actions.values : n.actions
            for (var i = 0; i < rawActs.length && i < 2; i++) {
                if (rawActs[i]) {
                    acts.push({
                        idx: i,
                        text: rawActs[i].text || "実行"
                    })
                }
            }
        }

        var entry = {
            uid: id,
            appName: n.appName || "System",
            summary: n.summary || "通知",
            body: n.body || "",
            urgency: n.urgency,
            timeText: hh + ":" + mm,
            actions: acts,
            createdAt: Date.now(),
            timeoutMs: (n.expireTimeout > 0 ? n.expireTimeout : 5200)
        }

        if (!n.transient) {
            var nextHist = [entry].concat(history)
            if (nextHist.length > 60) nextHist = nextHist.slice(0, 60)
            history = nextHist
        }

        if (!dnd && !ShellState.panelOpen) {
            var nextPop = [entry].concat(popups)
            if (nextPop.length > 4) nextPop = nextPop.slice(0, 4)
            popups = nextPop
        }

        n.closed.connect(function() {
            delete root._handles[id]
            root.hidePopup(id)
        })
    }

    function invokeAction(uid, actionIdx) {
        var h = _handles[uid]
        if (h && h.actions) {
            var rawActs = h.actions.values ? h.actions.values : h.actions
            if (rawActs[actionIdx] && rawActs[actionIdx].invoke) {
                rawActs[actionIdx].invoke()
            }
        }
        hidePopup(uid)
    }

    function hidePopup(uid) {
        popups = popups.filter(function(item) { return item.uid !== uid })
    }

    function dismissItem(uid) {
        hidePopup(uid)
        history = history.filter(function(item) { return item.uid !== uid })
        var h = _handles[uid]
        if (h) {
            delete _handles[uid]
            h.dismiss()
        }
    }

    function clearAll() {
        popups = []
        history = []
        var keys = Object.keys(_handles)
        for (var i = 0; i < keys.length; i++) {
            var h = _handles[keys[i]]
            if (h) h.dismiss()
        }
        _handles = ({})
    }

    property Timer reapTimer: Timer {
        interval: 800
        repeat: true
        running: root.popups.length > 0
        onTriggered: {
            var now = Date.now()
            root.popups = root.popups.filter(function(item) {
                return (now - item.createdAt) < item.timeoutMs
            })
        }
    }
}
