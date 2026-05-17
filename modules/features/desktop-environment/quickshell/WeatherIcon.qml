import QtQuick
import "."

Canvas {
    id: root

    property string iconType: "cloudy"
    property color iconColor: Theme.iconPrimary
    property real iconSize: 24
    property real animTime: 0

    width: iconSize
    height: iconSize

    // Paint as soon as the canvas's render context is ready. requestPaint()
    // calls made before `available` becomes true are silently dropped, so
    // hooking this signal avoids blank icons after first construction.
    onAvailableChanged: if (available) requestPaint()
    onIconTypeChanged: if (available) requestPaint()
    onIconColorChanged: if (available) requestPaint()
    onIconSizeChanged: if (available) requestPaint()
    onAnimTimeChanged: if (available) requestPaint()

    onPaint: {
        var ctx = getContext("2d");
        ctx.clearRect(0, 0, width, height);
        var s = width / 14;
        ctx.save();
        ctx.scale(s, s);
        ctx.strokeStyle = iconColor;
        ctx.fillStyle = iconColor;
        ctx.lineWidth = 1.3;
        ctx.lineCap = "round";

        var t = animTime;

        if (iconType === "sunny") {
            var sunColor = Qt.rgba(1.0, 0.82, 0.25, 1.0);
            ctx.fillStyle = sunColor;
            ctx.strokeStyle = sunColor;
            var pulse = 1 + Math.sin(t * 2.0) * 0.08;
            ctx.beginPath();
            ctx.arc(7, 7, 3 * pulse, 0, 2 * Math.PI);
            ctx.fill();
            var rot = t * 0.6;
            for (var i = 0; i < 8; i++) {
                var a = i * Math.PI / 4 + rot;
                var extend = 0.4 * Math.sin(t * 3 + i * 0.8);
                var ri = 4.5 + extend;
                var ro = 6.5 + extend;
                ctx.beginPath();
                ctx.moveTo(7 + Math.cos(a) * ri, 7 + Math.sin(a) * ri);
                ctx.lineTo(7 + Math.cos(a) * ro, 7 + Math.sin(a) * ro);
                ctx.stroke();
            }
            ctx.fillStyle = iconColor;
            ctx.strokeStyle = iconColor;
        } else if (iconType === "partlycloudy") {
            var pcSunColor = Qt.rgba(1.0, 0.82, 0.25, 1.0);
            var pcRot = t * 0.5;
            ctx.fillStyle = pcSunColor;
            ctx.strokeStyle = pcSunColor;
            ctx.beginPath();
            ctx.arc(10, 4, 2.5, 0, 2 * Math.PI);
            ctx.fill();
            for (var j = 0; j < 6; j++) {
                var a2 = j * Math.PI / 3 - Math.PI / 6 + pcRot;
                ctx.beginPath();
                ctx.moveTo(10 + Math.cos(a2) * 3.5, 4 + Math.sin(a2) * 3.5);
                ctx.lineTo(10 + Math.cos(a2) * 5, 4 + Math.sin(a2) * 5);
                ctx.stroke();
            }
            ctx.fillStyle = iconColor;
            ctx.strokeStyle = iconColor;
            var pcBob = Math.sin(t * 1.6) * 0.4;
            ctx.beginPath();
            ctx.arc(4, 9 + pcBob, 3, Math.PI, 1.5 * Math.PI);
            ctx.arc(7, 6.5 + pcBob, 3, 1.2 * Math.PI, 1.9 * Math.PI);
            ctx.arc(10.5, 9 + pcBob, 2.5, 1.5 * Math.PI, 0);
            ctx.lineTo(13, 11 + pcBob);
            ctx.lineTo(1, 11 + pcBob);
            ctx.closePath();
            ctx.fill();
        } else if (iconType === "rain") {
            // Rain drops falling across the full icon, no cloud.
            ctx.lineWidth = 1.3;
            var rainXs = [2, 4.5, 7, 9.5, 12];
            for (var ri = 0; ri < rainXs.length; ri++) {
                var rPhase = ri * 0.35;
                var fall = ((t * 1.4 + rPhase) % 1.0);
                var ry = 1 + fall * 10;
                var alpha = fall < 0.85 ? 1.0 : (1.0 - (fall - 0.85) / 0.15);
                ctx.strokeStyle = Qt.rgba(0.35, 0.6, 1.0, alpha);
                ctx.beginPath();
                ctx.moveTo(rainXs[ri], ry);
                ctx.lineTo(rainXs[ri] - 1.2, ry + 2.2);
                ctx.stroke();
            }
            ctx.strokeStyle = iconColor;
        } else if (iconType === "snow") {
            // Snowflakes drifting across the full icon, no cloud.
            ctx.font = "8px sans-serif";
            ctx.textAlign = "center";
            var snowXs = [2.5, 5, 7.5, 10, 12.5];
            for (var si = 0; si < snowXs.length; si++) {
                var sPhase = si * 0.45;
                var sFall = ((t * 0.7 + sPhase) % 1.0);
                var sy = 2 + sFall * 12;
                var swayX = Math.sin(t * 2.0 + si) * 0.7;
                var sAlpha = sFall < 0.85 ? 1.0 : (1.0 - (sFall - 0.85) / 0.15);
                ctx.fillStyle = Qt.rgba(0.6, 0.95, 1.0, sAlpha);
                ctx.fillText("*", snowXs[si] + swayX, sy);
            }
            ctx.fillStyle = iconColor;
        } else {
            var bob = Math.sin(t * 1.4) * 0.3;
            var drift = Math.sin(t * 0.9) * 0.4;
            ctx.beginPath();
            ctx.arc(4 + drift, 8 + bob, 3, Math.PI, 1.5 * Math.PI);
            ctx.arc(7 + drift, 5.5 + bob, 3, 1.2 * Math.PI, 1.9 * Math.PI);
            ctx.arc(10.5 + drift, 8 + bob, 2.5, 1.5 * Math.PI, 0);
            ctx.lineTo(13 + drift, 10 + bob);
            ctx.lineTo(1 + drift, 10 + bob);
            ctx.closePath();
            ctx.fill();

            if (iconType === "thunder") {
                ctx.lineWidth = 1.2;
                for (var ri2 = 0; ri2 < 3; ri2++) {
                    var tx = [4, 7, 10][ri2];
                    var tPhase = ri2 * 0.5;
                    var tFall = ((t * 1.6 + tPhase) % 1.0);
                    var ty = 11.2 + tFall * 2.6;
                    var tAlpha = tFall < 0.85 ? 1.0 : (1.0 - (tFall - 0.85) / 0.15);
                    ctx.strokeStyle = Qt.rgba(0.35, 0.6, 1.0, tAlpha);
                    ctx.beginPath();
                    ctx.moveTo(tx, ty);
                    ctx.lineTo(tx - 1, ty + 1.6);
                    ctx.stroke();
                }
                ctx.strokeStyle = iconColor;

                var flashCycle = (t % 2.0) / 2.0;
                var boltAlpha;
                if (flashCycle < 0.05) boltAlpha = flashCycle / 0.05;
                else if (flashCycle < 0.15) boltAlpha = 1.0;
                else if (flashCycle < 0.25) boltAlpha = 1.0 - (flashCycle - 0.15) / 0.1;
                else boltAlpha = 0.55;
                ctx.save();
                ctx.strokeStyle = Qt.rgba(1.0, 0.85, 0.3, boltAlpha);
                ctx.lineWidth = 1.4;
                ctx.beginPath();
                ctx.moveTo(8, 10); ctx.lineTo(6.5, 12); ctx.lineTo(8, 12); ctx.lineTo(6.5, 14);
                ctx.stroke();
                ctx.restore();
            }
            if (iconType === "fog") {
                ctx.lineWidth = 1;
                var sway1 = Math.sin(t * 1.2) * 1.5;
                var sway2 = Math.sin(t * 1.2 + Math.PI) * 1.5;
                ctx.beginPath();
                ctx.moveTo(2 + sway1, 11.5);
                ctx.lineTo(12 + sway1, 11.5);
                ctx.stroke();
                ctx.beginPath();
                ctx.moveTo(3 + sway2, 13);
                ctx.lineTo(11 + sway2, 13);
                ctx.stroke();
            }
        }
        ctx.restore();
    }
}
