import QtQuick
import "."

Canvas {
    id: root

    property var cpuHistory: []
    property var ramHistory: []

    readonly property int maxPoints: 60
    readonly property real xMin: 1.5
    readonly property real xMax: 12.5
    readonly property real yMin: 1.5
    readonly property real yMax: 8.5

    width: 14
    height: 14

    onCpuHistoryChanged: requestPaint()
    onRamHistoryChanged: requestPaint()
    Component.onCompleted: requestPaint()
    onVisibleChanged: if (visible) requestPaint()

    function drawSeries(ctx, h, color, lw) {
        if (!h || h.length < 2) return;
        var usableW = xMax - xMin;
        var usableH = yMax - yMin;
        var stepX = usableW / (maxPoints - 1);
        var offset = maxPoints - h.length;
        ctx.strokeStyle = color;
        ctx.lineWidth = lw;
        ctx.lineJoin = "round";
        ctx.lineCap = "round";
        ctx.beginPath();
        for (var i = 0; i < h.length; i++) {
            var x = xMin + (offset + i) * stepX;
            var v = Math.max(0, Math.min(100, h[i]));
            var y = yMax - (usableH * v / 100);
            if (i === 0) ctx.moveTo(x, y);
            else ctx.lineTo(x, y);
        }
        ctx.stroke();
    }

    onPaint: {
        var ctx = getContext("2d");
        ctx.clearRect(0, 0, width, height);
        ctx.strokeStyle = Theme.iconPrimary;
        ctx.fillStyle = Theme.iconPrimary;
        ctx.lineWidth = 1.4;
        ctx.lineCap = "round";
        ctx.lineJoin = "round";
        ctx.beginPath();
        ctx.roundedRect(0.5, 0.5, 13, 10, 1.5, 1.5);
        ctx.stroke();
        ctx.beginPath();
        ctx.moveTo(5, 11.5);
        ctx.lineTo(9, 11.5);
        ctx.stroke();
        ctx.beginPath();
        ctx.moveTo(7, 10.5);
        ctx.lineTo(7, 11.5);
        ctx.stroke();

        var haveCpu = cpuHistory && cpuHistory.length >= 2;
        var haveRam = ramHistory && ramHistory.length >= 2;
        if (!haveCpu && !haveRam) {
            ctx.strokeStyle = Theme.iconDim;
            ctx.lineWidth = 0.8;
            ctx.beginPath();
            ctx.moveTo(xMin, yMax);
            ctx.lineTo(xMax, yMax);
            ctx.stroke();
            return;
        }
        drawSeries(ctx, ramHistory, Theme.graphRam, 0.8);
        drawSeries(ctx, cpuHistory, Theme.graphCpu, 1.0);
    }
}
