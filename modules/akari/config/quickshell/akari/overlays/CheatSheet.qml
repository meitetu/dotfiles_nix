import QtQuick
import Quickshell
import Quickshell.Wayland
import "../services"

PanelWindow {
    id: sheetWin
    required property var modelData

    screen: modelData
    readonly property bool isTargetScreen: {
        if (ShellState.activeScreenName !== "") {
            return ShellState.activeScreenName === modelData.name
        }
        if (Compositor.focusedOutputName !== "") {
            return Compositor.focusedOutputName === modelData.name
        }
        return Quickshell.screens.length > 0 && Quickshell.screens[0].name === modelData.name
    }

    readonly property bool shouldOpen: ShellState.cheatsheetOpen && isTargetScreen

    visible: shouldOpen
    color: "transparent"

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }
    exclusionMode: ExclusionMode.Ignore

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "akari-cheatsheet"
    WlrLayershell.keyboardFocus: shouldOpen ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    MouseArea {
        anchors.fill: parent
        enabled: sheetWin.shouldOpen
        onClicked: ShellState.cheatsheetOpen = false
    }

    Item {
        anchors.fill: parent
        focus: sheetWin.shouldOpen
        Keys.onEscapePressed: ShellState.cheatsheetOpen = false

        Rectangle {
            anchors.centerIn: parent
            width: Math.min(736, parent.width - 48)
            height: Math.min(520, parent.height - 64)
            radius: Theme.shapeMd
            color: Theme.m3SurfaceContainerLow
            border.width: 1
            border.color: Theme.m3OutlineVariant

            MouseArea { anchors.fill: parent }

            Column {
                anchors.fill: parent
                anchors.margins: Theme.space20
                spacing: Theme.space12

                Item {
                    width: parent.width
                    height: 24

                    Text {
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        text: "キーバインド一覧"
                        font.family: Theme.fontUi
                        font.pixelSize: Theme.typeTitleMedium
                        font.weight: Font.Medium
                        color: Theme.m3OnSurface
                    }

                    KeyBadge {
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        label: "Esc"

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: ShellState.cheatsheetOpen = false
                        }
                    }
                }

                Rectangle { width: parent.width; height: 1; color: Theme.m3OutlineVariant }

                Flickable {
                    width: parent.width
                    height: parent.height - 48
                    contentWidth: width
                    contentHeight: bindGrid.implicitHeight
                    clip: true

                    Grid {
                        id: bindGrid
                        width: parent.width
                        columns: 2
                        spacing: Theme.space8
                        readonly property real cellWidth: (width - spacing) / 2

                        Repeater {
                            model: [
                                { k: "Super + Return",       d: "Kitty ターミナル" },
                                { k: "Super + R / Space",    d: "アプリランチャー" },
                                { k: "Super + E",            d: "Dolphin ファイル" },
                                { k: "Super + B",            d: "Floorp ブラウザ" },
                                { k: "Super + V",            d: "クリップボード履歴" },
                                { k: "Super + . / /",        d: "絵文字・顔文字" },
                                { k: "Super + Y",            d: "壁紙切替" },
                                { k: "Super + N / A",        d: "クイック設定パネル" },
                                { k: "Super + Shift + M",    d: "システムモニター" },
                                { k: "Super + Q",            d: "ウィンドウを閉じる" },
                                { k: "Super + F / T",        d: "最大化 / フロート切替" },
                                { k: "Super + J / P",        d: "分割方向 / 疑似タイル" },
                                { k: "Super + W / Tab",      d: "タブグループ / 切替" },
                                { k: "Super + Arrows",       d: "フォーカス移動" },
                                { k: "Super + Alt + Arrows", d: "ウィンドウ移動" },
                                { k: "Super + - / =",        d: "幅リサイズ" },
                                { k: "Super + 1..0 / U / I", d: "ワークスペース切替" },
                                { k: "Super + S / Shift+↓",  d: "Scratchpad 表示 / 退避" },
                                { k: "Print / Super+Shift+S",d: "スクリーンショット" },
                                { k: "Super + L",            d: "ロック画面" },
                                { k: "Super + X / Esc",      d: "電源メニュー" }
                            ]
                            delegate: Rectangle {
                                required property var modelData
                                width: bindGrid.cellWidth
                                height: 36
                                radius: Theme.shapeSm
                                color: Theme.m3SurfaceContainer

                                Row {
                                    anchors.fill: parent
                                    anchors.leftMargin: Theme.space12
                                    anchors.rightMargin: Theme.space12
                                    spacing: Theme.space12

                                    Text {
                                        width: 156
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: modelData.k
                                        font.family: Theme.fontMono
                                        font.pixelSize: Theme.typeLabelMedium
                                        font.weight: Font.Medium
                                        color: Theme.m3Primary
                                    }

                                    Text {
                                        width: parent.width - 168
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: modelData.d
                                        elide: Text.ElideRight
                                        font.family: Theme.fontUi
                                        font.pixelSize: Theme.typeBodySmall
                                        color: Theme.m3OnSurfaceVariant
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
