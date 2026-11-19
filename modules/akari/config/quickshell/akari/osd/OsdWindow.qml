import QtQuick
import Quickshell
import Quickshell.Wayland
import "../services"

PanelWindow {
    id: osdWin
    required property var modelData

    screen: modelData
    readonly property bool isTargetScreen: {
        if (Compositor.focusedOutputName !== "") {
            return Compositor.focusedOutputName === modelData.name
        }
        return Quickshell.screens.length > 0 && Quickshell.screens[0].name === modelData.name
    }

    readonly property bool shouldShow: ShellState.osdVisible && ShellState.osdMode !== "ime" && isTargetScreen

    visible: shouldShow
    color: "transparent"

    anchors {
        bottom: true
    }

    implicitWidth: 288
    implicitHeight: 96
    exclusionMode: ExclusionMode.Ignore
    exclusiveZone: 0
    mask: Region {}

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "akari-osd"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    readonly property int levelValue: {
        if (ShellState.osdMode === "brightness") return BrightnessService.level
        if (ShellState.osdMode === "mic") return AudioService.micMuted ? 0 : AudioService.micVolume
        return AudioService.muted ? 0 : AudioService.volume
    }

    Rectangle {
        width: 272
        height: 48
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.topMargin: Theme.space8
        radius: Theme.shapeMd
        color: Theme.m3SurfaceContainerHigh
        border.width: 1
        border.color: Theme.m3OutlineVariant

        Row {
            anchors.fill: parent
            anchors.leftMargin: Theme.space16
            anchors.rightMargin: Theme.space16
            spacing: Theme.space12

            MaterialIcon {
                anchors.verticalCenter: parent.verticalCenter
                name: {
                    if (ShellState.osdMode === "brightness") return "brightness_medium"
                    if (ShellState.osdMode === "mic") return AudioService.micIconName
                    return AudioService.iconName
                }
                iconSize: 20
                iconColor: Theme.m3Primary
            }

            Item {
                id: osdTrack
                width: parent.width - 20 - 40 - Theme.space12 * 2
                height: 24
                anchors.verticalCenter: parent.verticalCenter

                readonly property real ratio: Math.max(0.0, Math.min(1.0, osdWin.levelValue / 100.0))
                readonly property real usableW: Math.max(8, width - 12)
                readonly property real activeW: Math.round(usableW * ratio)

                Rectangle {
                    visible: osdTrack.activeW > 0
                    x: 0
                    anchors.verticalCenter: parent.verticalCenter
                    width: osdTrack.activeW
                    height: 12
                    topLeftRadius: Theme.shapeSm
                    bottomLeftRadius: Theme.shapeSm
                    topRightRadius: Theme.shapeXs
                    bottomRightRadius: Theme.shapeXs
                    color: Theme.m3Primary
                }

                Rectangle {
                    x: osdTrack.activeW > 0 ? (osdTrack.activeW + 4) : 0
                    anchors.verticalCenter: parent.verticalCenter
                    width: 4
                    height: 24
                    radius: Theme.shapeXs
                    color: Theme.m3Primary
                }

                Rectangle {
                    x: (osdTrack.activeW > 0 ? (osdTrack.activeW + 4) : 0) + 8
                    anchors.verticalCenter: parent.verticalCenter
                    width: Math.max(0, parent.width - x)
                    height: 12
                    topLeftRadius: Theme.shapeXs
                    bottomLeftRadius: Theme.shapeXs
                    topRightRadius: Theme.shapeSm
                    bottomRightRadius: Theme.shapeSm
                    color: Theme.m3SurfaceContainerHighest
                }
            }

            Text {
                width: 40
                horizontalAlignment: Text.AlignRight
                anchors.verticalCenter: parent.verticalCenter
                text: ShellState.osdMode === "mic"
                      ? (AudioService.micMuted ? "Mute" : (AudioService.micVolume + "%"))
                      : (osdWin.levelValue + "%")
                font.family: Theme.fontMono
                font.pixelSize: Theme.typeLabelMedium
                font.weight: Font.Medium
                color: Theme.m3OnSurface
            }
        }
    }
}
