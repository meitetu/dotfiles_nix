pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.SystemTray

QtObject {
    id: root

    // Quiet status bar state only — never triggers a screen popup OSD
    property var item: null
    property string iconName: ""
    property string labelText: "A"
    property string description: "直接入力"
    property bool isJapanese: false
    property bool ready: false

    function findItem() {
        var items = SystemTray.items
        if (!items || !items.values) return null
        for (var i = 0; i < items.values.length; i++) {
            var candidate = items.values[i]
            var id = (candidate.id || "").toLowerCase()
            var icon = (candidate.icon || "").toLowerCase()
            if (id.indexOf("fcitx") >= 0 || icon.indexOf("fcitx") >= 0) return candidate
        }
        return null
    }

    function describe(icon) {
        var name = (icon || "").toLowerCase()
        if (name.indexOf("hiragana") >= 0)
            return { label: "あ", text: "ひらがな", jp: true }
        if (name.indexOf("katakana_full") >= 0)
            return { label: "ア", text: "カタカナ", jp: true }
        if (name.indexOf("katakana_half") >= 0)
            return { label: "ｱ", text: "半角カナ", jp: true }
        if (name.indexOf("alpha_full") >= 0)
            return { label: "Ａ", text: "全角英数", jp: true }
        if (name.indexOf("alpha_half") >= 0)
            return { label: "A", text: "半角英数", jp: false }
        if (name.indexOf("direct") >= 0 || name.indexOf("input-keyboard") >= 0 || name.indexOf("keyboard") >= 0)
            return { label: "A", text: "直接入力", jp: false }
        return { label: "", text: "", jp: false }
    }

    function poll() {
        var current = findItem()
        if (current !== item) {
            item = current
            if (current) {
                iconName = current.icon || ""
                var seeded = describe(iconName)
                if (seeded.label !== "") {
                    labelText = seeded.label
                    description = seeded.text
                    isJapanese = seeded.jp
                }
            }
            return
        }
        if (!current) return

        var next = current.icon || ""
        if (next === iconName) return

        iconName = next
        var info = describe(next)
        if (info.label !== "") {
            labelText = info.label
            description = info.text
            isJapanese = info.jp
        }
    }

    function toggle() {
        Quickshell.execDetached(["fcitx5-remote", "-t"])
    }

    function openConfig() {
        Quickshell.execDetached(["fcitx5-configtool"])
    }

    property Timer pollTimer: Timer {
        interval: 250
        repeat: true
        running: true
        onTriggered: root.poll()
    }

    Component.onCompleted: {
        poll()
        ready = true
    }
}
