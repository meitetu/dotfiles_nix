import QtQuick
import Quickshell
import Quickshell.Wayland
import "../services"

WlSessionLock {
    id: sessionLock
    locked: LockService.locked

    WlSessionLockSurface {
        id: lockSurface
        color: Theme.m3SurfaceDim

        readonly property bool isPrimaryWide: width >= 1600

        property string hmStr: "00:00"
        property string dateStr: "11/18 水"

        function updateTime() {
            var d = new Date()
            var days = ["日曜日", "月曜日", "火曜日", "水曜日", "木曜日", "金曜日", "土曜日"]
            var hh = ("0" + d.getHours()).slice(-2)
            var mm = ("0" + d.getMinutes()).slice(-2)
            var mo = d.getMonth() + 1
            var da = d.getDate()
            hmStr = hh + ":" + mm
            dateStr = mo + "月" + da + "日 " + days[d.getDay()]
        }

        Timer {
            interval: 1000
            repeat: true
            running: sessionLock.locked
            triggeredOnStart: true
            onTriggered: lockSurface.updateTime()
        }

        onVisibleChanged: {
            if (visible) {
                updateTime()
                if (isPrimaryWide) pwInput.forceActiveFocus()
                else secondaryKeyCatcher.forceActiveFocus()
            }
        }

        Component.onCompleted: {
            updateTime()
            if (isPrimaryWide) pwInput.forceActiveFocus()
            else secondaryKeyCatcher.forceActiveFocus()
        }

        // ====================================================================
        // Desktop Wallpaper Background (same image as live desktop)
        // ====================================================================
        Image {
            anchors.fill: parent
            source: LockService.wallpaperUrl
            fillMode: Image.PreserveAspectCrop
            asynchronous: false
            cache: true
        }

        // ====================================================================
        // PRIMARY MONITOR: Clean Clock Card + Compact M3 Password Card Only
        // ====================================================================
        Item {
            visible: lockSurface.isPrimaryWide
            anchors.fill: parent

            MouseArea {
                anchors.fill: parent
                onClicked: pwInput.forceActiveFocus()
            }

            // Bottom-Left Minimal Clock Card (leaves wallpaper completely clear & vivid)
            Rectangle {
                anchors {
                    left: parent.left
                    bottom: parent.bottom
                    leftMargin: 36
                    bottomMargin: 32
                }
                width: clockCol.implicitWidth + 36
                height: clockCol.implicitHeight + 24
                radius: Theme.shapeMd
                color: Theme.m3SurfaceContainerLow
                border.width: 1
                border.color: Theme.m3OutlineVariant

                Column {
                    id: clockCol
                    anchors.centerIn: parent
                    spacing: 2

                    Text {
                        text: lockSurface.hmStr
                        font.family: Theme.fontMono
                        font.pixelSize: 48
                        font.weight: Font.Medium
                        color: Theme.m3OnSurface
                    }

                    Text {
                        text: lockSurface.dateStr
                        font.family: Theme.fontUi
                        font.pixelSize: Theme.typeBodyMedium
                        font.weight: Font.Medium
                        color: Theme.m3OnSurfaceVariant
                    }
                }
            }

            // Bottom-Right Compact M3 Unlock Card (zero clutter)
            Rectangle {
                anchors {
                    right: parent.right
                    bottom: parent.bottom
                    rightMargin: 36
                    bottomMargin: 32
                }
                width: 340
                height: authCol.implicitHeight + Theme.space16 * 2
                radius: Theme.shapeMd
                color: Theme.m3SurfaceContainerLow
                border.width: 1
                border.color: LockService.hasError ? Theme.m3Error : Theme.m3OutlineVariant

                Column {
                    id: authCol
                    anchors {
                        top: parent.top
                        left: parent.left
                        right: parent.right
                        margins: Theme.space16
                    }
                    spacing: Theme.space12

                    // Password Input + Face Scan Status Icon + Submit Button
                    Row {
                        width: parent.width
                        spacing: Theme.space8

                        Rectangle {
                            width: parent.width - 44 - Theme.space8
                            height: 44
                            radius: Theme.shapeSm
                            color: Theme.m3SurfaceContainerHighest
                            border.width: 1
                            border.color: LockService.hasError ? Theme.m3Error : Theme.m3Primary

                            MaterialIcon {
                                id: faceStateIcon
                                anchors.left: parent.left
                                anchors.leftMargin: Theme.space12
                                anchors.verticalCenter: parent.verticalCenter
                                name: LockService.faceScanning ? "face" : "lock"
                                iconSize: 18
                                iconColor: LockService.faceScanning ? Theme.m3Tertiary : Theme.m3OnSurfaceVariant

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: LockService.retryFace()
                                }
                            }

                            Text {
                                visible: pwInput.text === ""
                                anchors.left: faceStateIcon.right
                                anchors.leftMargin: Theme.space8
                                anchors.verticalCenter: parent.verticalCenter
                                text: LockService.faceScanning ? "顔認証中 / パスワード" : "パスワード"
                                font.family: Theme.fontUi
                                font.pixelSize: Theme.typeBodySmall
                                color: Theme.m3OnSurfaceVariant
                            }

                            TextInput {
                                id: pwInput
                                anchors {
                                    left: faceStateIcon.right
                                    right: parent.right
                                    top: parent.top
                                    bottom: parent.bottom
                                    leftMargin: Theme.space8
                                    rightMargin: Theme.space12
                                }
                                verticalAlignment: TextInput.AlignVCenter
                                echoMode: TextInput.Password
                                passwordCharacter: "•"
                                font.family: Theme.fontMono
                                font.pixelSize: Theme.typeLabelLarge
                                color: Theme.m3OnSurface
                                cursorVisible: activeFocus
                                clip: true

                                Connections {
                                    target: LockService
                                    function onInputTextChanged() {
                                        if (pwInput.text !== LockService.inputText) {
                                            pwInput.text = LockService.inputText
                                        }
                                    }
                                }
                                onTextChanged: {
                                    if (LockService.inputText !== text) {
                                        LockService.inputText = text
                                    }
                                }
                                onAccepted: LockService.submit()
                                Keys.onEscapePressed: {
                                    LockService.inputText = ""
                                    LockService.hasError = false
                                    LockService.errorText = ""
                                }
                            }
                        }

                        // Unlock Arrow Button (44x44, M3 Primary)
                        Rectangle {
                            width: 44
                            height: 44
                            radius: Theme.shapeSm
                            color: unlockBtnMouse.containsMouse ? Theme.m3PrimaryContainer : Theme.m3Primary

                            MaterialIcon {
                                anchors.centerIn: parent
                                name: "arrow_forward"
                                iconSize: 20
                                iconColor: unlockBtnMouse.containsMouse ? Theme.m3OnPrimaryContainer : Theme.m3OnPrimary
                            }

                            MouseArea {
                                id: unlockBtnMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: LockService.submit()
                            }
                        }
                    }

                    // Shown ONLY when an actual password error occurs
                    Text {
                        visible: LockService.hasError && LockService.errorText !== ""
                        width: parent.width
                        text: LockService.errorText
                        font.family: Theme.fontUi
                        font.pixelSize: Theme.typeBodySmall
                        color: Theme.m3Error
                    }
                }
            }
        }

        // ====================================================================
        // SECONDARY MONITOR: Clean Wallpaper Only (still accepts typing)
        // ====================================================================
        Item {
            visible: !lockSurface.isPrimaryWide
            anchors.fill: parent

            TextInput {
                id: secondaryKeyCatcher
                width: 1
                height: 1
                opacity: 0
                echoMode: TextInput.Password
                Connections {
                    target: LockService
                    function onInputTextChanged() {
                        if (secondaryKeyCatcher.text !== LockService.inputText) {
                            secondaryKeyCatcher.text = LockService.inputText
                        }
                    }
                }
                onTextChanged: {
                    if (LockService.inputText !== text) LockService.inputText = text
                }
                onAccepted: LockService.submit()
            }

            MouseArea {
                anchors.fill: parent
                onClicked: secondaryKeyCatcher.forceActiveFocus()
            }
        }
    }
}
