import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import Quickshell.Services.SystemTray
import "../services"

PanelWindow {
    id: barWindow
    required property var modelData

    screen: modelData

    visible: ShellState.barVisible
    color: "transparent"

    anchors {
        top: true
        left: true
        right: true
    }

    implicitHeight: Theme.barHeight + Theme.barMarginTop
    exclusiveZone: ShellState.barVisible ? (Theme.barHeight + Theme.barMarginTop) : 0

    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.namespace: "akari-bar"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    readonly property bool compactScreen: width < 1500

    property string timeStr: "00:00"
    property string dateStr: "01/01 水"

    function updateClock() {
        var d = new Date()
        var days = ["日", "月", "火", "水", "木", "金", "土"]
        var hh = ("0" + d.getHours()).slice(-2)
        var mm = ("0" + d.getMinutes()).slice(-2)
        var mo = ("0" + (d.getMonth() + 1)).slice(-2)
        var da = ("0" + d.getDate()).slice(-2)
        timeStr = hh + ":" + mm
        dateStr = mo + "/" + da + " " + days[d.getDay()]
    }

    Timer {
        interval: 1000
        repeat: true
        running: true
        triggeredOnStart: true
        onTriggered: barWindow.updateClock()
    }

    function findWorkspace(wsIndex) {
        var list = Compositor.workspaceList
        for (var i = 0; i < list.length; i++) {
            if (list[i].index === wsIndex) return list[i]
        }
        return null
    }

    function iconForClass(cls) {
        var c = (cls || "").toLowerCase()
        if (c.indexOf("kitty") >= 0 || c.indexOf("foot") >= 0 || c.indexOf("alacritty") >= 0 || c.indexOf("wezterm") >= 0)
            return "terminal"
        if (c.indexOf("firefox") >= 0 || c.indexOf("floorp") >= 0 || c.indexOf("chrom") >= 0 || c.indexOf("zen") >= 0)
            return "language"
        if (c.indexOf("dolphin") >= 0 || c.indexOf("thunar") >= 0 || c.indexOf("nautilus") >= 0)
            return "folder"
        if (c.indexOf("code") >= 0 || c.indexOf("antigravity") >= 0 || c.indexOf("nvim") >= 0 || c.indexOf("zed") >= 0)
            return "code"
        if (c.indexOf("obs") >= 0 || c.indexOf("mpv") >= 0 || c.indexOf("vlc") >= 0)
            return "videocam"
        return "web_asset"
    }

    // ========================================================================
    // M3 Floating Rounded Top Bar (40dp height, 12dp radius, 8dp top / 12dp side)
    // ========================================================================
    Rectangle {
        id: barSurface
        anchors {
            top: parent.top
            left: parent.left
            right: parent.right
            topMargin: Theme.barMarginTop
            leftMargin: Theme.barMarginSide
            rightMargin: Theme.barMarginSide
        }
        height: Theme.barHeight
        radius: Theme.barRadius
        color: Theme.m3SurfaceContainerLowest
        border.width: 1
        border.color: Theme.m3OutlineVariant

        // ====================================================================
        // LEFT: LauncherTrigger · Segmented Workspaces · ActiveWindow
        // ====================================================================
        Row {
            id: barLeft
            anchors {
                left: parent.left
                leftMargin: Theme.space8
                verticalCenter: parent.verticalCenter
            }
            spacing: Theme.space8

            // LauncherTrigger (32x28, primary-container, shape/sm 8dp)
            Rectangle {
                width: 32
                height: 28
                anchors.verticalCenter: parent.verticalCenter
                radius: Theme.shapeSm
                color: ShellState.launcherOpen ? Theme.m3Primary : Theme.m3PrimaryContainer

                MaterialIcon {
                    anchors.centerIn: parent
                    name: "search"
                    iconSize: 16
                    iconColor: ShellState.launcherOpen ? Theme.m3OnPrimary : Theme.m3OnPrimaryContainer
                }

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                    cursorShape: Qt.PointingHandCursor
                    onClicked: mouse => {
                        if (mouse.button === Qt.RightButton) ShellState.toggleCheatsheet(barWindow.modelData.name)
                        else ShellState.toggleLauncher(barWindow.modelData.name)
                    }
                }
            }

            // Workspaces Segmented Track (height 32, surface-container, shape/sm 8dp)
            Rectangle {
                height: 32
                width: wsRow.implicitWidth + 8
                anchors.verticalCenter: parent.verticalCenter
                radius: Theme.shapeSm
                color: Theme.m3SurfaceContainer

                MouseArea {
                    anchors.fill: parent
                    acceptedButtons: Qt.NoButton
                    onWheel: wheel => {
                        if (wheel.angleDelta.y > 0) Compositor.focusWorkspaceUp()
                        else if (wheel.angleDelta.y < 0) Compositor.focusWorkspaceDown()
                    }
                }

                Row {
                    id: wsRow
                    anchors.centerIn: parent
                    spacing: Theme.space4

                    Repeater {
                        model: 10
                        delegate: Rectangle {
                            id: wsItem
                            required property int index
                            readonly property int wsNum: index + 1
                            readonly property var wsObj: barWindow.findWorkspace(wsNum)
                            readonly property bool isActive: Compositor.focusedWorkspaceIndex === wsNum
                            readonly property int winCount: wsObj ? wsObj.windowCount : 0
                            readonly property bool isOccupied: winCount > 0
                            readonly property bool shouldShow: wsNum <= 5 || isOccupied || isActive

                            visible: shouldShow
                            width: shouldShow ? (isActive ? 36 : 24) : 0
                            height: 24
                            radius: Theme.shapeXs
                            color: isActive ? Theme.m3Primary
                                 : (isOccupied ? Theme.m3SecondaryContainer
                                 : (wsMouse.containsMouse ? Theme.m3SurfaceContainerHigh : "transparent"))

                            Behavior on width { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }

                            Text {
                                anchors.centerIn: parent
                                text: String(wsItem.wsNum)
                                font.family: Theme.fontMono
                                font.pixelSize: Theme.typeLabelMedium
                                font.weight: Font.Medium
                                color: wsItem.isActive ? Theme.m3OnPrimary
                                     : (wsItem.isOccupied ? Theme.m3OnSecondaryContainer : Theme.m3OnSurfaceVariant)
                            }

                            MouseArea {
                                id: wsMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: Compositor.focusWorkspace(wsItem.wsNum)
                            }
                        }
                    }
                }
            }

            // ActiveWindow (Icon + app class in primary + title in on-surface)
            Row {
                readonly property string activeClass: Compositor.activeAppId
                readonly property string activeTitle: Compositor.activeTitle
                readonly property string shortClass: {
                    if (activeClass === "") return ""
                    var parts = activeClass.split(".")
                    return parts[parts.length - 1].toLowerCase()
                }

                visible: activeTitle !== "" && !barWindow.compactScreen
                anchors.verticalCenter: parent.verticalCenter
                leftPadding: Theme.space8
                rightPadding: Theme.space8
                spacing: Theme.space8

                MaterialIcon {
                    anchors.verticalCenter: parent.verticalCenter
                    name: barWindow.iconForClass(parent.activeClass || parent.activeTitle)
                    iconSize: 16
                    iconColor: Theme.m3OnSurfaceVariant
                }

                Text {
                    visible: parent.shortClass !== ""
                    anchors.verticalCenter: parent.verticalCenter
                    text: parent.shortClass
                    font.family: Theme.fontUi
                    font.pixelSize: Theme.typeLabelMedium
                    font.weight: Font.Medium
                    color: Theme.m3Primary
                }

                Text {
                    width: Math.min(340, implicitWidth)
                    anchors.verticalCenter: parent.verticalCenter
                    text: parent.activeTitle
                    elide: Text.ElideRight
                    font.family: Theme.fontMono
                    font.pixelSize: Theme.typeLabelMedium
                    font.weight: Font.Medium
                    color: Theme.m3OnSurface
                }
            }
        }

        // ====================================================================
        // RIGHT: NowPlayingBar · SystemStatus · Clock
        // ====================================================================
        Row {
            id: barRight
            anchors {
                right: parent.right
                rightMargin: Theme.space8
                verticalCenter: parent.verticalCenter
            }
            spacing: Theme.space8

            // NowPlayingBar (height 28, surface-container, shape/sm 8dp)
            Rectangle {
                visible: MprisService.available && !barWindow.compactScreen
                height: 28
                width: visible ? Math.min(220, mediaRow.implicitWidth + 20) : 0
                anchors.verticalCenter: parent.verticalCenter
                radius: Theme.shapeSm
                color: mediaMouse.containsMouse ? Theme.m3SurfaceContainerHigh : Theme.m3SurfaceContainer
                clip: true

                Row {
                    id: mediaRow
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.left: parent.left
                    anchors.leftMargin: Theme.space8
                    spacing: Theme.space8

                    MaterialIcon {
                        anchors.verticalCenter: parent.verticalCenter
                        name: MprisService.playing ? "play_arrow" : "pause"
                        iconSize: 16
                        iconColor: MprisService.playing ? Theme.m3Tertiary : Theme.m3OnSurfaceVariant
                    }

                    Text {
                        width: Math.min(176, implicitWidth)
                        anchors.verticalCenter: parent.verticalCenter
                        text: MprisService.title
                        elide: Text.ElideRight
                        font.family: Theme.fontUi
                        font.pixelSize: Theme.typeLabelMedium
                        font.weight: Font.Medium
                        color: Theme.m3OnSurface
                    }
                }

                MouseArea {
                    id: mediaMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
                    cursorShape: Qt.PointingHandCursor
                    onClicked: mouse => {
                        if (mouse.button === Qt.MiddleButton) MprisService.next()
                        else if (mouse.button === Qt.RightButton) ShellState.togglePanel()
                        else MprisService.togglePlaying()
                    }
                }
            }

            // SystemStatus Unified Capsule (height 28, surface-container, shape/sm 8dp)
            Rectangle {
                height: 28
                width: statusRow.implicitWidth + 16
                anchors.verticalCenter: parent.verticalCenter
                radius: Theme.shapeSm
                color: Theme.m3SurfaceContainer

                Row {
                    id: statusRow
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.left: parent.left
                    anchors.leftMargin: Theme.space4
                    spacing: Theme.space12

                    // InputMethod Badge (24x20, secondary-container when JP, shape/xs 4dp)
                    Rectangle {
                        width: 24
                        height: 20
                        anchors.verticalCenter: parent.verticalCenter
                        radius: Theme.shapeXs
                        color: ImeService.isJapanese ? Theme.m3SecondaryContainer : Theme.m3SurfaceContainerHigh

                        Text {
                            anchors.centerIn: parent
                            text: ImeService.labelText !== "" ? ImeService.labelText : "A"
                            font.family: Theme.fontUi
                            font.pixelSize: Theme.typeLabelSmall
                            font.weight: Font.Medium
                            color: ImeService.isJapanese ? Theme.m3OnSecondaryContainer : Theme.m3OnSurfaceVariant
                        }

                        MouseArea {
                            anchors.fill: parent
                            acceptedButtons: Qt.LeftButton | Qt.RightButton
                            cursorShape: Qt.PointingHandCursor
                            onClicked: mouse => {
                                if (mouse.button === Qt.RightButton) ImeService.openConfig()
                                else ImeService.toggle()
                            }
                        }
                    }

                    // Connectivity + SystemTray Icons
                    Row {
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: Theme.space8

                        MaterialIcon {
                            anchors.verticalCenter: parent.verticalCenter
                            name: !ConnectivityService.netConnected ? "wifi_off"
                                : (ConnectivityService.netKind === "ethernet" ? "lan" : "wifi")
                            iconSize: 16
                            iconColor: ConnectivityService.netConnected ? Theme.m3OnSurfaceVariant : Theme.m3Outline

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: ShellState.togglePanel(barWindow.modelData.name)
                            }
                        }

                        // SystemTray: collapsible group
                        Row {
                            id: trayGroup
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: Theme.space8

                            readonly property var trayItems: {
                                var out = []
                                var items = SystemTray.items.values
                                for (var i = 0; i < items.length; i++) {
                                    var it = items[i]
                                    var idStr = (it.id || "").toLowerCase()
                                    var icStr = (it.icon || "").toLowerCase()
                                    if (idStr.indexOf("fcitx") >= 0 || icStr.indexOf("fcitx") >= 0) continue
                                    out.push(it)
                                }
                                return out
                            }

                            readonly property bool hasItems: trayItems.length > 0

                            // Toggle chevron
                            Item {
                                visible: trayGroup.hasItems
                                width: visible ? 16 : 0
                                height: 16
                                anchors.verticalCenter: parent.verticalCenter

                                MaterialIcon {
                                    anchors.centerIn: parent
                                    name: ShellState.trayExpanded ? "chevron_right" : "chevron_left"
                                    iconSize: 16
                                    iconColor: trayMouse.containsMouse ? Theme.m3Primary : Theme.m3OnSurfaceVariant
                                }

                                MouseArea {
                                    id: trayMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: ShellState.toggleTray()
                                }
                            }

                            // Tray icons (collapsed shows first 3)
                            Repeater {
                                model: {
                                    var items = trayGroup.trayItems
                                    var shown = ShellState.trayExpanded ? items.length : Math.min(3, items.length)
                                    var out = []
                                    for (var i = 0; i < shown; i++) out.push(i)
                                    return out
                                }
                                delegate: Item {
                                    required property int index
                                    width: 16
                                    height: 16
                                    anchors.verticalCenter: parent.verticalCenter

                                    IconImage {
                                        anchors.centerIn: parent
                                        width: 15
                                        height: 15
                                        backer.cache: false
                                        source: {
                                            var it = trayGroup.trayItems[index]
                                            if (!it) return ""
                                            var ic = it.icon || ""
                                            if (ic === "") return ""
                                            if (ic.startsWith("file://") || ic.startsWith("image://")) return ic
                                            if (ic.startsWith("/")) return "file://" + ic
                                            return "image://icon/" + ic
                                        }
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        acceptedButtons: Qt.LeftButton | Qt.RightButton
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: mouse => {
                                            var item = trayGroup.trayItems[index]
                                            if (!item) return
                                            if (mouse.button === Qt.RightButton || item.onlyMenu) {
                                                if (item.hasMenu) {
                                                    var pt = mapToItem(null, 0, barWindow.height + 4)
                                                    item.display(barWindow, pt.x, pt.y)
                                                } else {
                                                    item.secondaryActivate()
                                                }
                                            } else {
                                                item.activate()
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // Battery (if laptop/UPS battery exists)
                    Row {
                        visible: ConnectivityService.hasBattery
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: Theme.space4

                        MaterialIcon {
                            anchors.verticalCenter: parent.verticalCenter
                            name: "battery_5_bar"
                            iconSize: 16
                            iconColor: Theme.m3Tertiary
                        }

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: ConnectivityService.batteryPercent + "%"
                            font.family: Theme.fontMono
                            font.pixelSize: Theme.typeLabelMedium
                            font.weight: Font.Medium
                            color: Theme.m3OnSurface
                        }
                    }

                    // Notification indicator when unread/DND
                    Item {
                        visible: !ConnectivityService.hasBattery && (NotifService.count > 0 || NotifService.dnd)
                        width: visible ? notifRowInner.implicitWidth : 0
                        height: 20
                        anchors.verticalCenter: parent.verticalCenter

                        Row {
                            id: notifRowInner
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: Theme.space4

                            MaterialIcon {
                                anchors.verticalCenter: parent.verticalCenter
                                name: NotifService.dnd ? "notifications_off" : "notifications"
                                iconSize: 16
                                iconColor: NotifService.dnd ? Theme.m3Outline : Theme.m3Primary
                            }

                            Text {
                                visible: NotifService.count > 0
                                anchors.verticalCenter: parent.verticalCenter
                                text: String(NotifService.count)
                                font.family: Theme.fontMono
                                font.pixelSize: Theme.typeLabelMedium
                                font.weight: Font.Medium
                                color: Theme.m3OnSurface
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: ShellState.togglePanel(barWindow.modelData.name)
                        }
                    }
                }
            }

            // Audio Card (output + mic, independent from the tray capsule)
            Rectangle {
                id: audioCard
                height: 28
                width: audioCardRow.implicitWidth + 20
                anchors.verticalCenter: parent.verticalCenter
                radius: Theme.shapeSm
                color: audioCardMouse.containsMouse ? Theme.m3SurfaceContainerHigh : Theme.m3SurfaceContainer

                MouseArea {
                    id: audioCardMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    acceptedButtons: Qt.RightButton
                    cursorShape: Qt.PointingHandCursor
                    onClicked: AudioService.openMixer()
                }

                Row {
                    id: audioCardRow
                    anchors.centerIn: parent
                    spacing: Theme.space8

                    // Output section
                    Item {
                        width: outInner.implicitWidth
                        height: 20
                        anchors.verticalCenter: parent.verticalCenter

                        Row {
                            id: outInner
                            anchors.centerIn: parent
                            spacing: Theme.space4

                            MaterialIcon {
                                anchors.verticalCenter: parent.verticalCenter
                                name: AudioService.iconName
                                iconSize: 16
                                iconColor: AudioService.muted ? Theme.m3Outline : Theme.m3OnSurfaceVariant
                            }

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: AudioService.muted ? "Mute" : (AudioService.volume + "%")
                                font.family: Theme.fontMono
                                font.pixelSize: Theme.typeLabelMedium
                                font.weight: Font.Medium
                                color: AudioService.muted ? Theme.m3Outline : Theme.m3OnSurface
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            acceptedButtons: Qt.LeftButton
                            cursorShape: Qt.PointingHandCursor
                            onClicked: AudioService.toggleMute()
                            onWheel: wheel => {
                                if (wheel.angleDelta.y > 0) AudioService.stepVolume(5)
                                else if (wheel.angleDelta.y < 0) AudioService.stepVolume(-5)
                            }
                        }
                    }

                    // Separator
                    Rectangle {
                        width: 1
                        height: 14
                        anchors.verticalCenter: parent.verticalCenter
                        color: Theme.m3OutlineVariant
                    }

                    // Mic section
                    Item {
                        width: micInner.implicitWidth
                        height: 20
                        anchors.verticalCenter: parent.verticalCenter

                        Row {
                            id: micInner
                            anchors.centerIn: parent
                            spacing: Theme.space4

                            MaterialIcon {
                                anchors.verticalCenter: parent.verticalCenter
                                name: AudioService.micIconName
                                iconSize: 16
                                iconColor: AudioService.micMuted ? Theme.m3Outline : Theme.m3Secondary
                            }

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: AudioService.micMuted ? "Mute" : (AudioService.micVolume + "%")
                                font.family: Theme.fontMono
                                font.pixelSize: Theme.typeLabelMedium
                                font.weight: Font.Medium
                                color: AudioService.micMuted ? Theme.m3Outline : Theme.m3OnSurface
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            acceptedButtons: Qt.LeftButton
                            cursorShape: Qt.PointingHandCursor
                            onClicked: AudioService.toggleMicMute()
                            onWheel: wheel => {
                                if (wheel.angleDelta.y > 0) AudioService.stepMicVolume(5)
                                else if (wheel.angleDelta.y < 0) AudioService.stepMicVolume(-5)
                            }
                        }
                    }
                }
            }

            // System Stats Card (CPU / MEM / GPU) — click opens the System Monitor
            Rectangle {
                height: 28
                width: statsCardRow.implicitWidth + 20
                anchors.verticalCenter: parent.verticalCenter
                radius: Theme.shapeSm
                color: ShellState.sysmonOpen ? Theme.m3Primary
                     : (statsMouse.containsMouse ? Theme.m3SurfaceContainerHigh : Theme.m3SurfaceContainer)

                MouseArea {
                    id: statsMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: ShellState.toggleSysmon(barWindow.modelData.name)
                }

                Row {
                    id: statsCardRow
                    anchors.centerIn: parent
                    spacing: Theme.space12

                    // CPU
                    Row {
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: Theme.space4

                        MaterialIcon {
                            anchors.verticalCenter: parent.verticalCenter
                            name: "speed"
                            iconSize: 15
                            iconColor: ShellState.sysmonOpen ? Theme.m3OnPrimary : Theme.m3OnSurfaceVariant
                        }

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: SysStatsService.cpuPercent + "%"
                            font.family: Theme.fontMono
                            font.pixelSize: Theme.typeLabelMedium
                            font.weight: Font.Medium
                            color: ShellState.sysmonOpen ? Theme.m3OnPrimary
                                 : (SysStatsService.cpuPercent >= 85 ? Theme.m3Error : Theme.m3OnSurface)
                        }
                    }

                    // MEM
                    Row {
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: Theme.space4

                        MaterialIcon {
                            anchors.verticalCenter: parent.verticalCenter
                            name: "memory"
                            iconSize: 15
                            iconColor: ShellState.sysmonOpen ? Theme.m3OnPrimary : Theme.m3OnSurfaceVariant
                        }

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: SysStatsService.memPercent + "%"
                            font.family: Theme.fontMono
                            font.pixelSize: Theme.typeLabelMedium
                            font.weight: Font.Medium
                            color: ShellState.sysmonOpen ? Theme.m3OnPrimary
                                 : (SysStatsService.memPercent >= 85 ? Theme.m3Error : Theme.m3OnSurface)
                        }
                    }

                    // GPU (only when an amdgpu sysfs interface is present)
                    Row {
                        visible: SysStatsService.gpuAvailable
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: Theme.space4

                        MaterialIcon {
                            anchors.verticalCenter: parent.verticalCenter
                            name: "developer_board"
                            iconSize: 15
                            iconColor: ShellState.sysmonOpen ? Theme.m3OnPrimary : Theme.m3OnSurfaceVariant
                        }

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: SysStatsService.gpuPercent + "%"
                            font.family: Theme.fontMono
                            font.pixelSize: Theme.typeLabelMedium
                            font.weight: Font.Medium
                            color: ShellState.sysmonOpen ? Theme.m3OnPrimary
                                 : (SysStatsService.gpuPercent >= 85 ? Theme.m3Error : Theme.m3OnSurface)
                        }
                    }
                }
            }

            // Clock Capsule (height 28, surface-container-high, shape/sm 8dp — toggles QuickSettings)
            Rectangle {
                height: 28
                width: clockRow.implicitWidth + 24
                anchors.verticalCenter: parent.verticalCenter
                radius: Theme.shapeSm
                color: ShellState.panelOpen ? Theme.m3Primary
                     : (clockMouse.containsMouse ? Theme.m3SurfaceContainerHighest : Theme.m3SurfaceContainerHigh)

                Row {
                    id: clockRow
                    anchors.centerIn: parent
                    spacing: Theme.space8

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: barWindow.dateStr
                        font.family: Theme.fontUi
                        font.pixelSize: Theme.typeLabelMedium
                        font.weight: Font.Medium
                        color: ShellState.panelOpen ? Theme.m3OnPrimary : Theme.m3OnSurfaceVariant
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: barWindow.timeStr
                        font.family: Theme.fontMono
                        font.pixelSize: Theme.typeLabelLarge
                        font.weight: Font.Medium
                        color: ShellState.panelOpen ? Theme.m3OnPrimary : Theme.m3OnSurface
                    }
                }

                MouseArea {
                    id: clockMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: ShellState.togglePanel(barWindow.modelData.name)
                }
            }
        }
    }
}
