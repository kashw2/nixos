import QtQuick
import "."

Canvas {
    id: root

    property var history: []
    property var secondaryHistory: []
    property color lineColor: Theme.graphRam
    property color secondaryColor: "transparent"
    property color gridColor: Theme.surfaceSubtle
    property real maxValue: 100
    property int maxPoints: 60
    property bool showGrid: true
    property bool fillArea: true
    property real areaAlpha: 0.15
    property real lineWidth: 1.5
    property real level: -1

    readonly property real plotHeight: level >= 0 ? height - 4 : height

    onHistoryChanged: if (available) requestPaint()
    onSecondaryHistoryChanged: if (available) requestPaint()
    onLineColorChanged: if (available) requestPaint()
    onSecondaryColorChanged: if (available) requestPaint()
    onGridColorChanged: if (available) requestPaint()
    onMaxValueChanged: if (available) requestPaint()
    onLevelChanged: if (available) requestPaint()
    onWidthChanged: if (available) requestPaint()
    onHeightChanged: if (available) requestPaint()
    onAvailableChanged: if (available) requestPaint()

    function traceSeries(ctx, h, top, stepX, offset) {
        for (var i = 0; i < h.length; i++) {
            var x = (offset + i) * stepX;
            var y = root.plotHeight - root.plotHeight * Math.min(1, Math.max(0, h[i] / top));
            if (i === 0) ctx.moveTo(x, y);
            else ctx.lineTo(x, y);
        }
    }

    onPaint: {
        var ctx = getContext("2d");
        ctx.clearRect(0, 0, width, height);

        if (root.level >= 0) {
            ctx.fillStyle = Theme.surfaceStrong;
            ctx.fillRect(0, height - 3, width, 3);
            ctx.fillStyle = Qt.rgba(root.lineColor.r, root.lineColor.g, root.lineColor.b, 0.85);
            ctx.fillRect(0, height - 3, width * Math.min(1, Math.max(0, root.level)), 3);
        }

        if (root.showGrid) {
            ctx.strokeStyle = root.gridColor;
            ctx.lineWidth = 0.5;
            for (var g = 1; g <= 3; g++) {
                var gy = root.plotHeight - root.plotHeight * g / 4;
                ctx.beginPath();
                ctx.moveTo(0, gy);
                ctx.lineTo(width, gy);
                ctx.stroke();
            }
        }

        var h = root.history;
        if (!h || h.length < 2) return;

        var top = Math.max(1, root.maxValue);
        var stepX = width / (root.maxPoints - 1);
        var offset = root.maxPoints - h.length;

        if (root.fillArea) {
            ctx.fillStyle = Qt.rgba(root.lineColor.r, root.lineColor.g, root.lineColor.b, root.areaAlpha);
            ctx.beginPath();
            root.traceSeries(ctx, h, top, stepX, offset);
            ctx.lineTo((offset + h.length - 1) * stepX, root.plotHeight);
            ctx.lineTo(offset * stepX, root.plotHeight);
            ctx.closePath();
            ctx.fill();
        }

        ctx.strokeStyle = root.lineColor;
        ctx.lineWidth = root.lineWidth;
        ctx.lineJoin = "round";
        ctx.beginPath();
        root.traceSeries(ctx, h, top, stepX, offset);
        ctx.stroke();

        var s = root.secondaryHistory;
        if (s && s.length >= 2) {
            ctx.strokeStyle = root.secondaryColor;
            ctx.lineWidth = root.lineWidth;
            ctx.beginPath();
            root.traceSeries(ctx, s, top, stepX, root.maxPoints - s.length);
            ctx.stroke();
        }
    }
}
