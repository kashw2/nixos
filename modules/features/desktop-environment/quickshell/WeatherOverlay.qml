import Quickshell
import QtQuick

Variants {
    id: root
    required property var shell

    model: Quickshell.screens

    PanelWindow {
        id: weatherOverlay
        required property var modelData
        screen: modelData

        visible: root.shell.weatherEffectType !== "none"

        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }

        exclusionMode: ExclusionMode.Ignore
        color: "transparent"
        focusable: false
        mask: Region {}

        Canvas {
            id: effectCanvas
            anchors.fill: parent

            property var particles: []
            property bool isSnow: root.shell.weatherEffectType === "snow"
            property bool isThunder: root.shell.weatherEffectType === "thunder"
            property int particleCount: isSnow ? 150 : 250
            property real flashOpacity: 0.0

            Component.onCompleted: initParticles()
            onWidthChanged: initParticles()
            onHeightChanged: initParticles()
            onIsSnowChanged: initParticles()

            function initParticles() {
                if (width <= 0 || height <= 0) return;
                var ps = [];
                for (var i = 0; i < particleCount; i++) {
                    ps.push(spawnParticle(true));
                }
                particles = ps;
            }

            function spawnParticle(scatter) {
                var w = effectCanvas.width;
                var h = effectCanvas.height;
                if (isSnow) {
                    return {
                        x: Math.random() * w,
                        y: scatter ? Math.random() * h : -(Math.random() * 20),
                        speed: 0.3 + Math.random() * 1.2,
                        size: 1 + Math.random() * 3,
                        drift: (Math.random() - 0.5) * 0.3,
                        wobble: Math.random() * Math.PI * 2,
                        opacity: 0.2 + Math.random() * 0.5
                    };
                } else {
                    return {
                        x: scatter ? Math.random() * w : Math.random() * w - 50,
                        y: scatter ? Math.random() * h : -(Math.random() * 40 + 30),
                        speed: 10 + Math.random() * 14,
                        length: 12 + Math.random() * 22,
                        wind: 1.5 + Math.random() * 2.5,
                        opacity: 0.08 + Math.random() * 0.18
                    };
                }
            }

            Timer {
                interval: 33
                running: weatherOverlay.visible
                repeat: true
                onTriggered: {
                    effectCanvas.tick();
                    effectCanvas.requestPaint();
                }
            }

            Timer {
                running: weatherOverlay.visible && effectCanvas.isThunder
                repeat: true
                interval: 8000 + Math.random() * 15000
                onTriggered: {
                    effectCanvas.flashOpacity = 0.12;
                    interval = 8000 + Math.random() * 15000;
                }
            }

            function tick() {
                var w = effectCanvas.width;
                var h = effectCanvas.height;
                var ps = particles;

                for (var i = 0; i < ps.length; i++) {
                    var p = ps[i];
                    if (isSnow) {
                        p.y += p.speed;
                        p.wobble += 0.02;
                        p.x += p.drift + Math.sin(p.wobble) * 0.4;
                        if (p.y > h + 10 || p.x < -10 || p.x > w + 10) {
                            ps[i] = spawnParticle(false);
                        }
                    } else {
                        p.y += p.speed;
                        p.x += p.wind;
                        if (p.y > h + 40 || p.x > w + 40) {
                            ps[i] = spawnParticle(false);
                        }
                    }
                }

                if (flashOpacity > 0) {
                    flashOpacity = Math.max(0, flashOpacity - 0.015);
                }
            }

            onPaint: {
                var ctx = getContext("2d");
                ctx.clearRect(0, 0, width, height);

                if (flashOpacity > 0) {
                    ctx.fillStyle = "rgba(255, 255, 255, " + flashOpacity + ")";
                    ctx.fillRect(0, 0, width, height);
                }

                var ps = particles;
                if (isSnow) {
                    for (var i = 0; i < ps.length; i++) {
                        var p = ps[i];
                        ctx.beginPath();
                        ctx.arc(p.x, p.y, p.size, 0, 2 * Math.PI);
                        ctx.fillStyle = "rgba(255, 255, 255, " + p.opacity + ")";
                        ctx.fill();
                    }
                } else {
                    ctx.lineWidth = 1.2;
                    ctx.lineCap = "round";
                    for (var j = 0; j < ps.length; j++) {
                        var q = ps[j];
                        var dx = q.wind * (q.length / q.speed);
                        ctx.beginPath();
                        ctx.moveTo(q.x, q.y);
                        ctx.lineTo(q.x + dx, q.y + q.length);
                        ctx.strokeStyle = "rgba(180, 210, 255, " + q.opacity + ")";
                        ctx.stroke();
                    }
                }
            }
        }
    }
}
