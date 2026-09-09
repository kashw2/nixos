import QtQuick
import "."

Canvas {
    id: root

    property string iconType: "cloudy"
    property real phase: 0
    property real cornerRadius: 12
    property int density: 44

    onPhaseChanged: if (available) requestPaint()
    onIconTypeChanged: if (available) requestPaint()
    onWidthChanged: if (available) requestPaint()
    onHeightChanged: if (available) requestPaint()
    onAvailableChanged: if (available) requestPaint()

    function rnd(i, salt) {
        var x = Math.sin(i * 127.1 + salt * 311.7) * 43758.5453;
        return x - Math.floor(x);
    }

    function drawStreaks(ctx, w, h, count, speed, slant, len, alpha) {
        ctx.strokeStyle = Qt.rgba(1, 1, 1, alpha);
        ctx.lineWidth = 1;
        ctx.lineCap = "round";
        for (var i = 0; i < count; i++) {
            var y = (root.rnd(i, 1) * h + root.phase * speed * (0.6 + root.rnd(i, 2))) % (h + len) - len;
            var x = (root.rnd(i, 3) * w + y * slant) % w;
            ctx.beginPath();
            ctx.moveTo(x, y);
            ctx.lineTo(x + slant * len, y + len);
            ctx.stroke();
        }
    }

    function drawFlakes(ctx, w, h, count) {
        ctx.fillStyle = Qt.rgba(1, 1, 1, 0.30);
        for (var i = 0; i < count; i++) {
            var y = (root.rnd(i, 4) * h + root.phase * 6 * (0.5 + root.rnd(i, 5))) % (h + 6) - 3;
            var sway = Math.sin(root.phase * 0.8 + i) * 6;
            var x = (root.rnd(i, 6) * w + sway + w) % w;
            var r = 1 + root.rnd(i, 7) * 1.6;
            ctx.beginPath();
            ctx.arc(x, y, r, 0, Math.PI * 2);
            ctx.fill();
        }
    }

    function drawBlobs(ctx, w, h, count, alpha, speed) {
        ctx.fillStyle = Qt.rgba(1, 1, 1, alpha);
        for (var i = 0; i < count; i++) {
            var r = 26 + root.rnd(i, 8) * 46;
            var x = (root.rnd(i, 9) * (w + 200) + root.phase * speed * (0.4 + root.rnd(i, 10))) % (w + 2 * r) - r;
            var y = root.rnd(i, 11) * h;
            ctx.beginPath();
            ctx.arc(x, y, r, 0, Math.PI * 2);
            ctx.fill();
        }
    }

    function drawRays(ctx, w, h) {
        var cx = w - 40;
        var cy = 26;
        ctx.strokeStyle = Qt.rgba(1, 0.92, 0.68, 0.14);
        ctx.lineWidth = 12;
        ctx.lineCap = "round";
        for (var i = 0; i < 9; i++) {
            var a = root.phase * 0.05 + i * (Math.PI * 2 / 9);
            ctx.beginPath();
            ctx.moveTo(cx, cy);
            ctx.lineTo(cx + Math.cos(a) * 260, cy + Math.sin(a) * 260);
            ctx.stroke();
        }
    }

    onPaint: {
        var ctx = getContext("2d");
        ctx.clearRect(0, 0, width, height);
        if (width <= 0 || height <= 0 || root.iconType === "") return;

        ctx.save();
        ctx.beginPath();
        ctx.roundedRect(0, 0, width, height, root.cornerRadius, root.cornerRadius);
        ctx.clip();

        var w = width, h = height;

        if (root.iconType === "rain") {
            drawStreaks(ctx, w, h, root.density, 34, 0.22, 13, 0.18);
        } else if (root.iconType === "thunder") {
            drawStreaks(ctx, w, h, root.density + 14, 44, 0.3, 16, 0.20);
            var t = root.phase % 6.5;
            if (t < 0.16) {
                ctx.fillStyle = Qt.rgba(0.8, 0.78, 1, (0.16 - t) * 1.6);
                ctx.fillRect(0, 0, w, h);
            }
        } else if (root.iconType === "snow") {
            drawFlakes(ctx, w, h, root.density);
        } else if (root.iconType === "fog") {
            drawBlobs(ctx, w, h, 7, 0.05, 4);
        } else if (root.iconType === "cloudy") {
            drawBlobs(ctx, w, h, 6, 0.045, 3);
        } else if (root.iconType === "partlycloudy") {
            drawRays(ctx, w, h);
            drawBlobs(ctx, w, h, 4, 0.05, 3);
        } else if (root.iconType === "sunny") {
            drawRays(ctx, w, h);
        }

        ctx.restore();
    }
}
