import Quickshell
import QtQuick
import QtQuick.Layouts
import "."

Variants {
    id: root
    required property var shell
    model: Quickshell.screens

    BasePopup {
        shell: root.shell
        popupName: "brightness"
        popupWidth: 240

    Text {
        text: "Brightness"
        color: Theme.text
        font.pixelSize: 13
        font.bold: true
    }

    RowLayout {
        width: parent.width
        spacing: 10

        // Sun icon (dim)
        Canvas {
            width: 12
            height: 12
            Layout.alignment: Qt.AlignVCenter

            property color stroke: Theme.textDim
            onStrokeChanged: requestPaint()

            onPaint: {
                var ctx = getContext("2d");
                ctx.clearRect(0, 0, width, height);
                ctx.strokeStyle = stroke;
                ctx.lineWidth = 1.2;
                ctx.beginPath();
                ctx.arc(6, 6, 2.5, 0, 2 * Math.PI);
                ctx.stroke();
            }
        }

        Slider {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            minValue: 1
            value: root.shell.brightnessPercent
            onMoved: v => {
                root.shell.brightnessPercent = v;
                root.shell.setBrightness(v);
            }
        }

        // Sun icon (bright)
        Canvas {
            width: 14
            height: 14
            Layout.alignment: Qt.AlignVCenter

            property color stroke: Theme.iconPrimary
            property color fill: Theme.textDim
            onStrokeChanged: requestPaint()
            onFillChanged: requestPaint()

            onPaint: {
                var ctx = getContext("2d");
                ctx.clearRect(0, 0, width, height);
                var cx = 7;
                var cy = 7;
                ctx.strokeStyle = stroke;
                ctx.lineWidth = 1.2;
                ctx.lineCap = "round";
                for (var i = 0; i < 8; i++) {
                    var angle = i * Math.PI / 4;
                    ctx.beginPath();
                    ctx.moveTo(cx + Math.cos(angle) * 4.5, cy + Math.sin(angle) * 4.5);
                    ctx.lineTo(cx + Math.cos(angle) * 6.5, cy + Math.sin(angle) * 6.5);
                    ctx.stroke();
                }
                ctx.beginPath();
                ctx.arc(cx, cy, 2.5, 0, 2 * Math.PI);
                ctx.stroke();
                ctx.fillStyle = fill;
                ctx.fill();
            }
        }
    }

    // Percentage label
    Text {
        text: root.shell.brightnessPercent + "%"
        color: Theme.textDim
        font.pixelSize: 11
        anchors.horizontalCenter: parent.horizontalCenter
    }
    }
}
