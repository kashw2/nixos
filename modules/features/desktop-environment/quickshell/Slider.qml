import QtQuick
import "."

Rectangle {
    id: root

    property int value: 0
    property int minValue: 0
    property int maxValue: 100
    property bool dimmed: false

    signal moved(int value)

    readonly property real fraction: Math.min(Math.max((value - minValue) / (maxValue - minValue), 0), 1)

    height: 6
    radius: 3
    color: Theme.surfaceStrong

    Rectangle {
        width: parent.width * root.fraction
        height: parent.height
        radius: 3
        color: root.dimmed ? Theme.surfaceBg : Theme.textDim

        Behavior on width { NumberAnimation { duration: 100 } }
    }

    Rectangle {
        x: parent.width * root.fraction - 7
        y: -4
        width: 14
        height: 14
        radius: 7
        color: Theme.iconPrimary

        Behavior on x { NumberAnimation { duration: 100 } }
    }

    MouseArea {
        anchors.fill: parent
        anchors.topMargin: -8
        anchors.bottomMargin: -8
        cursorShape: Qt.PointingHandCursor

        function update(mouse) {
            var range = root.maxValue - root.minValue;
            var v = Math.round(mouse.x / width * range) + root.minValue;
            v = Math.max(root.minValue, Math.min(root.maxValue, v));
            root.moved(v);
        }

        onPressed: mouse => update(mouse)
        onPositionChanged: mouse => {
            if (pressed) update(mouse);
        }
    }
}
