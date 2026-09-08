import QtQuick
import "."

Canvas {
    id: root

    property bool inhibited: false
    property color iconColor: Theme.iconPrimary
    property real iconSize: 14
    property real steam: 0

    width: iconSize
    height: iconSize

    onInhibitedChanged: if (available) requestPaint()
    onIconColorChanged: if (available) requestPaint()
    onSteamChanged: if (available && inhibited) requestPaint()
    onAvailableChanged: if (available) requestPaint()

    onPaint: {
        var ctx = getContext("2d");
        ctx.clearRect(0, 0, width, height);

        var s = width / 14;
        ctx.save();
        ctx.scale(s, s);
        ctx.strokeStyle = root.iconColor;
        ctx.fillStyle = root.iconColor;
        ctx.lineWidth = 1.3;
        ctx.lineCap = "round";
        ctx.lineJoin = "round";

        ctx.beginPath();
        ctx.moveTo(2.5, 5.5);
        ctx.lineTo(2.5, 10);
        ctx.quadraticCurveTo(2.5, 12, 4.5, 12);
        ctx.lineTo(8, 12);
        ctx.quadraticCurveTo(10, 12, 10, 10);
        ctx.lineTo(10, 5.5);
        ctx.closePath();
        ctx.stroke();

        ctx.beginPath();
        ctx.moveTo(10, 6.5);
        ctx.quadraticCurveTo(12.5, 6.5, 12.5, 8.2);
        ctx.quadraticCurveTo(12.5, 9.9, 10, 9.9);
        ctx.stroke();

        if (root.inhibited) {
            for (var i = 0; i < 3; i++) {
                var x = 4.2 + i * 2.2;
                var wob = Math.sin(root.steam * 2 + i) * 0.7;
                ctx.beginPath();
                ctx.moveTo(x, 4.2);
                ctx.quadraticCurveTo(x + wob, 2.8, x, 1.4);
                ctx.stroke();
            }
        } else {
            ctx.lineWidth = 1.5;
            ctx.beginPath();
            ctx.moveTo(1.5, 1.5);
            ctx.lineTo(12.5, 12.5);
            ctx.stroke();
        }

        ctx.restore();
    }
}
