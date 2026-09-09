import QtQuick
import "."

VectorIcon {
    id: root

    property color iconColor: Theme.iconPrimary

    designSize: 14
    repaintOn: [iconColor]

    function draw(ctx) {
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
    }
}
