import QtQuick
import Quickshell
import Quickshell.Wayland
import "../services"

PanelWindow {
    id: toastWin
    required property var modelData

    screen: modelData
    readonly property bool isTargetScreen: {
        if (Compositor.focusedOutputName !== "") {
            return Compositor.focusedOutputName === modelData.name
        }
        return Quickshell.screens.length > 0 && Quickshell.screens[0].name === modelData.name
    }

    visible: NotifService.popups.length > 0 && isTargetScreen && !ShellState.panelOpen
    color: "transparent"

    anchors {
        top: true
        right: true
    }

    implicitWidth: 408
    implicitHeight: Math.min(620, toastCol.implicitHeight + Theme.barHeight + 24)
    exclusionMode: ExclusionMode.Ignore
    exclusiveZone: 0

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "akari-notifications"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    Column {
        id: toastCol
        anchors.top: parent.top
        anchors.topMargin: Theme.barHeight + Theme.barMarginTop + Theme.space8
        anchors.right: parent.right
        anchors.rightMargin: Theme.barMarginSide
        width: 384
        spacing: Theme.space8

        move: Transition {
            NumberAnimation { properties: "y"; duration: 180; easing.type: Easing.OutCubic }
        }

        Repeater {
            model: NotifService.popups
            delegate: Rectangle {
                id: card
                required property var modelData
                width: 384
                height: cardCol.implicitHeight + Theme.space12 * 2
                radius: Theme.shapeMd
                color: Theme.m3SurfaceContainerHigh
                border.width: 1
                border.color: modelData.urgency === 2 ? Theme.m3Error : Theme.m3OutlineVariant

                MouseArea {
                    anchors.fill: parent
                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                    onClicked: mouse => {
                        if (mouse.button === Qt.RightButton) NotifService.dismissItem(card.modelData.uid)
                        else NotifService.hidePopup(card.modelData.uid)
                    }
                }

                Column {
                    id: cardCol
                    anchors {
                        top: parent.top
                        left: parent.left
                        right: parent.right
                        margins: Theme.space12
                    }
                    spacing: Theme.space12

                    // 1. NotificationHeader (NotifIconBox + appName | timeText + close)
                    Item {
                        width: parent.width
                        height: 24

                        Row {
                            anchors.left: parent.left
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: Theme.space8

                            Rectangle {
                                width: 24
                                height: 24
                                radius: Theme.shapeXs
                                color: card.modelData.urgency === 2 ? Theme.m3ErrorContainer : Theme.m3SecondaryContainer

                                MaterialIcon {
                                    anchors.centerIn: parent
                                    name: "notifications"
                                    iconSize: 14
                                    iconColor: card.modelData.urgency === 2 ? Theme.m3OnErrorContainer : Theme.m3OnSecondaryContainer
                                }
                            }

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: card.modelData.appName
                                font.family: Theme.fontUi
                                font.pixelSize: Theme.typeLabelSmall
                                font.weight: Font.Medium
                                color: Theme.m3OnSurfaceVariant
                            }
                        }

                        Row {
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: Theme.space8

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: card.modelData.timeText
                                font.family: Theme.fontUi
                                font.pixelSize: Theme.typeLabelSmall
                                font.weight: Font.Medium
                                color: Theme.m3OnSurfaceVariant
                            }

                            MaterialIcon {
                                anchors.verticalCenter: parent.verticalCenter
                                name: "close"
                                iconSize: 16
                                iconColor: Theme.m3OnSurfaceVariant

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: NotifService.dismissItem(card.modelData.uid)
                                }
                            }
                        }
                    }

                    // 2. NotificationBody (Summary + Body)
                    Column {
                        width: parent.width
                        spacing: Theme.space4

                        Text {
                            width: parent.width
                            text: card.modelData.summary
                            wrapMode: Text.Wrap
                            maximumLineCount: 2
                            elide: Text.ElideRight
                            font.family: Theme.fontUi
                            font.pixelSize: Theme.typeTitleSmall
                            font.weight: Font.Medium
                            color: Theme.m3OnSurface
                        }

                        Text {
                            visible: card.modelData.body !== ""
                            width: parent.width
                            text: card.modelData.body
                            wrapMode: Text.Wrap
                            maximumLineCount: 3
                            elide: Text.ElideRight
                            font.family: card.modelData.body.indexOf("/") >= 0 ? Theme.fontMono : Theme.fontUi
                            font.pixelSize: Theme.typeBodySmall
                            font.weight: Font.Medium
                            color: Theme.m3OnSurfaceVariant
                        }
                    }

                    // 3. NotificationActions (shown when notification provides actions)
                    Row {
                        visible: card.modelData.actions && card.modelData.actions.length > 0
                        spacing: Theme.space8

                        Repeater {
                            model: card.modelData.actions || []
                            delegate: Rectangle {
                                required property var modelData
                                required property int index
                                height: 28
                                width: actText.implicitWidth + 24
                                radius: Theme.shapeSm
                                color: index === 0 ? Theme.m3Primary : Theme.m3SurfaceContainerHighest

                                Text {
                                    id: actText
                                    anchors.centerIn: parent
                                    text: modelData.text
                                    font.family: Theme.fontUi
                                    font.pixelSize: Theme.typeLabelMedium
                                    font.weight: Font.Medium
                                    color: index === 0 ? Theme.m3OnPrimary : Theme.m3OnSurface
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: NotifService.invokeAction(card.modelData.uid, modelData.idx)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
