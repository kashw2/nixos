import QtQuick
import "."

Canvas {
    id: root

    property int percent: 0
    property color iconColor: Theme.iconPrimary

    width: 14
    height: 14

    onPercentChanged: requestPaint()
    onIconColorChanged: requestPaint()
    onVisibleChanged: if (visible) requestPaint()
    Component.onCompleted: requestPaint()

    onPaint: {
        var ctx = getContext("2d");
        ctx.clearRect(0, 0, width, height);

        var cx = 7;
        var cy = 7;
        var r = 3;

        ctx.strokeStyle = iconColor;
        ctx.lineWidth = 1.4;
        ctx.lineCap = "round";
        var rayLen = 2;
        var rayDist = 5;
        for (var i = 0; i < 8; i++) {
            var angle = i * Math.PI / 4;
            ctx.beginPath();
            ctx.moveTo(cx + Math.cos(angle) * rayDist, cy + Math.sin(angle) * rayDist);
            ctx.lineTo(cx + Math.cos(angle) * (rayDist + rayLen), cy + Math.sin(angle) * (rayDist + rayLen));
            ctx.stroke();
        }

        var opacity = 0.4 + (percent / 100) * 0.6;
        ctx.fillStyle = Qt.rgba(iconColor.r, iconColor.g, iconColor.b, opacity);
        ctx.beginPath();
        ctx.arc(cx, cy, r, 0, 2 * Math.PI);
        ctx.fill();

        ctx.strokeStyle = iconColor;
        ctx.lineWidth = 1.4;
        ctx.beginPath();
        ctx.arc(cx, cy, r, 0, 2 * Math.PI);
        ctx.stroke();
    }
}
