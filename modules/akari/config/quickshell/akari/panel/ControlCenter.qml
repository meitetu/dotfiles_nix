import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import "../services"

PanelWindow {
    id: panelWin
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

    readonly property bool shouldOpen: ShellState.panelOpen && isTargetScreen

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
    WlrLayershell.namespace: "akari-panel"
    WlrLayershell.keyboardFocus: shouldOpen ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

    readonly property string userName: Quickshell.env("USER") || "meitetu"
    readonly property string userInitial: userName.length > 0 ? userName.slice(0, 1).toUpperCase() : "M"

    MouseArea {
        anchors.fill: parent
        enabled: panelWin.shouldOpen
        onClicked: ShellState.panelOpen = false
    }

    // ========================================================================
    // M3 QuickSettings Floating Panel (384w, surface-container-low, 12dp radius)
    // ========================================================================
    Item {
        anchors.fill: parent
        focus: panelWin.shouldOpen
        Keys.onEscapePressed: ShellState.panelOpen = false

        Rectangle {
            id: qsPanel
            anchors {
                top: parent.top
                right: parent.right
                topMargin: Theme.barHeight + Theme.barMarginTop + Theme.space8
                rightMargin: Theme.barMarginSide
            }
            width: 384
            height: Math.min(parent.height - Theme.barHeight - 24, mainCol.implicitHeight + Theme.space16 * 2)
            radius: Theme.shapeMd
            color: Theme.m3SurfaceContainerLow
            border.width: 1
            border.color: Theme.m3OutlineVariant

            MouseArea { anchors.fill: parent }

            Flickable {
                id: bodyFlick
                anchors.fill: parent
                anchors.margins: Theme.space16
                contentWidth: width
                contentHeight: mainCol.implicitHeight
                clip: true
                boundsBehavior: Flickable.StopAtBounds

                Column {
                    id: mainCol
                    width: bodyFlick.width
                    spacing: Theme.space16

                    // ========================================================
                    // 1. UserHeader (Monogram M + user/uptime + Lock + Power)
                    // ========================================================
                    Item {
                        width: parent.width
                        height: 36

                        Row {
                            anchors.left: parent.left
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: Theme.space12

                            Rectangle {
                                width: 36
                                height: 36
                                radius: Theme.shapeSm
                                color: Theme.m3PrimaryContainer

                                Text {
                                    anchors.centerIn: parent
                                    text: panelWin.userInitial
                                    font.family: Theme.fontMono
                                    font.pixelSize: Theme.typeLabelLarge
                                    font.weight: Font.Medium
                                    color: Theme.m3OnPrimaryContainer
                                }
                            }

                            Column {
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 0

                                Text {
                                    text: panelWin.userName
                                    font.family: Theme.fontUi
                                    font.pixelSize: Theme.typeTitleSmall
                                    font.weight: Font.Medium
                                    color: Theme.m3OnSurface
                                }

                                Text {
                                    text: SysStatsService.uptimeText !== ""
                                        ? ("稼働 " + SysStatsService.uptimeText)
                                        : ("CPU " + SysStatsService.cpuPercent + "% · MEM " + SysStatsService.memText)
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

                            // LockAction (36x36, surface-container-high, 8dp radius)
                            Rectangle {
                                width: 36
                                height: 36
                                radius: Theme.shapeSm
                                color: lockMouse.containsMouse ? Theme.m3SurfaceContainerHighest : Theme.m3SurfaceContainerHigh

                                MaterialIcon {
                                    anchors.centerIn: parent
                                    name: "lock"
                                    iconSize: 18
                                    iconColor: Theme.m3OnSurfaceVariant
                                }

                                MouseArea {
                                    id: lockMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        ShellState.panelOpen = false
                                        LockService.activate()
                                    }
                                }
                            }

                            // PowerAction (36x36, error-container, 8dp radius)
                            Rectangle {
                                width: 36
                                height: 36
                                radius: Theme.shapeSm
                                color: Theme.m3ErrorContainer

                                MaterialIcon {
                                    anchors.centerIn: parent
                                    name: "power_settings_new"
                                    iconSize: 18
                                    iconColor: Theme.m3OnErrorContainer
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: ShellState.togglePower()
                                }
                            }
                        }
                    }

                    // ========================================================
                    // 2. QuickToggles (Asymmetric ConnectivityRow + ModeStrip)
                    // ========================================================
                    Column {
                        width: parent.width
                        spacing: Theme.space8

                        // ConnectivityRow: full-width network tile
                        Row {
                            width: parent.width
                            spacing: Theme.space8

                            Rectangle {
                                width: parent.width
                                height: 56
                                radius: Theme.shapeMd
                                color: ConnectivityService.netConnected ? Theme.m3Primary : Theme.m3SurfaceContainerHigh

                                Row {
                                    anchors {
                                        left: parent.left
                                        right: parent.right
                                        verticalCenter: parent.verticalCenter
                                        leftMargin: Theme.space16
                                        rightMargin: Theme.space12
                                    }
                                    spacing: Theme.space12

                                    MaterialIcon {
                                        anchors.verticalCenter: parent.verticalCenter
                                        name: !ConnectivityService.netConnected ? "wifi_off"
                                            : (ConnectivityService.netKind === "ethernet" ? "lan" : "wifi")
                                        iconSize: 20
                                        iconColor: ConnectivityService.netConnected ? Theme.m3OnPrimary : Theme.m3OnSurfaceVariant
                                    }

                                    Column {
                                        width: parent.width - 32
                                        anchors.verticalCenter: parent.verticalCenter
                                        spacing: 0

                                        Text {
                                            width: parent.width
                                            text: ConnectivityService.netTitle
                                            elide: Text.ElideRight
                                            font.family: Theme.fontUi
                                            font.pixelSize: Theme.typeTitleSmall
                                            font.weight: Font.Medium
                                            color: ConnectivityService.netConnected ? Theme.m3OnPrimary : Theme.m3OnSurface
                                        }

                                        Text {
                                            width: parent.width
                                            text: ConnectivityService.netSubtitle
                                            elide: Text.ElideRight
                                            font.family: Theme.fontUi
                                            font.pixelSize: Theme.typeBodySmall
                                            color: ConnectivityService.netConnected ? Theme.m3OnPrimary : Theme.m3OnSurfaceVariant
                                        }
                                    }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        ShellState.panelOpen = false
                                        ConnectivityService.openNetworkSettings()
                                    }
                                }
                            }
                        }

                        // ModeStrip (3 equal M3 mode chips: ダーク / 通知オフ / 日本語 あ)
                        Row {
                            width: parent.width
                            spacing: Theme.space8
                            readonly property real chipW: (width - Theme.space8 * 2) / 3

                            // Dark / Light Mode Toggle
                            Rectangle {
                                width: parent.chipW
                                height: 36
                                radius: Theme.shapeSm
                                color: Theme.darkMode ? Theme.m3PrimaryContainer : Theme.m3SurfaceContainerHigh

                                Row {
                                    anchors.centerIn: parent
                                    spacing: Theme.space8

                                    MaterialIcon {
                                        anchors.verticalCenter: parent.verticalCenter
                                        name: Theme.darkMode ? "dark_mode" : "light_mode"
                                        iconSize: 16
                                        iconColor: Theme.darkMode ? Theme.m3OnPrimaryContainer : Theme.m3OnSurfaceVariant
                                    }

                                    Text {
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: Theme.darkMode ? "ダーク" : "ライト"
                                        font.family: Theme.fontUi
                                        font.pixelSize: Theme.typeLabelMedium
                                        font.weight: Font.Medium
                                        color: Theme.darkMode ? Theme.m3OnPrimaryContainer : Theme.m3OnSurface
                                    }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: Theme.toggleDarkMode()
                                }
                            }

                            // DND Toggle
                            Rectangle {
                                width: parent.chipW
                                height: 36
                                radius: Theme.shapeSm
                                color: NotifService.dnd ? Theme.m3PrimaryContainer : Theme.m3SurfaceContainerHigh

                                Row {
                                    anchors.centerIn: parent
                                    spacing: Theme.space8

                                    MaterialIcon {
                                        anchors.verticalCenter: parent.verticalCenter
                                        name: NotifService.dnd ? "notifications_off" : "notifications"
                                        iconSize: 16
                                        iconColor: NotifService.dnd ? Theme.m3OnPrimaryContainer : Theme.m3OnSurfaceVariant
                                    }

                                    Text {
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: "通知オフ"
                                        font.family: Theme.fontUi
                                        font.pixelSize: Theme.typeLabelMedium
                                        font.weight: Font.Medium
                                        color: NotifService.dnd ? Theme.m3OnPrimaryContainer : Theme.m3OnSurface
                                    }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: NotifService.toggleDnd()
                                }
                            }

                            // IME Toggle
                            Rectangle {
                                width: parent.chipW
                                height: 36
                                radius: Theme.shapeSm
                                color: ImeService.isJapanese ? Theme.m3SecondaryContainer : Theme.m3SurfaceContainerHigh

                                Text {
                                    anchors.centerIn: parent
                                    text: ImeService.isJapanese ? ("日本語 " + ImeService.labelText) : "直接入力 A"
                                    font.family: Theme.fontUi
                                    font.pixelSize: Theme.typeLabelMedium
                                    font.weight: Font.Medium
                                    color: ImeService.isJapanese ? Theme.m3OnSecondaryContainer : Theme.m3OnSurface
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: ImeService.toggle()
                                }
                            }
                        }
                    }

                    // ========================================================
                    // 3. M3 Handle-Gap Sliders (16dp thick track + 4x28 handle)
                    // ========================================================
                    Column {
                        width: parent.width
                        spacing: Theme.space12

                        // VolumeSlider
                        Row {
                            width: parent.width
                            height: 32
                            spacing: Theme.space12

                            MaterialIcon {
                                anchors.verticalCenter: parent.verticalCenter
                                name: AudioService.iconName
                                iconSize: 20
                                iconColor: Theme.m3OnSurfaceVariant

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: AudioService.toggleMute()
                                }
                            }

                            Item {
                                id: volTrackArea
                                width: parent.width - 20 - 36 - Theme.space12 * 2
                                height: 28
                                anchors.verticalCenter: parent.verticalCenter

                                readonly property real ratio: AudioService.muted ? 0.0 : Math.max(0.0, Math.min(1.0, AudioService.volume / 100.0))
                                readonly property real usableW: Math.max(12, width - 12)
                                readonly property real activeW: Math.round(usableW * ratio)
                                readonly property real inactiveW: Math.max(0, usableW - activeW)

                                Rectangle {
                                    visible: volTrackArea.activeW > 0
                                    x: 0
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: volTrackArea.activeW
                                    height: 16
                                    topLeftRadius: Theme.shapeSm
                                    bottomLeftRadius: Theme.shapeSm
                                    topRightRadius: Theme.shapeXs
                                    bottomRightRadius: Theme.shapeXs
                                    color: Theme.m3Primary
                                }

                                Rectangle {
                                    x: volTrackArea.activeW > 0 ? (volTrackArea.activeW + 4) : 0
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: 4
                                    height: 28
                                    radius: Theme.shapeXs
                                    color: Theme.m3Primary
                                }

                                Rectangle {
                                    visible: volTrackArea.inactiveW > 0
                                    x: (volTrackArea.activeW > 0 ? (volTrackArea.activeW + 4) : 0) + 8
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: parent.width - x
                                    height: 16
                                    topLeftRadius: Theme.shapeXs
                                    bottomLeftRadius: Theme.shapeXs
                                    topRightRadius: Theme.shapeSm
                                    bottomRightRadius: Theme.shapeSm
                                    color: Theme.m3SurfaceContainerHighest
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onPressed: mouse => AudioService.setVolume((mouse.x / volTrackArea.width) * 100)
                                    onPositionChanged: mouse => { if (pressed) AudioService.setVolume((mouse.x / volTrackArea.width) * 100) }
                                }
                            }

                            Text {
                                width: 36
                                horizontalAlignment: Text.AlignRight
                                anchors.verticalCenter: parent.verticalCenter
                                text: AudioService.muted ? "0%" : (AudioService.volume + "%")
                                font.family: Theme.fontMono
                                font.pixelSize: Theme.typeLabelMedium
                                font.weight: Font.Medium
                                color: Theme.m3OnSurface
                            }
                        }

                        // MicSlider
                        Row {
                            width: parent.width
                            height: 32
                            spacing: Theme.space12

                            MaterialIcon {
                                anchors.verticalCenter: parent.verticalCenter
                                name: AudioService.micIconName
                                iconSize: 20
                                iconColor: AudioService.micMuted ? Theme.m3Outline : Theme.m3OnSurfaceVariant

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: AudioService.toggleMicMute()
                                }
                            }

                            Item {
                                id: micTrackArea
                                width: parent.width - 20 - 36 - Theme.space12 * 2
                                height: 28
                                anchors.verticalCenter: parent.verticalCenter

                                readonly property real ratio: AudioService.micMuted ? 0.0 : Math.max(0.0, Math.min(1.0, AudioService.micVolume / 100.0))
                                readonly property real usableW: Math.max(12, width - 12)
                                readonly property real activeW: Math.round(usableW * ratio)
                                readonly property real inactiveW: Math.max(0, usableW - activeW)

                                Rectangle {
                                    visible: micTrackArea.activeW > 0
                                    x: 0
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: micTrackArea.activeW
                                    height: 16
                                    topLeftRadius: Theme.shapeSm
                                    bottomLeftRadius: Theme.shapeSm
                                    topRightRadius: Theme.shapeXs
                                    bottomRightRadius: Theme.shapeXs
                                    color: Theme.m3Secondary
                                }

                                Rectangle {
                                    x: micTrackArea.activeW > 0 ? (micTrackArea.activeW + 4) : 0
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: 4
                                    height: 28
                                    radius: Theme.shapeXs
                                    color: Theme.m3Secondary
                                }

                                Rectangle {
                                    visible: micTrackArea.inactiveW > 0
                                    x: (micTrackArea.activeW > 0 ? (micTrackArea.activeW + 4) : 0) + 8
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: parent.width - x
                                    height: 16
                                    topLeftRadius: Theme.shapeXs
                                    bottomLeftRadius: Theme.shapeXs
                                    topRightRadius: Theme.shapeSm
                                    bottomRightRadius: Theme.shapeSm
                                    color: Theme.m3SurfaceContainerHighest
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onPressed: mouse => AudioService.setMicVolume((mouse.x / micTrackArea.width) * 100)
                                    onPositionChanged: mouse => { if (pressed) AudioService.setMicVolume((mouse.x / micTrackArea.width) * 100) }
                                }
                            }

                            Text {
                                width: 36
                                horizontalAlignment: Text.AlignRight
                                anchors.verticalCenter: parent.verticalCenter
                                text: AudioService.micMuted ? "Mute" : (AudioService.micVolume + "%")
                                font.family: Theme.fontMono
                                font.pixelSize: Theme.typeLabelMedium
                                font.weight: Font.Medium
                                color: AudioService.micMuted ? Theme.m3Outline : Theme.m3OnSurface
                            }
                        }

                        // BrightnessSlider
                        Row {
                            visible: BrightnessService.available
                            width: parent.width
                            height: 32
                            spacing: Theme.space12

                            MaterialIcon {
                                anchors.verticalCenter: parent.verticalCenter
                                name: "brightness_medium"
                                iconSize: 20
                                iconColor: Theme.m3OnSurfaceVariant
                            }

                            Item {
                                id: brTrackArea
                                width: parent.width - 20 - 36 - Theme.space12 * 2
                                height: 28
                                anchors.verticalCenter: parent.verticalCenter

                                readonly property real ratio: Math.max(0.0, Math.min(1.0, BrightnessService.level / 100.0))
                                readonly property real usableW: Math.max(12, width - 12)
                                readonly property real activeW: Math.round(usableW * ratio)
                                readonly property real inactiveW: Math.max(0, usableW - activeW)

                                Rectangle {
                                    visible: brTrackArea.activeW > 0
                                    x: 0
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: brTrackArea.activeW
                                    height: 16
                                    topLeftRadius: Theme.shapeSm
                                    bottomLeftRadius: Theme.shapeSm
                                    topRightRadius: Theme.shapeXs
                                    bottomRightRadius: Theme.shapeXs
                                    color: Theme.m3Primary
                                }

                                Rectangle {
                                    x: brTrackArea.activeW > 0 ? (brTrackArea.activeW + 4) : 0
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: 4
                                    height: 28
                                    radius: Theme.shapeXs
                                    color: Theme.m3Primary
                                }

                                Rectangle {
                                    visible: brTrackArea.inactiveW > 0
                                    x: (brTrackArea.activeW > 0 ? (brTrackArea.activeW + 4) : 0) + 8
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: parent.width - x
                                    height: 16
                                    topLeftRadius: Theme.shapeXs
                                    bottomLeftRadius: Theme.shapeXs
                                    topRightRadius: Theme.shapeSm
                                    bottomRightRadius: Theme.shapeSm
                                    color: Theme.m3SurfaceContainerHighest
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onPressed: mouse => BrightnessService.setBrightness((mouse.x / brTrackArea.width) * 100)
                                    onPositionChanged: mouse => { if (pressed) BrightnessService.setBrightness((mouse.x / brTrackArea.width) * 100) }
                                }
                            }

                            Text {
                                width: 36
                                horizontalAlignment: Text.AlignRight
                                anchors.verticalCenter: parent.verticalCenter
                                text: BrightnessService.level + "%"
                                font.family: Theme.fontMono
                                font.pixelSize: Theme.typeLabelMedium
                                font.weight: Font.Medium
                                color: Theme.m3OnSurface
                            }
                        }
                    }

                    // ========================================================
                    // 4. MediaPlayer Card (surface-container, 12dp radius)
                    // ========================================================
                    Rectangle {
                        visible: MprisService.available
                        width: parent.width
                        height: visible ? (mediaCardCol.implicitHeight + Theme.space12 * 2) : 0
                        radius: Theme.shapeMd
                        color: Theme.m3SurfaceContainer

                        Column {
                            id: mediaCardCol
                            anchors {
                                top: parent.top
                                left: parent.left
                                right: parent.right
                                margins: Theme.space12
                            }
                            spacing: Theme.space12

                            Item {
                                width: parent.width
                                height: 48

                                Row {
                                    anchors.left: parent.left
                                    anchors.right: mediaBtnsRow.left
                                    anchors.rightMargin: Theme.space12
                                    anchors.verticalCenter: parent.verticalCenter
                                    spacing: Theme.space12

                                    ClippingRectangle {
                                        width: 48
                                        height: 48
                                        anchors.verticalCenter: parent.verticalCenter
                                        radius: Theme.shapeSm
                                        color: Theme.m3SecondaryContainer

                                        Text {
                                            visible: albumArtImg.status !== Image.Ready
                                            anchors.centerIn: parent
                                            text: MprisService.badgeCode
                                            font.family: Theme.fontMono
                                            font.pixelSize: Theme.typeLabelMedium
                                            font.weight: Font.Medium
                                            color: Theme.m3OnSecondaryContainer
                                        }

                                        Image {
                                            id: albumArtImg
                                            anchors.fill: parent
                                            source: MprisService.artUrl
                                            fillMode: Image.PreserveAspectCrop
                                            asynchronous: true
                                            cache: true
                                            visible: status === Image.Ready
                                        }
                                    }

                                    Column {
                                        width: parent.width - 60
                                        anchors.verticalCenter: parent.verticalCenter
                                        spacing: 0

                                        Text {
                                            width: parent.width
                                            text: MprisService.title
                                            elide: Text.ElideRight
                                            font.family: Theme.fontUi
                                            font.pixelSize: Theme.typeTitleMedium
                                            font.weight: Font.Medium
                                            color: Theme.m3OnSurface
                                        }

                                        Text {
                                            visible: MprisService.artist !== ""
                                            width: parent.width
                                            text: MprisService.artist
                                            elide: Text.ElideRight
                                            font.family: Theme.fontUi
                                            font.pixelSize: Theme.typeBodySmall
                                            color: Theme.m3OnSurfaceVariant
                                        }
                                    }
                                }

                                Row {
                                    id: mediaBtnsRow
                                    anchors.right: parent.right
                                    anchors.verticalCenter: parent.verticalCenter
                                    spacing: Theme.space8

                                    // PlayButton (40x40, primary-container, 8dp radius)
                                    Rectangle {
                                        width: 40
                                        height: 40
                                        radius: Theme.shapeSm
                                        color: Theme.m3PrimaryContainer

                                        MaterialIcon {
                                            anchors.centerIn: parent
                                            name: MprisService.playing ? "pause" : "play_arrow"
                                            iconSize: 20
                                            iconColor: Theme.m3OnPrimaryContainer
                                        }

                                        MouseArea {
                                            anchors.fill: parent
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: MprisService.togglePlaying()
                                        }
                                    }

                                    // NextButton (32x32, surface-container-highest, 8dp radius)
                                    Rectangle {
                                        width: 32
                                        height: 32
                                        anchors.verticalCenter: parent.verticalCenter
                                        radius: Theme.shapeSm
                                        color: Theme.m3SurfaceContainerHighest

                                        MaterialIcon {
                                            anchors.centerIn: parent
                                            name: "skip_next"
                                            iconSize: 16
                                            iconColor: Theme.m3OnSurfaceVariant
                                        }

                                        MouseArea {
                                            anchors.fill: parent
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: MprisService.next()
                                        }
                                    }
                                }
                            }

                            // MediaProgress (01:42 | 4dp split track | 03:56)
                            Row {
                                visible: MprisService.lengthSec > 0
                                width: parent.width
                                spacing: Theme.space8

                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: MprisService.positionText
                                    font.family: Theme.fontMono
                                    font.pixelSize: Theme.typeLabelMedium
                                    font.weight: Font.Medium
                                    color: Theme.m3OnSurfaceVariant
                                }

                                Item {
                                    id: progBar
                                    width: parent.width - 88
                                    height: 4
                                    anchors.verticalCenter: parent.verticalCenter
                                    readonly property real playedW: Math.round((width - 4) * MprisService.progressRatio)

                                    Rectangle {
                                        visible: progBar.playedW > 0
                                        x: 0
                                        width: progBar.playedW
                                        height: 4
                                        radius: Theme.shapeXs
                                        color: Theme.m3Primary
                                    }

                                    Rectangle {
                                        x: progBar.playedW > 0 ? (progBar.playedW + 4) : 0
                                        width: Math.max(0, parent.width - x)
                                        height: 4
                                        radius: Theme.shapeXs
                                        color: Theme.m3SurfaceContainerHighest
                                    }
                                }

                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: MprisService.lengthText
                                    font.family: Theme.fontMono
                                    font.pixelSize: Theme.typeLabelMedium
                                    font.weight: Font.Medium
                                    color: Theme.m3OnSurfaceVariant
                                }
                            }
                        }
                    }

                    // ========================================================
                    // 5. Bottom Cava Visualizer Card (M3 Switch + Mode + Height)
                    // ========================================================
                    Rectangle {
                        width: parent.width
                        height: cavaCardCol.implicitHeight + Theme.space12 * 2
                        radius: Theme.shapeMd
                        color: Theme.m3SurfaceContainer

                        Column {
                            id: cavaCardCol
                            anchors {
                                top: parent.top
                                left: parent.left
                                right: parent.right
                                margins: Theme.space12
                            }
                            spacing: Theme.space12

                            // Header + M3 Switch
                            Item {
                                width: parent.width
                                height: 36

                                Row {
                                    anchors.left: parent.left
                                    anchors.right: cavaSwitchTrack.left
                                    anchors.rightMargin: Theme.space12
                                    anchors.verticalCenter: parent.verticalCenter
                                    spacing: Theme.space12

                                    Rectangle {
                                        width: 36
                                        height: 36
                                        radius: Theme.shapeSm
                                        color: CavaService.enabled ? Theme.m3PrimaryContainer : Theme.m3SurfaceContainerHighest

                                        MaterialIcon {
                                            anchors.centerIn: parent
                                            name: "graphic_eq"
                                            iconSize: 18
                                            iconColor: CavaService.enabled ? Theme.m3OnPrimaryContainer : Theme.m3OnSurfaceVariant
                                        }
                                    }

                                    Column {
                                        width: parent.width - 48
                                        anchors.verticalCenter: parent.verticalCenter
                                        spacing: 0

                                        Text {
                                            width: parent.width
                                            text: "Cava バー"
                                            elide: Text.ElideRight
                                            font.family: Theme.fontUi
                                            font.pixelSize: Theme.typeTitleSmall
                                            font.weight: Font.Medium
                                            color: Theme.m3OnSurface
                                        }

                                        Text {
                                            width: parent.width
                                            text: !CavaService.enabled
                                                ? "画面下部にスペクトラムを表示"
                                                : (CavaService.layerMode === "desktop"
                                                    ? "画面下部 · 壁紙上"
                                                    : (CavaService.layerMode === "reserve"
                                                        ? "画面下部 · 領域確保"
                                                        : "画面下部 · 最前面"))
                                            elide: Text.ElideRight
                                            font.family: Theme.fontUi
                                            font.pixelSize: Theme.typeBodySmall
                                            color: Theme.m3OnSurfaceVariant
                                        }
                                    }
                                }

                                // Material 3 Pill Switch
                                Rectangle {
                                    id: cavaSwitchTrack
                                    anchors.right: parent.right
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: 48
                                    height: 28
                                    radius: 14
                                    color: CavaService.enabled ? Theme.m3Primary : Theme.m3SurfaceContainerHighest
                                    border.width: CavaService.enabled ? 0 : 1
                                    border.color: Theme.m3Outline

                                    Rectangle {
                                        width: CavaService.enabled ? 20 : 16
                                        height: width
                                        radius: width / 2
                                        x: CavaService.enabled ? (parent.width - width - 4) : 6
                                        anchors.verticalCenter: parent.verticalCenter
                                        color: CavaService.enabled ? Theme.m3OnPrimary : Theme.m3Outline
                                    }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: CavaService.toggle()
                                }
                            }

                            // Expanded Controls when Cava Bar is ON
                            Column {
                                visible: CavaService.enabled
                                width: parent.width
                                spacing: Theme.space8

                                // Placement Mode Chips (最前面 / 壁紙上 / 領域確保)
                                Row {
                                    width: parent.width
                                    spacing: Theme.space8
                                    readonly property real chipW: (width - Theme.space8 * 2) / 3

                                    Rectangle {
                                        width: parent.chipW
                                        height: 30
                                        radius: Theme.shapeSm
                                        color: CavaService.layerMode === "overlay" ? Theme.m3SecondaryContainer : Theme.m3SurfaceContainerHigh

                                        Text {
                                            anchors.centerIn: parent
                                            text: "最前面"
                                            font.family: Theme.fontUi
                                            font.pixelSize: Theme.typeLabelMedium
                                            font.weight: Font.Medium
                                            color: CavaService.layerMode === "overlay" ? Theme.m3OnSecondaryContainer : Theme.m3OnSurface
                                        }

                                        MouseArea {
                                            anchors.fill: parent
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: CavaService.setLayerMode("overlay")
                                        }
                                    }

                                    Rectangle {
                                        width: parent.chipW
                                        height: 30
                                        radius: Theme.shapeSm
                                        color: CavaService.layerMode === "desktop" ? Theme.m3SecondaryContainer : Theme.m3SurfaceContainerHigh

                                        Text {
                                            anchors.centerIn: parent
                                            text: "壁紙上"
                                            font.family: Theme.fontUi
                                            font.pixelSize: Theme.typeLabelMedium
                                            font.weight: Font.Medium
                                            color: CavaService.layerMode === "desktop" ? Theme.m3OnSecondaryContainer : Theme.m3OnSurface
                                        }

                                        MouseArea {
                                            anchors.fill: parent
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: CavaService.setLayerMode("desktop")
                                        }
                                    }

                                    Rectangle {
                                        width: parent.chipW
                                        height: 30
                                        radius: Theme.shapeSm
                                        color: CavaService.layerMode === "reserve" ? Theme.m3SecondaryContainer : Theme.m3SurfaceContainerHigh

                                        Text {
                                            anchors.centerIn: parent
                                            text: "領域確保"
                                            font.family: Theme.fontUi
                                            font.pixelSize: Theme.typeLabelMedium
                                            font.weight: Font.Medium
                                            color: CavaService.layerMode === "reserve" ? Theme.m3OnSecondaryContainer : Theme.m3OnSurface
                                        }

                                        MouseArea {
                                            anchors.fill: parent
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: CavaService.setLayerMode("reserve")
                                        }
                                    }
                                }

                                // Auto-hide when silent chip
                                Rectangle {
                                    width: parent.width
                                    height: 30
                                    radius: Theme.shapeSm
                                    color: CavaService.autoHideSilent ? Theme.m3SecondaryContainer : Theme.m3SurfaceContainerHigh

                                    Row {
                                        anchors.left: parent.left
                                        anchors.leftMargin: Theme.space12
                                        anchors.verticalCenter: parent.verticalCenter
                                        spacing: Theme.space8

                                        MaterialIcon {
                                            anchors.verticalCenter: parent.verticalCenter
                                            name: CavaService.autoHideSilent ? "visibility_off" : "visibility"
                                            iconSize: 15
                                            iconColor: CavaService.autoHideSilent ? Theme.m3OnSecondaryContainer : Theme.m3OnSurfaceVariant
                                        }

                                        Text {
                                            anchors.verticalCenter: parent.verticalCenter
                                            text: "無音時は自動で隠す"
                                            font.family: Theme.fontUi
                                            font.pixelSize: Theme.typeLabelMedium
                                            font.weight: Font.Medium
                                            color: CavaService.autoHideSilent ? Theme.m3OnSecondaryContainer : Theme.m3OnSurface
                                        }
                                    }

                                    Text {
                                        anchors.right: parent.right
                                        anchors.rightMargin: Theme.space12
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: CavaService.autoHideSilent ? "ON" : "OFF"
                                        font.family: Theme.fontMono
                                        font.pixelSize: Theme.typeLabelSmall
                                        font.weight: Font.Medium
                                        color: CavaService.autoHideSilent ? Theme.m3OnSecondaryContainer : Theme.m3OnSurfaceVariant
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: CavaService.toggleAutoHideSilent()
                                    }
                                }

                                // Bar Height M3 Handle-Gap Slider (32px .. 160px)
                                Row {
                                    width: parent.width
                                    height: 28
                                    spacing: Theme.space12

                                    MaterialIcon {
                                        anchors.verticalCenter: parent.verticalCenter
                                        name: "equalizer"
                                        iconSize: 18
                                        iconColor: Theme.m3OnSurfaceVariant
                                    }

                                    Item {
                                        id: cavaHeightTrack
                                        width: parent.width - 18 - 40 - Theme.space12 * 2
                                        height: 24
                                        anchors.verticalCenter: parent.verticalCenter

                                        readonly property real ratio: Math.max(0.0, Math.min(1.0, (CavaService.barHeight - 32) / (160 - 32)))
                                        readonly property real usableW: Math.max(12, width - 12)
                                        readonly property real activeW: Math.round(usableW * ratio)
                                        readonly property real inactiveW: Math.max(0, usableW - activeW)

                                        Rectangle {
                                            visible: cavaHeightTrack.activeW > 0
                                            x: 0
                                            anchors.verticalCenter: parent.verticalCenter
                                            width: cavaHeightTrack.activeW
                                            height: 14
                                            topLeftRadius: Theme.shapeSm
                                            bottomLeftRadius: Theme.shapeSm
                                            topRightRadius: Theme.shapeXs
                                            bottomRightRadius: Theme.shapeXs
                                            color: Theme.m3Primary
                                        }

                                        Rectangle {
                                            x: cavaHeightTrack.activeW > 0 ? (cavaHeightTrack.activeW + 4) : 0
                                            anchors.verticalCenter: parent.verticalCenter
                                            width: 4
                                            height: 24
                                            radius: Theme.shapeXs
                                            color: Theme.m3Primary
                                        }

                                        Rectangle {
                                            visible: cavaHeightTrack.inactiveW > 0
                                            x: (cavaHeightTrack.activeW > 0 ? (cavaHeightTrack.activeW + 4) : 0) + 8
                                            anchors.verticalCenter: parent.verticalCenter
                                            width: parent.width - x
                                            height: 14
                                            topLeftRadius: Theme.shapeXs
                                            bottomLeftRadius: Theme.shapeXs
                                            topRightRadius: Theme.shapeSm
                                            bottomRightRadius: Theme.shapeSm
                                            color: Theme.m3SurfaceContainerHighest
                                        }

                                        MouseArea {
                                            anchors.fill: parent
                                            cursorShape: Qt.PointingHandCursor
                                            onPressed: mouse => {
                                                var r = Math.max(0, Math.min(1, mouse.x / cavaHeightTrack.width))
                                                CavaService.setBarHeight(32 + r * (160 - 32))
                                            }
                                            onPositionChanged: mouse => {
                                                if (pressed) {
                                                    var r = Math.max(0, Math.min(1, mouse.x / cavaHeightTrack.width))
                                                    CavaService.setBarHeight(32 + r * (160 - 32))
                                                }
                                            }
                                        }
                                    }

                                    Text {
                                        width: 40
                                        horizontalAlignment: Text.AlignRight
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: CavaService.barHeight + "px"
                                        font.family: Theme.fontMono
                                        font.pixelSize: Theme.typeLabelMedium
                                        font.weight: Font.Medium
                                        color: Theme.m3OnSurface
                                    }
                                }
                            }
                        }
                    }

                    // ========================================================
                    // 6. Unread Notifications History (shown when count > 0)
                    // ========================================================
                    Column {
                        visible: NotifService.count > 0
                        width: parent.width
                        spacing: Theme.space8

                        Item {
                            width: parent.width
                            height: 20

                            Text {
                                anchors.left: parent.left
                                anchors.verticalCenter: parent.verticalCenter
                                text: "未読の通知 (" + NotifService.count + ")"
                                font.family: Theme.fontUi
                                font.pixelSize: Theme.typeLabelMedium
                                font.weight: Font.Medium
                                color: Theme.m3OnSurfaceVariant
                            }

                            Text {
                                anchors.right: parent.right
                                anchors.verticalCenter: parent.verticalCenter
                                text: "すべて消去"
                                font.family: Theme.fontUi
                                font.pixelSize: Theme.typeLabelMedium
                                font.weight: Font.Medium
                                color: Theme.m3Primary

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: NotifService.clearAll()
                                }
                            }
                        }

                        Repeater {
                            model: NotifService.history
                            delegate: Rectangle {
                                required property var modelData
                                width: mainCol.width
                                height: histCol.implicitHeight + 20
                                radius: Theme.shapeSm
                                color: Theme.m3SurfaceContainer
                                border.width: 1
                                border.color: Theme.m3OutlineVariant

                                Column {
                                    id: histCol
                                    anchors {
                                        top: parent.top
                                        left: parent.left
                                        right: parent.right
                                        margins: 10
                                    }
                                    spacing: Theme.space4

                                    Item {
                                        width: parent.width
                                        height: 16

                                        Text {
                                            anchors.left: parent.left
                                            text: modelData.appName + " · " + modelData.timeText
                                            font.family: Theme.fontUi
                                            font.pixelSize: Theme.typeLabelSmall
                                            font.weight: Font.Medium
                                            color: Theme.m3OnSurfaceVariant
                                        }

                                        MaterialIcon {
                                            anchors.right: parent.right
                                            name: "close"
                                            iconSize: 14
                                            iconColor: Theme.m3OnSurfaceVariant

                                            MouseArea {
                                                anchors.fill: parent
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: NotifService.dismissItem(modelData.uid)
                                            }
                                        }
                                    }

                                    Text {
                                        width: parent.width
                                        text: modelData.summary
                                        wrapMode: Text.Wrap
                                        font.family: Theme.fontUi
                                        font.pixelSize: Theme.typeBodyMedium
                                        font.weight: Font.Medium
                                        color: Theme.m3OnSurface
                                    }

                                    Text {
                                        visible: modelData.body !== ""
                                        width: parent.width
                                        text: modelData.body
                                        wrapMode: Text.Wrap
                                        maximumLineCount: 2
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
