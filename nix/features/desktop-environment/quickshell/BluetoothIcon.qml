import QtQuick
import "."

VectorIcon {
    id: root

    property bool powered: false

    width: 12
    height: 16
    repaintOn: [powered]

    function draw(ctx) {
        ctx.strokeStyle = powered ? Theme.iconPrimary : Theme.iconDim;
        ctx.lineWidth = 1.6;
        ctx.lineCap = "round";
        ctx.lineJoin = "round";

        var cx = width / 2;

        ctx.beginPath();
        ctx.moveTo(2, 4);
        ctx.lineTo(9, 11);
        ctx.lineTo(cx, 15);
        ctx.lineTo(cx, 1);
        ctx.lineTo(9, 5);
        ctx.lineTo(2, 12);
        ctx.stroke();
    }
}
