import QtQuick
import "../services"

// Bar-style history graph used by the System Monitor cards.
// Fixed-width slots grow from the right so a fresh history starts empty.
Item {
    id: spark

    property var series: []
    property int maxSlots: 40
    property real maxValue: 100
    property color barColor: Theme.m3Primary
    property color trackColor: Theme.m3SurfaceContainerHighest
    property int barGap: 3
    property int barRadius: 1

    clip: true

    readonly property int count: series ? series.length : 0
    readonly property int slots: Math.max(1, maxSlots)
    readonly property real slotW: width / slots
    readonly property real barW: Math.max(1, slotW - barGap)

    // Baseline so the graph area stays readable while empty
    Rectangle {
        anchors.bottom: parent.bottom
        width: parent.width
        height: 1
        color: Theme.m3OutlineVariant
        opacity: 0.5
    }

    Repeater {
        model: spark.count

        delegate: Rectangle {
            id: bar
            required property int index

            readonly property real value: spark.series[index] !== undefined ? spark.series[index] : 0
            readonly property real ratio: spark.maxValue > 0
                ? Math.max(0, Math.min(1, value / spark.maxValue))
                : 0

            // Newest sample sits at the right edge
            x: spark.width - (spark.count - index) * spark.slotW + spark.barGap / 2
            width: spark.barW
            height: Math.max(1, (spark.height - 1) * bar.ratio)
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 1
            radius: spark.barRadius
            color: spark.barColor
            opacity: 0.45 + 0.55 * (bar.index / Math.max(1, spark.count - 1))
        }
    }
}
