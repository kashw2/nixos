import QtQuick
import "."

Canvas {
    id: root

    property bool active: false

    width: 14
    height: 14

    onActiveChanged: requestPaint()

    onPaint: {
        var ctx = getContext("2d");
        ctx.clearRect(0, 0, width, height);
        ctx.strokeStyle = active ? Theme.iconPrimary : Theme.iconDim;
        ctx.lineWidth = 1.4;
        ctx.lineCap = "round";
        ctx.lineJoin = "round";

        var cx = width / 2;

        ctx.beginPath();
        ctx.moveTo(cx, 1);
        ctx.lineTo(cx, 13);
        ctx.stroke();

        ctx.beginPath();
        ctx.moveTo(3, 4);
        ctx.lineTo(width - 3, 4);
        ctx.stroke();

        ctx.beginPath();
        ctx.moveTo(3, 4);
        ctx.lineTo(3, 7);
        ctx.stroke();

        ctx.beginPath();
        ctx.moveTo(width - 3, 4);
        ctx.lineTo(width - 3, 7);
        ctx.stroke();
    }
}
