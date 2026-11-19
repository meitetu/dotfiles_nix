import QtQuick
import Quickshell
import Quickshell.Wayland
import "../services"

PanelWindow {
    id: powerWin
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

    readonly property bool shouldOpen: ShellState.powerOpen && isTargetScreen

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
    WlrLayershell.namespace: "akari-power"
    WlrLayershell.keyboardFocus: shouldOpen ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    function runAction(kind) {
        ShellState.powerOpen = false
        if (kind === "lock") LockService.activate()
        else if (kind === "suspend") Quickshell.execDetached(["systemctl", "suspend"])
        else if (kind === "logout") Compositor.quitSession()
        else if (kind === "reboot") Quickshell.execDetached(["systemctl", "reboot"])
        else if (kind === "shutdown") Quickshell.execDetached(["systemctl", "poweroff"])
    }

    MouseArea {
        anchors.fill: parent
        enabled: powerWin.shouldOpen
        onClicked: ShellState.powerOpen = false
    }

    Item {
        anchors.fill: parent
        focus: powerWin.shouldOpen
        Keys.onEscapePressed: ShellState.powerOpen = false

        Rectangle {
            anchors.centerIn: parent
            width: rowItems.implicitWidth + Theme.space16 * 2
            height: 120
            radius: Theme.shapeMd
            color: Theme.m3SurfaceContainerLow
            border.width: 1
            border.color: Theme.m3OutlineVariant

            MouseArea { anchors.fill: parent }

            Row {
                id: rowItems
                anchors.centerIn: parent
                spacing: Theme.space8

                Repeater {
                    model: [
                        { icon: "lock",                label: "ロック",       act: "lock",     destructive: false },
                        { icon: "dark_mode",           label: "スリープ",     act: "suspend",  destructive: false },
                        { icon: "logout",              label: "ログアウト",   act: "logout",   destructive: false },
                        { icon: "restart_alt",         label: "再起動",       act: "reboot",   destructive: false },
                        { icon: "power_settings_new",  label: "電源オフ",     act: "shutdown", destructive: true  }
                    ]
                    delegate: Rectangle {
                        required property var modelData
                        width: 96
                        height: 88
                        radius: Theme.shapeSm
                        color: modelData.destructive
                               ? Theme.m3ErrorContainer
                               : (actMouse.containsMouse ? Theme.m3SecondaryContainer : Theme.m3SurfaceContainerHigh)

                        Column {
                            anchors.centerIn: parent
                            spacing: Theme.space8

                            MaterialIcon {
                                anchors.horizontalCenter: parent.horizontalCenter
                                name: modelData.icon
                                iconSize: 22
                                iconColor: modelData.destructive
                                           ? Theme.m3OnErrorContainer
                                           : (actMouse.containsMouse ? Theme.m3OnSecondaryContainer : Theme.m3OnSurfaceVariant)
                            }

                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: modelData.label
                                font.family: Theme.fontUi
                                font.pixelSize: Theme.typeLabelMedium
                                font.weight: Font.Medium
                                color: modelData.destructive
                                       ? Theme.m3OnErrorContainer
                                       : (actMouse.containsMouse ? Theme.m3OnSecondaryContainer : Theme.m3OnSurface)
                            }
                        }

                        MouseArea {
                            id: actMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: powerWin.runAction(modelData.act)
                        }
                    }
                }
            }
        }
    }
}
