import QtQuick
import "../services"

// Horizontal label/value row with an optional hairline track bar.
Item {
    id: meter

    property string label: ""
    property string valueText: ""
    property real ratio: 0
    property color barColor: Theme.m3Primary
    property bool warn: false

    implicitHeight: col.implicitHeight

    Column {
        id: col
        width: parent.width
        spacing: Theme.space4

        Item {
            width: parent.width
            height: 16

            Text {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                text: meter.label
                font.family: Theme.fontUi
                font.pixelSize: Theme.typeLabelMedium
                color: Theme.m3OnSurfaceVariant
            }

            Text {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                text: meter.valueText
                font.family: Theme.fontMono
                font.pixelSize: Theme.typeLabelMedium
                font.weight: Font.Medium
                color: meter.warn ? Theme.m3Error : Theme.m3OnSurface
            }
        }

        Rectangle {
            width: parent.width
            height: 6
            radius: 3
            color: Theme.m3SurfaceContainerHighest

            Rectangle {
                width: Math.max(0, Math.min(parent.width, parent.width * Math.max(0, Math.min(1, meter.ratio))))
                height: parent.height
                radius: 3
                color: meter.warn ? Theme.m3Error : meter.barColor
            }
        }
    }
}
