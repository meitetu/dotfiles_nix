import QtQuick

Rectangle {
    id: badge
    property string label: "Esc"
    property color badgeFill: Theme.m3SurfaceContainerHigh
    property color textColor: Theme.m3OnSurfaceVariant

    height: 20
    width: Math.max(24, badgeText.implicitWidth + 16)
    radius: Theme.shapeXs
    color: badgeFill

    Text {
        id: badgeText
        anchors.centerIn: parent
        text: badge.label
        font.family: Theme.fontMono
        font.pixelSize: Theme.typeLabelMedium
        font.weight: Font.Medium
        color: badge.textColor
    }
}
