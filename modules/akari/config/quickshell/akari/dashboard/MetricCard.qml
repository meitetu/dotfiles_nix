import QtQuick
import "../services"

// Base card used across the System Monitor dashboard.
Rectangle {
    id: card

    property string title: ""
    property string iconName: ""
    property string trailingText: ""
    default property alias content: body.data

    implicitHeight: frame.implicitHeight + Theme.space16 * 2
    height: implicitHeight
    radius: Theme.shapeMd
    color: Theme.m3SurfaceContainer
    border.width: 1
    border.color: Theme.m3OutlineVariant
    clip: true

    Column {
        id: frame
        anchors {
            top: parent.top
            left: parent.left
            right: parent.right
            margins: Theme.space16
        }
        spacing: Theme.space8

        // ---- Header -----------------------------------------------------
        Item {
            width: parent.width
            height: 20

            Row {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                spacing: Theme.space8

                MaterialIcon {
                    anchors.verticalCenter: parent.verticalCenter
                    name: card.iconName
                    iconSize: 16
                    iconColor: Theme.m3Primary
                }

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: card.title
                    font.family: Theme.fontUi
                    font.pixelSize: Theme.typeTitleSmall
                    font.weight: Font.Medium
                    color: Theme.m3OnSurface
                }
            }

            Text {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                text: card.trailingText
                font.family: Theme.fontMono
                font.pixelSize: Theme.typeLabelSmall
                font.weight: Font.Medium
                color: Theme.m3OnSurfaceVariant
            }
        }

        // ---- Body -------------------------------------------------------
        Column {
            id: body
            width: parent.width
            spacing: Theme.space8
        }
    }
}
