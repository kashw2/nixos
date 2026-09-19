import QtQuick
import "."

VectorIcon {
    id: root

    property bool active: false

    repaintOn: [active]

    function draw(ctx) {
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
