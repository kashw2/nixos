import QtQuick
import "."

Item {
    id: root

    property url source
    property color fallback: Theme.accent
    property color dominant: root.fallback

    width: 0
    height: 0

    onSourceChanged: {
        if (root.source == "") {
            root.dominant = root.fallback;
            return;
        }
        sampler.loadImage(root.source);
    }

    function normalise(r, g, b) {
        var c = Qt.rgba(r, g, b, 1);
        if (c.hsvHue < 0) return root.fallback;
        var s = Math.min(Math.max(c.hsvSaturation, 0.45), 0.85);
        var v = Math.min(Math.max(c.hsvValue, 0.72), 0.96);
        return Qt.hsva(c.hsvHue, s, v, 1);
    }

    Canvas {
        id: sampler
        width: 32
        height: 32
        visible: false
        renderTarget: Canvas.Image
        renderStrategy: Canvas.Immediate

        onImageLoaded: requestPaint()

        onPaint: {
            if (root.source == "" || !isImageLoaded(root.source)) return;

            var ctx = getContext("2d");
            ctx.clearRect(0, 0, width, height);
            ctx.drawImage(root.source, 0, 0, width, height);

            var px = ctx.getImageData(0, 0, width, height).data;
            var wr = 0, wg = 0, wb = 0, total = 0;

            for (var i = 0; i < px.length; i += 4) {
                var r = px[i] / 255, g = px[i + 1] / 255, b = px[i + 2] / 255;
                var mx = Math.max(r, g, b), mn = Math.min(r, g, b);
                var sat = mx === 0 ? 0 : (mx - mn) / mx;
                var w = sat * sat * mx;
                wr += r * w; wg += g * w; wb += b * w; total += w;
            }

            if (total < 0.0001) {
                root.dominant = root.fallback;
                return;
            }

            root.dominant = root.normalise(wr / total, wg / total, wb / total);
        }
    }
}
