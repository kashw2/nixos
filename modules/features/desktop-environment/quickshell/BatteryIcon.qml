import QtQuick
import "."

Canvas {
    id: root

    property int percent: 0
    property bool charging: false
    property color toggleGreen: Theme.toggleGreen

    width: 24
    height: 12

    onPercentChanged: requestPaint()
    onChargingChanged: requestPaint()
    onToggleGreenChanged: requestPaint()

    onPaint: {
        var ctx = getContext("2d");
        ctx.clearRect(0, 0, width, height);

        ctx.strokeStyle = Theme.iconPrimary;
        ctx.lineWidth = 1.4;
        ctx.lineJoin = "round";
        ctx.beginPath();
        ctx.roundedRect(0.5, 0.5, 20, 11, 2, 2);
        ctx.stroke();

        ctx.fillStyle = Theme.iconPrimary;
        ctx.beginPath();
        ctx.roundedRect(21, 3, 2.5, 5, 1, 1);
        ctx.fill();

        var pct = percent / 100;
        var fillColor;
        if (charging) {
            fillColor = toggleGreen;
        } else if (percent <= 10) {
            fillColor = Qt.rgba(0.9, 0.2, 0.2, 0.9);
        } else if (percent <= 25) {
            fillColor = Qt.rgba(0.95, 0.5, 0.15, 0.85);
        } else if (percent <= 50) {
            fillColor = Qt.rgba(0.95, 0.85, 0.2, 0.8);
        } else {
            fillColor = toggleGreen;
        }

        var maxFillWidth = 17;
        var fillWidth = maxFillWidth * pct;
        if (fillWidth > 0.5) {
            ctx.fillStyle = fillColor;
            ctx.beginPath();
            ctx.roundedRect(2, 2.5, fillWidth, 7, 1, 1);
            ctx.fill();
        }

        if (charging) {
            ctx.fillStyle = Theme.iconPrimary;
            ctx.beginPath();
            ctx.moveTo(12, 1);
            ctx.lineTo(8, 6.5);
            ctx.lineTo(11, 6.5);
            ctx.lineTo(9, 11);
            ctx.lineTo(13, 5.5);
            ctx.lineTo(10, 5.5);
            ctx.closePath();
            ctx.fill();
        }
    }
}
