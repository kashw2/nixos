import QtQuick
import "."

Canvas {
    id: root

    property bool enabled: false

    width: 18
    height: 14

    onEnabledChanged: requestPaint()

    onPaint: {
        var ctx = getContext("2d");
        ctx.clearRect(0, 0, width, height);
        var col = enabled ? Theme.iconPrimary : Theme.iconDim;
        ctx.strokeStyle = col;
        ctx.lineWidth = 1.6;
        ctx.lineCap = "round";

        var cx = width / 2;
        var by = height;

        ctx.beginPath();
        ctx.arc(cx, by, 13, -Math.PI * 0.75, -Math.PI * 0.25);
        ctx.stroke();

        ctx.beginPath();
        ctx.arc(cx, by, 9, -Math.PI * 0.75, -Math.PI * 0.25);
        ctx.stroke();

        ctx.beginPath();
        ctx.arc(cx, by, 5, -Math.PI * 0.75, -Math.PI * 0.25);
        ctx.stroke();

        ctx.fillStyle = col;
        ctx.beginPath();
        ctx.arc(cx, by - 1, 1.8, 0, Math.PI * 2);
        ctx.fill();

        if (!enabled) {
            ctx.strokeStyle = Theme.iconDim;
            ctx.lineWidth = 1.8;
            ctx.beginPath();
            ctx.moveTo(1, 1);
            ctx.lineTo(width - 1, height - 1);
            ctx.stroke();
        }
    }
}
