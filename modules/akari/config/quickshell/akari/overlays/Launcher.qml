import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import "../services"

PanelWindow {
    id: launcherWin
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

    readonly property bool shouldOpen: ShellState.launcherOpen && isTargetScreen

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
    WlrLayershell.namespace: "akari-launcher"
    WlrLayershell.keyboardFocus: shouldOpen ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    property string queryText: ""
    property int activeCategory: 0 // 0: すべて | 1: 開発 | 2: システム | 3: メディア
    property int selectedIndex: 0
    property var filteredApps: []

    readonly property var categoryDefs: [
        { label: "すべて",   keys: [] },
        { label: "開発",     keys: ["development", "ide", "texteditor", "terminalemulator"] },
        { label: "システム", keys: ["system", "settings", "utility", "filemanager", "monitor"] },
        { label: "メディア", keys: ["audiovideo", "audio", "video", "graphics", "photography", "recorder"] }
    ]

    function matchesCategory(app, catIdx) {
        if (catIdx <= 0 || catIdx >= categoryDefs.length) return true
        var needles = categoryDefs[catIdx].keys
        var cats = app.categories || []
        for (var i = 0; i < cats.length; i++) {
            var c = String(cats[i]).toLowerCase()
            for (var j = 0; j < needles.length; j++) {
                if (c.indexOf(needles[j]) >= 0) return true
            }
        }
        return false
    }

    function rebuildList() {
        var raw = AppCatalogService.apps || []
        var q = queryText.trim().toLowerCase()
        var out = []

        for (var i = 0; i < raw.length; i++) {
            var app = raw[i]
            if (!app) continue
            if (!matchesCategory(app, activeCategory)) continue

            if (q !== "") {
                var hay = (app.name + " " + app.subtitle + " " + app.bin + " " + app.keywords).toLowerCase()
                if (hay.indexOf(q) < 0) continue
            }

            out.push(app)
        }

        if (q !== "") {
            out.sort(function(a, b) {
                var aStarts = a.name.toLowerCase().indexOf(q) === 0 || a.bin.toLowerCase().indexOf(q) === 0
                var bStarts = b.name.toLowerCase().indexOf(q) === 0 || b.bin.toLowerCase().indexOf(q) === 0
                if (aStarts !== bStarts) return aStarts ? -1 : 1
                return a.name.localeCompare(b.name, "ja")
            })
        }

        filteredApps = out
        selectedIndex = 0
        if (appListView) appListView.positionViewAtBeginning()
    }

    Connections {
        target: AppCatalogService
        function onAppsChanged() {
            if (launcherWin.shouldOpen) launcherWin.rebuildList()
        }
    }

    function launchCurrent() {
        if (filteredApps.length > 0 && selectedIndex >= 0 && selectedIndex < filteredApps.length) {
            var target = filteredApps[selectedIndex]
            ShellState.launcherOpen = false
            AppCatalogService.launch(target)
        } else if (queryText.trim().startsWith("$")) {
            var shCmd = queryText.trim().slice(1).trim()
            if (shCmd !== "") {
                ShellState.launcherOpen = false
                Quickshell.execDetached(["env", "GTK_IM_MODULE=fcitx", "QT_IM_MODULE=fcitx", "bash", "-lc", shCmd])
            }
        }
    }

    onShouldOpenChanged: {
        if (shouldOpen) {
            // Always rescan so apps installed after shell start appear immediately
            AppCatalogService.refresh()
            queryText = ""
            searchInput.text = ""
            activeCategory = 0
            rebuildList()
            searchInput.forceActiveFocus()
        }
    }

    MouseArea {
        anchors.fill: parent
        enabled: launcherWin.shouldOpen
        onClicked: ShellState.launcherOpen = false
    }

    // ========================================================================
    // Left-Aligned M3 Launcher Card (448w, surface-container-low, 12dp radius)
    // ========================================================================
    Rectangle {
        id: launcherCard
        anchors {
            top: parent.top
            left: parent.left
            topMargin: Theme.barHeight + Theme.barMarginTop + Theme.space8
            leftMargin: Theme.barMarginSide
        }
        width: 448
        height: cardColumn.implicitHeight + Theme.space16 * 2
        radius: Theme.shapeMd
        color: Theme.m3SurfaceContainerLow
        border.width: 1
        border.color: Theme.m3OutlineVariant

        MouseArea { anchors.fill: parent }

        Column {
            id: cardColumn
            anchors {
                top: parent.top
                left: parent.left
                right: parent.right
                margins: Theme.space16
            }
            spacing: Theme.space12

            // 1. SearchField (48dp h, surface-container-highest, 1dp primary border, 8dp radius)
            Rectangle {
                width: parent.width
                height: 48
                radius: Theme.shapeSm
                color: Theme.m3SurfaceContainerHighest
                border.width: 1
                border.color: Theme.m3Primary

                Row {
                    anchors {
                        left: parent.left
                        right: escBadge.left
                        verticalCenter: parent.verticalCenter
                        leftMargin: Theme.space12
                        rightMargin: Theme.space8
                    }
                    spacing: Theme.space12

                    MaterialIcon {
                        anchors.verticalCenter: parent.verticalCenter
                        name: "search"
                        iconSize: 20
                        iconColor: Theme.m3OnSurfaceVariant
                    }

                    Item {
                        width: parent.width - 32
                        height: 24
                        anchors.verticalCenter: parent.verticalCenter

                        Text {
                            visible: searchInput.text === "" && searchInput.preeditText === ""
                            anchors.verticalCenter: parent.verticalCenter
                            text: "アプリ・コマンドを検索..."
                            font.family: Theme.fontUi
                            font.pixelSize: Theme.typeBodyMedium
                            color: Theme.m3OnSurfaceVariant
                        }

                        TextInput {
                            id: searchInput
                            anchors.fill: parent
                            verticalAlignment: TextInput.AlignVCenter
                            font.family: Theme.fontUi
                            font.pixelSize: Theme.typeBodyMedium
                            color: Theme.m3OnSurface
                            selectionColor: Theme.m3SecondaryContainer
                            selectedTextColor: Theme.m3OnSecondaryContainer
                            clip: true

                            onTextChanged: {
                                launcherWin.queryText = text
                                launcherWin.rebuildList()
                            }

                            Keys.onPressed: event => {
                                if (event.key === Qt.Key_Escape) {
                                    ShellState.launcherOpen = false
                                    event.accepted = true
                                } else if (event.key === Qt.Key_Down || (event.modifiers & Qt.ControlModifier && event.key === Qt.Key_N)) {
                                    if (launcherWin.filteredApps.length > 0) {
                                        launcherWin.selectedIndex = Math.min(launcherWin.filteredApps.length - 1, launcherWin.selectedIndex + 1)
                                        appListView.positionViewAtIndex(launcherWin.selectedIndex, ListView.Contain)
                                    }
                                    event.accepted = true
                                } else if (event.key === Qt.Key_Up || (event.modifiers & Qt.ControlModifier && event.key === Qt.Key_P)) {
                                    if (launcherWin.filteredApps.length > 0) {
                                        launcherWin.selectedIndex = Math.max(0, launcherWin.selectedIndex - 1)
                                        appListView.positionViewAtIndex(launcherWin.selectedIndex, ListView.Contain)
                                    }
                                    event.accepted = true
                                } else if (event.key === Qt.Key_Tab) {
                                    launcherWin.activeCategory = (launcherWin.activeCategory + 1) % launcherWin.categoryDefs.length
                                    launcherWin.rebuildList()
                                    event.accepted = true
                                } else if (event.key === Qt.Key_Backtab) {
                                    launcherWin.activeCategory = (launcherWin.activeCategory + launcherWin.categoryDefs.length - 1) % launcherWin.categoryDefs.length
                                    launcherWin.rebuildList()
                                    event.accepted = true
                                } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                                    launcherWin.launchCurrent()
                                    event.accepted = true
                                }
                            }
                        }
                    }
                }

                KeyBadge {
                    id: escBadge
                    anchors.right: parent.right
                    anchors.rightMargin: Theme.space12
                    anchors.verticalCenter: parent.verticalCenter
                    label: "Esc"

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: ShellState.launcherOpen = false
                    }
                }
            }

            // 2. FilterChips (すべて / 開発 / システム / メディア)
            Row {
                width: parent.width
                spacing: Theme.space8

                Repeater {
                    model: launcherWin.categoryDefs
                    delegate: Rectangle {
                        required property var modelData
                        required property int index
                        readonly property bool active: launcherWin.activeCategory === index

                        height: 28
                        width: chipLabel.implicitWidth + 24
                        radius: Theme.shapeSm
                        color: active ? Theme.m3Primary
                             : (chipMouse.containsMouse ? Theme.m3SurfaceContainerHigh : Theme.m3SurfaceContainer)

                        Text {
                            id: chipLabel
                            anchors.centerIn: parent
                            text: modelData.label
                            font.family: Theme.fontUi
                            font.pixelSize: Theme.typeLabelMedium
                            font.weight: Font.Medium
                            color: parent.active ? Theme.m3OnPrimary : Theme.m3OnSurfaceVariant
                        }

                        MouseArea {
                            id: chipMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                launcherWin.activeCategory = index
                                launcherWin.rebuildList()
                                searchInput.forceActiveFocus()
                            }
                        }
                    }
                }
            }

            // 3. AppList (5 visible 56dp items = 296dp max height, scrollable)
            ListView {
                id: appListView
                width: parent.width
                height: Math.min(296, Math.max(56, launcherWin.filteredApps.length * 60 - 4))
                spacing: Theme.space4
                clip: true
                boundsBehavior: Flickable.StopAtBounds
                model: launcherWin.filteredApps

                Text {
                    visible: launcherWin.filteredApps.length === 0
                    anchors.centerIn: parent
                    text: AppCatalogService.apps.length === 0 ? "アプリケーションを読み込み中..." : "一致するアプリケーションがありません"
                    font.family: Theme.fontUi
                    font.pixelSize: Theme.typeBodySmall
                    color: Theme.m3OnSurfaceVariant
                }

                delegate: Rectangle {
                    id: appRow
                    required property var modelData
                    required property int index
                    readonly property bool isSelected: index === launcherWin.selectedIndex

                    width: appListView.width
                    height: 56
                    radius: Theme.shapeSm
                    color: isSelected ? Theme.m3SecondaryContainer
                         : (rowMouse.containsMouse ? Theme.m3SurfaceContainer : "transparent")

                    // Left AppIdentity (36x36 IconContainer + 2-line AppText)
                    Row {
                        anchors {
                            left: parent.left
                            right: execLabel.left
                            verticalCenter: parent.verticalCenter
                            leftMargin: Theme.space8
                            rightMargin: Theme.space12
                        }
                        spacing: Theme.space12

                        Rectangle {
                            width: 36
                            height: 36
                            anchors.verticalCenter: parent.verticalCenter
                            radius: Theme.shapeSm
                            color: appRow.isSelected ? Theme.m3PrimaryContainer : Theme.m3SurfaceContainerHigh

                            IconImage {
                                id: appIconImg
                                visible: modelData.icon !== "" && status === Image.Ready
                                anchors.centerIn: parent
                                width: 20
                                height: 20
                                source: {
                                    var ic = modelData.icon || ""
                                    if (ic === "") return ""
                                    if (ic.startsWith("file://") || ic.startsWith("image://")) return ic
                                    if (ic.startsWith("/")) return "file://" + ic
                                    return "image://icon/" + ic
                                }
                            }

                            MaterialIcon {
                                visible: !appIconImg.visible
                                anchors.centerIn: parent
                                name: "apps"
                                iconSize: 20
                                iconColor: appRow.isSelected ? Theme.m3OnPrimaryContainer : Theme.m3OnSurfaceVariant
                            }
                        }

                        Column {
                            width: parent.width - 48
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 0

                            Text {
                                width: parent.width
                                text: modelData.name
                                elide: Text.ElideRight
                                font.family: Theme.fontUi
                                font.pixelSize: Theme.typeBodyMedium
                                font.weight: Font.Normal
                                color: appRow.isSelected ? Theme.m3OnSecondaryContainer : Theme.m3OnSurface
                            }

                            Text {
                                width: parent.width
                                text: modelData.subtitle
                                elide: Text.ElideRight
                                font.family: Theme.fontUi
                                font.pixelSize: Theme.typeBodySmall
                                color: appRow.isSelected ? Theme.m3OnSecondaryContainer : Theme.m3OnSurfaceVariant
                            }
                        }
                    }

                    // Right executable binary name
                    Text {
                        id: execLabel
                        anchors.right: parent.right
                        anchors.rightMargin: Theme.space12
                        anchors.verticalCenter: parent.verticalCenter
                        width: Math.min(112, implicitWidth)
                        text: modelData.bin
                        elide: Text.ElideRight
                        font.family: Theme.fontMono
                        font.pixelSize: Theme.typeLabelMedium
                        font.weight: Font.Medium
                        color: appRow.isSelected ? Theme.m3OnSecondaryContainer : Theme.m3OnSurfaceVariant
                    }

                    MouseArea {
                        id: rowMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onEntered: launcherWin.selectedIndex = index
                        onClicked: {
                            launcherWin.selectedIndex = index
                            launcherWin.launchCurrent()
                        }
                    }
                }
            }

            // 4. LauncherFooter (↑↓ 移動 · Enter 起動)
            Item {
                width: parent.width
                height: 28

                Row {
                    anchors.left: parent.left
                    anchors.leftMargin: Theme.space4
                    anchors.bottom: parent.bottom
                    spacing: Theme.space8

                    KeyBadge { label: "↑↓" }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "移動"
                        font.family: Theme.fontUi
                        font.pixelSize: Theme.typeLabelMedium
                        font.weight: Font.Medium
                        color: Theme.m3OnSurfaceVariant
                    }
                }

                Row {
                    anchors.right: parent.right
                    anchors.rightMargin: Theme.space4
                    anchors.bottom: parent.bottom
                    spacing: Theme.space8

                    KeyBadge { label: "Enter" }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "起動"
                        font.family: Theme.fontUi
                        font.pixelSize: Theme.typeLabelMedium
                        font.weight: Font.Medium
                        color: Theme.m3OnSurface
                    }
                }
            }
        }
    }
}
