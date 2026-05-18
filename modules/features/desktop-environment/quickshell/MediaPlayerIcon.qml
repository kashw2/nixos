import QtQuick
import "."

Canvas {
    id: root

    property string iconType: "paused"
    property color iconColor: Theme.iconPrimary
    property real iconSize: 24
    property real animTime: 0

    width: iconSize
    height: iconSize

    onAvailableChanged: if (available) requestPaint()
    onIconTypeChanged: if (available) requestPaint()
    onIconColorChanged: if (available) requestPaint()
    onIconSizeChanged: if (available) requestPaint()
    onAnimTimeChanged: if (available && iconType === "playing") requestPaint()

    onPaint: {
        var ctx = getContext("2d");
        ctx.clearRect(0, 0, width, height);
        var s = width / 14;
        ctx.save();
        ctx.scale(s, s);
        ctx.fillStyle = iconColor;
        ctx.strokeStyle = iconColor;
        ctx.lineCap = "round";
        ctx.lineJoin = "round";

        var t = animTime;

        if (iconType === "playing") {
            var barWidth = 2.4;
            var spacing = 1.6;
            var groupWidth = 3 * barWidth + 2 * spacing;
            var startX = (14 - groupWidth) / 2;
            var centerY = 7;
            var maxBarHeight = 11;
            var minBarHeight = 3;

            for (var i = 0; i < 3; i++) {
                var phase = i * 0.9;
                var amp = 0.5 + 0.5 * Math.sin(t * 4.0 + phase);
                var h = minBarHeight + (maxBarHeight - minBarHeight) * amp;
                var x = startX + i * (barWidth + spacing);
                ctx.beginPath();
                ctx.rect(x, centerY - h / 2, barWidth, h);
                ctx.fill();
            }
        } else if (iconType === "paused") {
            var pBarWidth = 3.0;
            var pSpacing = 2.8;
            var pGroupWidth = 2 * pBarWidth + pSpacing;
            var pStartX = (14 - pGroupWidth) / 2;
            var pHeight = 11;
            var pY = (14 - pHeight) / 2;
            ctx.beginPath();
            ctx.rect(pStartX, pY, pBarWidth, pHeight);
            ctx.rect(pStartX + pBarWidth + pSpacing, pY, pBarWidth, pHeight);
            ctx.fill();
        } else {
            ctx.lineWidth = 1.2;
            ctx.beginPath();
            ctx.moveTo(7.4, 2.5);
            ctx.lineTo(7.4, 10.6);
            ctx.stroke();
            ctx.beginPath();
            ctx.arc(5.7, 10.8, 1.8, 0, 2 * Math.PI);
            ctx.fill();
            ctx.beginPath();
            ctx.moveTo(7.4, 2.5);
            ctx.quadraticCurveTo(11, 3.6, 10.4, 6.4);
            ctx.stroke();
        }
        ctx.restore();
    }
}
