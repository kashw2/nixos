import QtQuick
import "."

Canvas {
    id: root

    property int count: 0

    width: 14
    height: 16

    onCountChanged: requestPaint()

    onPaint: {
        var ctx = getContext("2d");
        ctx.clearRect(0, 0, width, height);

        ctx.strokeStyle = Theme.iconPrimary;
        ctx.fillStyle = Theme.iconPrimary;
        ctx.lineWidth = 1.4;
        ctx.lineCap = "round";
        ctx.lineJoin = "round";

        ctx.beginPath();
        ctx.moveTo(2, 10);
        ctx.quadraticCurveTo(2, 5, 4, 3);
        ctx.quadraticCurveTo(5.5, 0.5, 7, 0.5);
        ctx.quadraticCurveTo(8.5, 0.5, 10, 3);
        ctx.quadraticCurveTo(12, 5, 12, 10);
        ctx.lineTo(13, 11.5);
        ctx.lineTo(1, 11.5);
        ctx.closePath();
        ctx.stroke();
        ctx.fill();

        ctx.beginPath();
        ctx.arc(7, 14, 1.5, 0, Math.PI * 2);
        ctx.fill();
    }
}
