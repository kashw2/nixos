import QtQuick
import "."

VectorIcon {
    id: root

    property bool inhibited: false
    property color iconColor: Theme.iconPrimary
    property real steam: 0

    designSize: 14
    repaintOn: [inhibited, iconColor, inhibited ? steam : 0]

    function draw(ctx) {
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
    }
}
