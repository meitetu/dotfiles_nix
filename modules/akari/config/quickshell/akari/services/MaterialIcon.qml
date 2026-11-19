import QtQuick

Text {
    id: iconRoot
    property string name: ""
    property int iconSize: 16
    property color iconColor: Theme.m3OnSurfaceVariant

    text: name
    font.family: Theme.fontIcon
    font.pixelSize: iconSize
    font.weight: Font.Normal
    color: iconColor
    width: iconSize
    height: iconSize
    horizontalAlignment: Text.AlignHCenter
    verticalAlignment: Text.AlignVCenter
    renderType: Text.QtRendering
}
