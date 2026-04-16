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
            property var splashes: []
            property bool isSnow: root.shell.weatherEffectType === "snow"
            property bool isThunder: root.shell.weatherEffectType === "thunder"
            property int baseParticleCount: isSnow ? 200 : 300
            property real intensityMultiplier: 1.0
            property real intensityTarget: 1.0
            property real flashOpacity: 0.0
            property int flashStage: 0
            property var lightningBolts: []
            property real globalWind: 0.0
            property real windTarget: 0.0
            property real gustStrength: 0.0
            property real gustDecay: 0.0
            property real time: 0
            property real snowAccumulation: 0.0
            property real ambientDarkness: 0.0
            property real ambientDarknessTarget: 0.0

            // Turbulence zones for snow
            property var turbulenceZones: []

            Component.onCompleted: initParticles()
            onWidthChanged: initParticles()
            onHeightChanged: initParticles()
            onIsSnowChanged: initParticles()

            function initParticles() {
                if (width <= 0 || height <= 0) return;
                var ps = [];
                for (var i = 0; i < baseParticleCount; i++) {
                    ps.push(spawnParticle(true));
                }
                particles = ps;
                splashes = [];
                lightningBolts = [];
                snowAccumulation = 0;
                initTurbulenceZones();
            }

            function initTurbulenceZones() {
                var zones = [];
                for (var i = 0; i < 3; i++) {
                    zones.push({
                        x: Math.random() * effectCanvas.width,
                        y: Math.random() * effectCanvas.height,
                        radius: 80 + Math.random() * 120,
                        strength: (Math.random() - 0.5) * 1.5,
                        vx: (Math.random() - 0.5) * 0.5,
                        vy: 0.1 + Math.random() * 0.2
                    });
                }
                turbulenceZones = zones;
            }

            function spawnParticle(scatter) {
                var w = effectCanvas.width;
                var h = effectCanvas.height;
                if (isSnow) {
                    var layer = Math.random();
                    var depth = layer < 0.3 ? 0 : (layer < 0.7 ? 1 : 2);
                    var depthScale = [0.4, 0.7, 1.0][depth];
                    return {
                        x: Math.random() * w,
                        y: scatter ? Math.random() * h : -(Math.random() * 30),
                        speed: (0.2 + Math.random() * 0.8) * depthScale,
                        size: (1.5 + Math.random() * 2.5) * depthScale,
                        drift: (Math.random() - 0.5) * 0.2,
                        wobble: Math.random() * Math.PI * 2,
                        wobbleSpeed: 0.01 + Math.random() * 0.03,
                        wobbleAmp: 0.2 + Math.random() * 0.6,
                        opacity: (0.15 + Math.random() * 0.35) * depthScale,
                        depth: depth,
                        rotation: Math.random() * Math.PI * 2,
                        rotSpeed: (Math.random() - 0.5) * 0.02,
                        isCrystal: depth === 2 && Math.random() < 0.3
                    };
                } else {
                    var rlayer = Math.random();
                    var rdepth = rlayer < 0.25 ? 0 : (rlayer < 0.6 ? 1 : 2);
                    var rscale = [0.5, 0.75, 1.0][rdepth];
                    return {
                        x: scatter ? Math.random() * w : Math.random() * w - 80,
                        y: scatter ? Math.random() * h : -(Math.random() * 60 + 40),
                        speed: (8 + Math.random() * 12) * rscale,
                        length: (10 + Math.random() * 20) * rscale,
                        wind: (1.5 + Math.random() * 2.0) * rscale,
                        opacity: (0.04 + Math.random() * 0.12) * rscale,
                        thickness: (0.5 + Math.random() * 0.8) * rscale,
                        depth: rdepth
                    };
                }
            }

            function spawnSplash(x, y) {
                var count = 2 + Math.floor(Math.random() * 3);
                var newSplashes = [];
                var windBias = globalWind + gustStrength * 0.5;
                for (var i = 0; i < count; i++) {
                    var angle = -Math.PI * (0.2 + Math.random() * 0.6);
                    var spd = 1 + Math.random() * 2.5;
                    newSplashes.push({
                        x: x,
                        y: y,
                        vx: Math.cos(angle) * spd + windBias,
                        vy: Math.sin(angle) * spd,
                        life: 1.0,
                        decay: 0.04 + Math.random() * 0.06
                    });
                }
                return newSplashes;
            }

            function generateBolt(x1, y1, x2, y2, displacement, branchChance) {
                var segments = [];
                generateBoltSegments(segments, x1, y1, x2, y2, displacement, branchChance, 0);
                return segments;
            }

            function generateBoltSegments(segments, x1, y1, x2, y2, displacement, branchChance, depth) {
                if (displacement < 3 || depth > 5) {
                    segments.push({ x1: x1, y1: y1, x2: x2, y2: y2, branch: depth > 0 });
                    return;
                }
                var mx = (x1 + x2) / 2 + (Math.random() - 0.5) * displacement;
                var my = (y1 + y2) / 2 + (Math.random() - 0.5) * displacement * 0.3;
                generateBoltSegments(segments, x1, y1, mx, my, displacement / 2, branchChance, depth);
                generateBoltSegments(segments, mx, my, x2, y2, displacement / 2, branchChance, depth);

                if (depth < 3 && Math.random() < branchChance) {
                    var bx = mx + (Math.random() - 0.5) * displacement * 1.5;
                    var by = my + displacement * (0.5 + Math.random() * 0.8);
                    generateBoltSegments(segments, mx, my, bx, by, displacement / 3, branchChance * 0.5, depth + 1);
                }
            }

            Timer {
                interval: 16
                running: weatherOverlay.visible
                repeat: true
                onTriggered: {
                    effectCanvas.tick();
                    effectCanvas.requestPaint();
                }
            }

            // Lightning strike timer
            Timer {
                running: weatherOverlay.visible && effectCanvas.isThunder
                repeat: true
                interval: 6000 + Math.random() * 18000
                onTriggered: {
                    effectCanvas.triggerLightning();
                    interval = 6000 + Math.random() * 18000;
                }
            }

            // Wind gust timer
            Timer {
                running: weatherOverlay.visible
                repeat: true
                interval: 4000 + Math.random() * 8000
                onTriggered: {
                    if (Math.random() < 0.4) {
                        var dir = Math.random() < 0.5 ? -1 : 1;
                        effectCanvas.gustStrength = dir * (1.5 + Math.random() * 3.0);
                        effectCanvas.gustDecay = 0.97 - Math.random() * 0.02;
                    }
                    interval = 4000 + Math.random() * 8000;
                }
            }

            // Rain intensity wave timer
            Timer {
                running: weatherOverlay.visible && !effectCanvas.isSnow
                repeat: true
                interval: 5000 + Math.random() * 10000
                onTriggered: {
                    effectCanvas.intensityTarget = 0.5 + Math.random() * 1.0;
                    interval = 5000 + Math.random() * 10000;
                }
            }

            function triggerLightning() {
                var w = effectCanvas.width;
                var h = effectCanvas.height;
                var startX = w * (0.2 + Math.random() * 0.6);
                var endX = startX + (Math.random() - 0.5) * 200;
                var endY = h * (0.5 + Math.random() * 0.4);
                var bolt = {
                    segments: generateBolt(startX, 0, endX, endY, 120, 0.4),
                    life: 1.0,
                    decay: 0.03 + Math.random() * 0.02
                };
                var bolts = lightningBolts;
                bolts.push(bolt);
                lightningBolts = bolts;

                flashStage = 1 + Math.floor(Math.random() * 3);
                flashOpacity = 0.08 + Math.random() * 0.1;
                ambientDarknessTarget = 0;
            }

            function tick() {
                var w = effectCanvas.width;
                var h = effectCanvas.height;
                var ps = particles;
                time += 0.016;

                // Wind with gusts
                windTarget += (Math.random() - 0.5) * 0.02;
                windTarget = Math.max(-0.8, Math.min(0.8, windTarget));
                globalWind += (windTarget - globalWind) * 0.005;

                if (Math.abs(gustStrength) > 0.01) {
                    gustStrength *= gustDecay;
                } else {
                    gustStrength = 0;
                }
                var effectiveWind = globalWind + gustStrength;

                // Rain intensity modulation
                intensityMultiplier += (intensityTarget - intensityMultiplier) * 0.01;
                var targetCount = Math.round(baseParticleCount * intensityMultiplier);

                // Adjust particle count toward target
                if (!isSnow) {
                    while (ps.length < targetCount && ps.length < 500) {
                        ps.push(spawnParticle(false));
                    }
                    while (ps.length > targetCount && ps.length > 100) {
                        ps.pop();
                    }
                }

                // Ambient darkness for thunder
                if (isThunder) {
                    ambientDarknessTarget = 0.06 + intensityMultiplier * 0.03;
                    if (flashStage > 0) {
                        ambientDarknessTarget = 0.02;
                    }
                }
                ambientDarkness += (ambientDarknessTarget - ambientDarkness) * 0.02;

                // Update turbulence zones
                var zones = turbulenceZones;
                for (var t = 0; t < zones.length; t++) {
                    zones[t].x += zones[t].vx;
                    zones[t].y += zones[t].vy;
                    if (zones[t].x < -zones[t].radius) zones[t].x = w + zones[t].radius;
                    if (zones[t].x > w + zones[t].radius) zones[t].x = -zones[t].radius;
                    if (zones[t].y > h + zones[t].radius) {
                        zones[t].y = -zones[t].radius;
                        zones[t].x = Math.random() * w;
                        zones[t].strength = (Math.random() - 0.5) * 1.5;
                    }
                }

                var newSplashes = [];

                for (var i = 0; i < ps.length; i++) {
                    var p = ps[i];
                    if (isSnow) {
                        p.y += p.speed;
                        p.wobble += p.wobbleSpeed;
                        p.rotation += p.rotSpeed;

                        // Base movement + global wind + gust
                        var windEffect = effectiveWind * [0.3, 0.6, 1.0][p.depth];
                        var turbulenceEffect = 0;

                        // Apply turbulence from nearby zones
                        for (var tz = 0; tz < zones.length; tz++) {
                            var dx = p.x - zones[tz].x;
                            var dy = p.y - zones[tz].y;
                            var dist = Math.sqrt(dx * dx + dy * dy);
                            if (dist < zones[tz].radius) {
                                var influence = 1 - (dist / zones[tz].radius);
                                turbulenceEffect += zones[tz].strength * influence * [0.2, 0.5, 1.0][p.depth];
                            }
                        }

                        p.x += p.drift + Math.sin(p.wobble) * p.wobbleAmp + windEffect + turbulenceEffect;

                        if (p.y > h + 10 || p.x < -20 || p.x > w + 20) {
                            ps[i] = spawnParticle(false);
                        }
                    } else {
                        // Rain affected by wind and gusts
                        var rainWind = p.wind + effectiveWind * [0.3, 0.6, 1.0][p.depth];
                        p.y += p.speed * intensityMultiplier;
                        p.x += rainWind;
                        if (p.y > h + 40 || p.x > w + 60 || p.x < -60) {
                            if (p.depth === 2 && Math.random() < 0.3) {
                                var sp = spawnSplash(p.x, h - 2);
                                for (var s = 0; s < sp.length; s++) {
                                    newSplashes.push(sp[s]);
                                }
                            }
                            ps[i] = spawnParticle(false);
                        }
                    }
                }

                // Snow accumulation
                if (isSnow) {
                    snowAccumulation = Math.min(30, snowAccumulation + 0.002);
                }

                // Update splashes
                var sl = splashes;
                for (var k = sl.length - 1; k >= 0; k--) {
                    sl[k].x += sl[k].vx;
                    sl[k].y += sl[k].vy;
                    sl[k].vy += 0.1;
                    sl[k].life -= sl[k].decay;
                    if (sl[k].life <= 0) {
                        sl.splice(k, 1);
                    }
                }
                for (var n = 0; n < newSplashes.length; n++) {
                    sl.push(newSplashes[n]);
                }
                if (sl.length > 80) {
                    sl.splice(0, sl.length - 80);
                }

                // Update lightning bolts
                var bolts = lightningBolts;
                for (var b = bolts.length - 1; b >= 0; b--) {
                    bolts[b].life -= bolts[b].decay;
                    if (bolts[b].life <= 0) {
                        bolts.splice(b, 1);
                    }
                }

                // Multi-stage flash
                if (flashStage > 0) {
                    flashOpacity -= 0.012;
                    if (flashOpacity <= 0) {
                        flashStage--;
                        if (flashStage > 0) {
                            flashOpacity = 0.04 + Math.random() * 0.08;
                        } else {
                            flashOpacity = 0;
                            ambientDarknessTarget = isThunder ? 0.06 : 0;
                        }
                    }
                }
            }

            onPaint: {
                var ctx = getContext("2d");
                var w = width;
                var h = height;
                ctx.clearRect(0, 0, w, h);

                // Ambient darkness for thunderstorms
                if (ambientDarkness > 0.005) {
                    ctx.fillStyle = "rgba(10, 15, 30, " + ambientDarkness + ")";
                    ctx.fillRect(0, 0, w, h);
                }

                // Lightning flash
                if (flashOpacity > 0) {
                    ctx.fillStyle = "rgba(200, 220, 255, " + flashOpacity + ")";
                    ctx.fillRect(0, 0, w, h);
                }

                // Draw lightning bolts
                var bolts = lightningBolts;
                for (var b = 0; b < bolts.length; b++) {
                    var bolt = bolts[b];
                    var alpha = bolt.life;

                    // Glow layer
                    ctx.lineWidth = 6;
                    ctx.strokeStyle = "rgba(180, 200, 255, " + (alpha * 0.15) + ")";
                    ctx.beginPath();
                    for (var sg = 0; sg < bolt.segments.length; sg++) {
                        var seg = bolt.segments[sg];
                        if (!seg.branch) {
                            ctx.moveTo(seg.x1, seg.y1);
                            ctx.lineTo(seg.x2, seg.y2);
                        }
                    }
                    ctx.stroke();

                    // Core layer (main trunk)
                    ctx.lineWidth = 2;
                    ctx.strokeStyle = "rgba(220, 235, 255, " + (alpha * 0.7) + ")";
                    ctx.beginPath();
                    for (var sg2 = 0; sg2 < bolt.segments.length; sg2++) {
                        var seg2 = bolt.segments[sg2];
                        if (!seg2.branch) {
                            ctx.moveTo(seg2.x1, seg2.y1);
                            ctx.lineTo(seg2.x2, seg2.y2);
                        }
                    }
                    ctx.stroke();

                    // Bright center
                    ctx.lineWidth = 0.8;
                    ctx.strokeStyle = "rgba(255, 255, 255, " + alpha + ")";
                    ctx.beginPath();
                    for (var sg3 = 0; sg3 < bolt.segments.length; sg3++) {
                        var seg3 = bolt.segments[sg3];
                        if (!seg3.branch) {
                            ctx.moveTo(seg3.x1, seg3.y1);
                            ctx.lineTo(seg3.x2, seg3.y2);
                        }
                    }
                    ctx.stroke();

                    // Branch segments (thinner, dimmer)
                    ctx.lineWidth = 1;
                    ctx.strokeStyle = "rgba(200, 215, 255, " + (alpha * 0.4) + ")";
                    ctx.beginPath();
                    for (var sg4 = 0; sg4 < bolt.segments.length; sg4++) {
                        var seg4 = bolt.segments[sg4];
                        if (seg4.branch) {
                            ctx.moveTo(seg4.x1, seg4.y1);
                            ctx.lineTo(seg4.x2, seg4.y2);
                        }
                    }
                    ctx.stroke();
                }

                var ps = particles;
                if (isSnow) {
                    for (var i = 0; i < ps.length; i++) {
                        var p = ps[i];
                        if (p.isCrystal && p.size > 2.5) {
                            // Draw 6-armed snowflake crystal
                            ctx.save();
                            ctx.translate(p.x, p.y);
                            ctx.rotate(p.rotation);
                            ctx.strokeStyle = "rgba(255, 255, 255, " + p.opacity + ")";
                            ctx.lineWidth = 0.6;
                            ctx.lineCap = "round";
                            var armLen = p.size * 1.2;
                            for (var a = 0; a < 6; a++) {
                                var angle = a * Math.PI / 3;
                                var ax = Math.cos(angle) * armLen;
                                var ay = Math.sin(angle) * armLen;
                                ctx.beginPath();
                                ctx.moveTo(0, 0);
                                ctx.lineTo(ax, ay);
                                // Small branches on each arm
                                var bx = Math.cos(angle) * armLen * 0.5;
                                var by = Math.sin(angle) * armLen * 0.5;
                                var bAngle1 = angle + Math.PI / 6;
                                var bAngle2 = angle - Math.PI / 6;
                                var bLen = armLen * 0.3;
                                ctx.moveTo(bx, by);
                                ctx.lineTo(bx + Math.cos(bAngle1) * bLen, by + Math.sin(bAngle1) * bLen);
                                ctx.moveTo(bx, by);
                                ctx.lineTo(bx + Math.cos(bAngle2) * bLen, by + Math.sin(bAngle2) * bLen);
                                ctx.stroke();
                            }
                            ctx.restore();
                        } else {
                            // Soft gradient snowflake
                            var grad = ctx.createRadialGradient(p.x, p.y, 0, p.x, p.y, p.size);
                            grad.addColorStop(0, "rgba(255, 255, 255, " + p.opacity + ")");
                            grad.addColorStop(0.4, "rgba(255, 255, 255, " + (p.opacity * 0.6) + ")");
                            grad.addColorStop(1, "rgba(255, 255, 255, 0)");
                            ctx.beginPath();
                            ctx.arc(p.x, p.y, p.size, 0, 2 * Math.PI);
                            ctx.fillStyle = grad;
                            ctx.fill();
                        }
                    }

                    // Snow accumulation gradient at bottom
                    if (snowAccumulation > 1) {
                        var accGrad = ctx.createLinearGradient(0, h - snowAccumulation, 0, h);
                        accGrad.addColorStop(0, "rgba(255, 255, 255, 0)");
                        accGrad.addColorStop(0.4, "rgba(255, 255, 255, 0.03)");
                        accGrad.addColorStop(1, "rgba(255, 255, 255, 0.08)");
                        ctx.fillStyle = accGrad;
                        ctx.fillRect(0, h - snowAccumulation, w, snowAccumulation);
                    }
                } else {
                    // Rain mist/spray along bottom
                    var mistHeight = h * 0.06;
                    var mistGrad = ctx.createLinearGradient(0, h - mistHeight, 0, h);
                    var mistOpacity = 0.02 + intensityMultiplier * 0.02;
                    mistGrad.addColorStop(0, "rgba(180, 210, 255, 0)");
                    mistGrad.addColorStop(0.5, "rgba(180, 210, 255, " + (mistOpacity * 0.5) + ")");
                    mistGrad.addColorStop(1, "rgba(180, 210, 255, " + mistOpacity + ")");
                    ctx.fillStyle = mistGrad;
                    ctx.fillRect(0, h - mistHeight, w, mistHeight);

                    // Rain drops
                    ctx.lineCap = "round";
                    var windAngle = globalWind + gustStrength;
                    for (var j = 0; j < ps.length; j++) {
                        var q = ps[j];
                        var rdx = (q.wind + windAngle * [0.3, 0.6, 1.0][q.depth]) * (q.length / q.speed);
                        ctx.lineWidth = q.thickness;
                        ctx.beginPath();
                        ctx.moveTo(q.x, q.y);
                        ctx.lineTo(q.x + rdx, q.y + q.length);
                        ctx.strokeStyle = "rgba(180, 210, 255, " + q.opacity + ")";
                        ctx.stroke();
                    }

                    // Splashes
                    var sl = splashes;
                    for (var m = 0; m < sl.length; m++) {
                        var sp = sl[m];
                        ctx.beginPath();
                        ctx.arc(sp.x, sp.y, 1, 0, 2 * Math.PI);
                        ctx.fillStyle = "rgba(180, 210, 255, " + (sp.life * 0.3) + ")";
                        ctx.fill();
                    }
                }
            }
        }
    }
}
