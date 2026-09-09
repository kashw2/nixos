import QtQuick
import "."

Canvas {
    id: root

    property real iconSize: 14
    property real designSize: 0
    property var repaintOn: []

    width: iconSize
    height: iconSize

    onRepaintOnChanged: if (available) requestPaint()
    onAvailableChanged: if (available) requestPaint()
    onVisibleChanged: if (visible && available) requestPaint()
    onWidthChanged: if (available) requestPaint()
    onHeightChanged: if (available) requestPaint()

    function draw(ctx) {}

    onPaint: {
        var ctx = getContext("2d");
        ctx.clearRect(0, 0, width, height);
        ctx.save();
        if (root.designSize > 0) {
            var s = width / root.designSize;
            ctx.scale(s, s);
        }
        root.draw(ctx);
        ctx.restore();
    }
}
