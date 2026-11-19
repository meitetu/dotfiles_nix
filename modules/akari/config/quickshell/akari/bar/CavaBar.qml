import QtQuick
import Quickshell
import Quickshell.Wayland
import "../services"

PanelWindow {
    id: cavaWin
    required property var modelData

    screen: modelData

    readonly property bool shouldShow: CavaService.enabled && (!CavaService.autoHideSilent || CavaService.activeAudio)

    visible: shouldShow
    color: "transparent"

    anchors {
        bottom: true
        left: true
        right: true
    }

    implicitHeight: CavaService.barHeight + Theme.space8
    exclusionMode: CavaService.layerMode === "reserve" ? ExclusionMode.Normal : ExclusionMode.Ignore
    exclusiveZone: (CavaService.enabled && CavaService.layerMode === "reserve")
        ? (CavaService.barHeight + Theme.space8)
        : 0

    // Completely click-through so bottom window controls & wallpaper remain interactive
    mask: Region {}

    WlrLayershell.layer: CavaService.layerMode === "desktop" ? WlrLayer.Bottom : WlrLayer.Top
    WlrLayershell.namespace: "akari-cava"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    Item {
        id: barsContainer
        anchors {
            left: parent.left
            right: parent.right
            bottom: parent.bottom
            leftMargin: Theme.barMarginSide
            rightMargin: Theme.barMarginSide
            bottomMargin: 4
        }
        height: CavaService.barHeight

        readonly property int count: CavaService.barCount
        readonly property real gap: width < 1500 ? 3 : 4
        readonly property real singleBarW: Math.max(2, (width - gap * (count - 1)) / count)

        Row {
            anchors {
                left: parent.left
                right: parent.right
                bottom: parent.bottom
            }
            height: parent.height
            spacing: barsContainer.gap

            Repeater {
                model: barsContainer.count

                delegate: Item {
                    required property int index
                    width: barsContainer.singleBarW
                    height: barsContainer.height

                    readonly property int rawVal: index < CavaService.values.length ? CavaService.values[index] : 0
                    readonly property real ratio: rawVal / 1000.0
                    readonly property real barPx: Math.max(3, Math.round(height * ratio))

                    Rectangle {
                        anchors {
                            left: parent.left
                            right: parent.right
                            bottom: parent.bottom
                        }
                        height: parent.barPx
                        topLeftRadius: Math.min(4, width / 2)
                        topRightRadius: Math.min(4, width / 2)
                        bottomLeftRadius: 2
                        bottomRightRadius: 2
                        opacity: parent.rawVal > 8 ? 0.92 : 0.45
                        color: {
                            if (parent.rawVal <= 8) return Theme.m3OutlineVariant
                            if (parent.ratio > 0.72) return Theme.m3Primary
                            if (parent.ratio > 0.28) return Theme.m3PrimaryContainer
                            return Theme.m3Secondary
                        }
                    }
                }
            }
        }
    }
}
