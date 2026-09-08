import QtQuick
import "."

Canvas {
    id: root

    property color iconColor: Theme.iconPrimary
    property real iconSize: 14

    width: iconSize
    height: iconSize

    onIconColorChanged: if (available) requestPaint()
    onAvailableChanged: if (available) requestPaint()

    onPaint: {
        var ctx = getContext("2d");
        ctx.clearRect(0, 0, width, height);

        var s = width / 14;
        ctx.save();
        ctx.scale(s, s);
        ctx.strokeStyle = root.iconColor;
        ctx.lineWidth = 1.5;
        ctx.lineCap = "round";

        ctx.beginPath();
        ctx.arc(7, 7.6, 5, -Math.PI * 0.35, Math.PI * 1.35);
        ctx.stroke();

        ctx.beginPath();
        ctx.moveTo(7, 1.6);
        ctx.lineTo(7, 7);
        ctx.stroke();

        ctx.restore();
    }
}
