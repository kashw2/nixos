import QtQuick
import "."

VectorIcon {
    id: root

    property int volume: 0
    property bool muted: false

    repaintOn: [volume, muted]

    function draw(ctx) {
        ctx.strokeStyle = muted ? Theme.iconDim : Theme.iconPrimary;
        ctx.fillStyle = muted ? Theme.iconDim : Theme.iconPrimary;
        ctx.lineWidth = 1.4;
        ctx.lineJoin = "round";
        ctx.lineCap = "round";

        ctx.beginPath();
        ctx.moveTo(1, 5);
        ctx.lineTo(3.5, 5);
        ctx.lineTo(6.5, 2);
        ctx.lineTo(6.5, 12);
        ctx.lineTo(3.5, 9);
        ctx.lineTo(1, 9);
        ctx.closePath();
        ctx.fill();

        if (muted) {
            ctx.strokeStyle = Theme.iconDim;
            ctx.lineWidth = 1.6;
            ctx.beginPath();
            ctx.moveTo(9, 4.5);
            ctx.lineTo(13, 9.5);
            ctx.stroke();
            ctx.beginPath();
            ctx.moveTo(13, 4.5);
            ctx.lineTo(9, 9.5);
            ctx.stroke();
        } else {
            ctx.strokeStyle = Theme.iconPrimary;
            ctx.lineWidth = 1.3;
            if (volume > 0) {
                ctx.beginPath();
                ctx.arc(7, 7, 3, -Math.PI / 4, Math.PI / 4);
                ctx.stroke();
            }
            if (volume > 33) {
                ctx.beginPath();
                ctx.arc(7, 7, 5, -Math.PI / 4, Math.PI / 4);
                ctx.stroke();
            }
            if (volume > 66) {
                ctx.beginPath();
                ctx.arc(7, 7, 7, -Math.PI / 4, Math.PI / 4);
                ctx.stroke();
            }
        }
    }
}
