import QtQuick
import Quickshell
import Quickshell.Wayland
import "../services"

// ============================================================================
// System Monitor Dashboard — opened from the bar's stats capsule.
// CPU (per-core + history), memory/swap, GPU/VRAM, storage (usage + I/O rate),
// network rates, load average and top processes.
// ============================================================================
PanelWindow {
    id: dashWin
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

    readonly property bool shouldOpen: ShellState.sysmonOpen && isTargetScreen

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
    WlrLayershell.namespace: "akari-sysmon"
    WlrLayershell.keyboardFocus: shouldOpen ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

    readonly property var mon: SysMonitorService
    readonly property int cardGap: Theme.space12

    function close() { ShellState.sysmonOpen = false }

    MouseArea {
        anchors.fill: parent
        enabled: dashWin.shouldOpen
        onClicked: dashWin.close()
    }

    Item {
        anchors.fill: parent
        focus: dashWin.shouldOpen
        Keys.onEscapePressed: dashWin.close()

        Rectangle {
            id: surface
            anchors.centerIn: parent
            width: Math.min(1080, parent.width - 48)
            height: Math.min(760, parent.height - 48)
            radius: Theme.shapeMd
            color: Theme.m3SurfaceContainerLow
            border.width: 1
            border.color: Theme.m3OutlineVariant

            MouseArea { anchors.fill: parent }

            Column {
                anchors.fill: parent
                anchors.margins: Theme.space20
                spacing: Theme.space12

                // ============================================================
                // Header
                // ============================================================
                Item {
                    width: parent.width
                    height: 32

                    Row {
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: Theme.space12

                        Rectangle {
                            width: 32
                            height: 32
                            radius: Theme.shapeSm
                            color: Theme.m3PrimaryContainer

                            MaterialIcon {
                                anchors.centerIn: parent
                                name: "monitoring"
                                iconSize: 18
                                iconColor: Theme.m3OnPrimaryContainer
                            }
                        }

                        Column {
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 0

                            Text {
                                text: "システムモニター"
                                font.family: Theme.fontUi
                                font.pixelSize: Theme.typeTitleMedium
                                font.weight: Font.Medium
                                color: Theme.m3OnSurface
                            }

                            Text {
                                text: dashWin.mon.uptimeText !== ""
                                    ? ("稼働 " + dashWin.mon.uptimeText)
                                    : "計測中…"
                                font.family: Theme.fontUi
                                font.pixelSize: Theme.typeBodySmall
                                color: Theme.m3OnSurfaceVariant
                            }
                        }
                    }

                    Row {
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: Theme.space8

                        Rectangle {
                            height: 24
                            width: loadText.implicitWidth + 20
                            radius: Theme.shapeXs
                            color: Theme.m3SurfaceContainerHigh

                            Text {
                                id: loadText
                                anchors.centerIn: parent
                                text: "LOAD " + dashWin.mon.load1.toFixed(2)
                                    + " · " + dashWin.mon.load5.toFixed(2)
                                    + " · " + dashWin.mon.load15.toFixed(2)
                                font.family: Theme.fontMono
                                font.pixelSize: Theme.typeLabelSmall
                                font.weight: Font.Medium
                                color: Theme.m3OnSurfaceVariant
                            }
                        }

                        KeyBadge {
                            label: "Esc"

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: dashWin.close()
                            }
                        }
                    }
                }

                Rectangle { width: parent.width; height: 1; color: Theme.m3OutlineVariant }

                // ============================================================
                // Card grid
                // ============================================================
                Flickable {
                    id: bodyFlick
                    width: parent.width
                    height: parent.height - 78
                    contentWidth: width
                    contentHeight: cardCol.implicitHeight
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds

                    Column {
                        id: cardCol
                        width: bodyFlick.width
                        spacing: dashWin.cardGap

                        readonly property real cellW: (width - dashWin.cardGap) / 2

                        // ---- Row 1: CPU + Memory ---------------------------
                        Row {
                            width: parent.width
                            spacing: dashWin.cardGap
                            readonly property real rowH: Math.max(cpuCard.implicitHeight, memCard.implicitHeight)
                            height: rowH

                            MetricCard {
                                id: cpuCard
                                width: cardCol.cellW
                                height: parent.rowH
                                title: "CPU"
                                iconName: "speed"
                                trailingText: dashWin.mon.cpuPercent + "%"
                                    + (dashWin.mon.cpuTempC > 0 ? "  ·  " + Math.round(dashWin.mon.cpuTempC) + "°C" : "")

                                Sparkline {
                                    width: parent.width
                                    height: 40
                                    series: dashWin.mon.cpuHistory
                                    maxValue: 100
                                    barColor: Theme.m3Primary
                                }

                                MeterRow {
                                    width: parent.width
                                    label: "総合使用率"
                                    valueText: dashWin.mon.cpuPercent + "%"
                                    ratio: dashWin.mon.cpuPercent / 100
                                    barColor: Theme.m3Primary
                                    warn: dashWin.mon.cpuPercent >= 90
                                }

                                Grid {
                                    width: parent.width
                                    columns: Math.min(8, Math.max(1, dashWin.mon.coreCount))
                                    spacing: Theme.space4

                                    Repeater {
                                        model: dashWin.mon.coreCount

                                        delegate: Column {
                                            id: coreCell
                                            required property int index
                                            readonly property int value: (dashWin.mon.cpuCores[index] !== undefined)
                                                ? dashWin.mon.cpuCores[index] : 0

                                            width: (parent.width - (parent.columns - 1) * parent.spacing) / parent.columns
                                            spacing: 2

                                            Rectangle {
                                                width: parent.width
                                                height: 18
                                                radius: 2
                                                color: Theme.m3SurfaceContainerHighest
                                                opacity: 0.5

                                                Rectangle {
                                                    anchors.bottom: parent.bottom
                                                    width: parent.width
                                                    height: Math.max(2, parent.height * Math.max(0, Math.min(1, coreCell.value / 100)))
                                                    radius: 2
                                                    color: coreCell.value >= 85 ? Theme.m3Error : Theme.m3Secondary
                                                }
                                            }

                                            Text {
                                                width: parent.width
                                                horizontalAlignment: Text.AlignHCenter
                                                text: coreCell.value + "%"
                                                font.family: Theme.fontMono
                                                font.pixelSize: Theme.typeLabelSmall
                                                color: Theme.m3OnSurfaceVariant
                                            }
                                        }
                                    }
                                }
                            }

                            MetricCard {
                                id: memCard
                                width: cardCol.cellW
                                height: parent.rowH
                                title: "メモリ"
                                iconName: "memory"
                                trailingText: dashWin.mon.memUsedText + " / " + dashWin.mon.memTotalText

                                Sparkline {
                                    width: parent.width
                                    height: 32
                                    series: dashWin.mon.memHistory
                                    maxValue: 100
                                    barColor: Theme.m3Tertiary
                                }

                                MeterRow {
                                    width: parent.width
                                    label: "RAM"
                                    valueText: dashWin.mon.memPercent + "%"
                                    ratio: dashWin.mon.memPercent / 100
                                    barColor: Theme.m3Tertiary
                                    warn: dashWin.mon.memPercent >= 90
                                }

                                MeterRow {
                                    width: parent.width
                                    label: "SWAP"
                                    valueText: dashWin.mon.swapTotalText === "0.0G"
                                        ? "なし"
                                        : (dashWin.mon.swapUsedText + " / " + dashWin.mon.swapTotalText)
                                    ratio: dashWin.mon.swapPercent / 100
                                    barColor: Theme.m3Secondary
                                    warn: dashWin.mon.swapPercent >= 60
                                }

                                Item {
                                    width: parent.width
                                    height: 18

                                    Text {
                                        anchors.left: parent.left
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: "空き " + dashWin.mon.memFreeText
                                        font.family: Theme.fontMono
                                        font.pixelSize: Theme.typeLabelMedium
                                        color: Theme.m3OnSurfaceVariant
                                    }

                                    Text {
                                        anchors.right: parent.right
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: "使用中 " + dashWin.mon.memUsedText
                                        font.family: Theme.fontMono
                                        font.pixelSize: Theme.typeLabelMedium
                                        font.weight: Font.Medium
                                        color: Theme.m3OnSurface
                                    }
                                }
                            }
                        }

                        // ---- Row 2: GPU + Storage --------------------------
                        Row {
                            width: parent.width
                            spacing: dashWin.cardGap
                            readonly property real rowH: Math.max(gpuCard.implicitHeight, diskCard.implicitHeight)
                            height: rowH

                            MetricCard {
                                id: gpuCard
                                width: cardCol.cellW
                                height: parent.rowH
                                title: "GPU"
                                iconName: "developer_board"
                                trailingText: dashWin.mon.gpuAvailable
                                    ? (dashWin.mon.gpuPercent + "%"
                                        + (dashWin.mon.gpuTempC > 0 ? "  ·  " + Math.round(dashWin.mon.gpuTempC) + "°C" : "")
                                        + (dashWin.mon.gpuPowerW > 0 ? "  ·  " + dashWin.mon.gpuPowerW.toFixed(0) + "W" : ""))
                                    : "非検出"

                                Sparkline {
                                    width: parent.width
                                    height: 30
                                    visible: dashWin.mon.gpuAvailable
                                    series: dashWin.mon.gpuHistory
                                    maxValue: 100
                                    barColor: Theme.m3Primary
                                }

                                MeterRow {
                                    width: parent.width
                                    label: "使用率"
                                    valueText: dashWin.mon.gpuAvailable ? dashWin.mon.gpuPercent + "%" : "—"
                                    ratio: dashWin.mon.gpuPercent / 100
                                    barColor: Theme.m3Primary
                                    warn: dashWin.mon.gpuPercent >= 90
                                }

                                MeterRow {
                                    width: parent.width
                                    label: "VRAM"
                                    valueText: dashWin.mon.gpuAvailable
                                        ? (dashWin.mon.vramUsedText + " / " + dashWin.mon.vramTotalText)
                                        : "—"
                                    ratio: dashWin.mon.vramPercent / 100
                                    barColor: Theme.m3Secondary
                                    warn: dashWin.mon.vramPercent >= 90
                                }
                            }

                            MetricCard {
                                id: diskCard
                                width: cardCol.cellW
                                height: parent.rowH
                                title: "ストレージ"
                                iconName: "hard_drive"
                                trailingText: "R " + dashWin.mon.fmtRate(dashWin.mon.diskReadRate)
                                    + "  ·  W " + dashWin.mon.fmtRate(dashWin.mon.diskWriteRate)

                                MeterRow {
                                    width: parent.width
                                    label: "ルート (/)"
                                    valueText: dashWin.mon.diskPercent + "% · "
                                        + dashWin.mon.diskUsedText + " / " + dashWin.mon.diskTotalText
                                    ratio: dashWin.mon.diskPercent / 100
                                    barColor: Theme.m3Primary
                                    warn: dashWin.mon.diskPercent >= 90
                                }

                                MeterRow {
                                    width: parent.width
                                    label: "ディスク I/O"
                                    valueText: "↓ " + dashWin.mon.fmtRate(dashWin.mon.diskReadRate)
                                        + "   ↑ " + dashWin.mon.fmtRate(dashWin.mon.diskWriteRate)
                                    ratio: Math.min(1, (dashWin.mon.diskReadRate + dashWin.mon.diskWriteRate) / (100 * 1024 * 1024))
                                    barColor: Theme.m3Secondary
                                }
                            }
                        }

                        // ---- Row 3: Network + Processes --------------------
                        Row {
                            width: parent.width
                            spacing: dashWin.cardGap
                            readonly property real rowH: Math.max(netCard.implicitHeight, procCard.implicitHeight)
                            height: rowH

                            MetricCard {
                                id: netCard
                                width: cardCol.cellW
                                height: parent.rowH
                                title: "ネットワーク"
                                iconName: "lan"
                                trailingText: "↓ " + dashWin.mon.fmtRate(dashWin.mon.netRxRate)
                                    + "  ·  ↑ " + dashWin.mon.fmtRate(dashWin.mon.netTxRate)

                                Sparkline {
                                    width: parent.width
                                    height: 32
                                    series: dashWin.mon.netRxHistory
                                    maxValue: dashWin.mon.netRxPeak
                                    barColor: Theme.m3Tertiary
                                }

                                Row {
                                    width: parent.width
                                    spacing: Theme.space16

                                    Row {
                                        spacing: Theme.space4

                                        MaterialIcon {
                                            anchors.verticalCenter: parent.verticalCenter
                                            name: "download"
                                            iconSize: 14
                                            iconColor: Theme.m3Tertiary
                                        }

                                        Text {
                                            anchors.verticalCenter: parent.verticalCenter
                                            text: "受信 " + dashWin.mon.fmtRate(dashWin.mon.netRxRate)
                                            font.family: Theme.fontMono
                                            font.pixelSize: Theme.typeLabelMedium
                                            font.weight: Font.Medium
                                            color: Theme.m3OnSurface
                                        }
                                    }

                                    Row {
                                        spacing: Theme.space4

                                        MaterialIcon {
                                            anchors.verticalCenter: parent.verticalCenter
                                            name: "upload"
                                            iconSize: 14
                                            iconColor: Theme.m3Secondary
                                        }

                                        Text {
                                            anchors.verticalCenter: parent.verticalCenter
                                            text: "送信 " + dashWin.mon.fmtRate(dashWin.mon.netTxRate)
                                            font.family: Theme.fontMono
                                            font.pixelSize: Theme.typeLabelMedium
                                            font.weight: Font.Medium
                                            color: Theme.m3OnSurface
                                        }
                                    }
                                }
                            }

                            MetricCard {
                                id: procCard
                                width: cardCol.cellW
                                height: parent.rowH
                                title: "プロセス (CPU順)"
                                iconName: "format_list_numbered"
                                trailingText: dashWin.mon.processes.length + " 件"

                                Column {
                                    width: parent.width
                                    spacing: Theme.space4

                                    Repeater {
                                        model: dashWin.mon.processes

                                        delegate: Item {
                                            required property var modelData
                                            required property int index

                                            width: parent.width
                                            height: 16

                                            Text {
                                                width: 18
                                                anchors.left: parent.left
                                                anchors.verticalCenter: parent.verticalCenter
                                                text: String(index + 1)
                                                font.family: Theme.fontMono
                                                font.pixelSize: Theme.typeLabelSmall
                                                color: Theme.m3Outline
                                            }

                                            Text {
                                                anchors.left: parent.left
                                                anchors.leftMargin: 22
                                                anchors.right: parent.right
                                                anchors.rightMargin: 112
                                                anchors.verticalCenter: parent.verticalCenter
                                                text: modelData.name
                                                elide: Text.ElideRight
                                                font.family: Theme.fontUi
                                                font.pixelSize: Theme.typeBodySmall
                                                color: Theme.m3OnSurface
                                            }

                                            Text {
                                                width: 56
                                                anchors.right: parent.right
                                                anchors.rightMargin: 56
                                                anchors.verticalCenter: parent.verticalCenter
                                                horizontalAlignment: Text.AlignRight
                                                text: "PID " + modelData.pid
                                                font.family: Theme.fontMono
                                                font.pixelSize: Theme.typeLabelSmall
                                                color: Theme.m3OnSurfaceVariant
                                            }

                                            Text {
                                                width: 48
                                                anchors.right: parent.right
                                                anchors.verticalCenter: parent.verticalCenter
                                                horizontalAlignment: Text.AlignRight
                                                text: modelData.cpu.toFixed(1) + "%"
                                                font.family: Theme.fontMono
                                                font.pixelSize: Theme.typeLabelMedium
                                                font.weight: Font.Medium
                                                color: modelData.cpu >= 50 ? Theme.m3Error : Theme.m3OnSurface
                                            }
                                        }
                                    }

                                    Text {
                                        visible: dashWin.mon.processes.length === 0
                                        width: parent.width
                                        text: "計測中…"
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
