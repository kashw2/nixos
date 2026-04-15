import Quickshell
import Quickshell.Hyprland
import QtQuick
import QtQuick.Layouts

Variants {
    id: root
    required property var shell

    model: Quickshell.screens

    PanelWindow {
        id: sysMonPopupWindow
        required property var modelData
        screen: modelData

        visible: root.shell.sysMonPopupOpen && root.shell.sysMonPopupScreen === modelData

        HyprlandFocusGrab {
            active: root.shell.sysMonPopupOpen && root.shell.sysMonPopupScreen === modelData
            windows: [sysMonPopupWindow]
            onCleared: {
                root.shell.sysMonPopupOpen = false;
            }
        }

        anchors {
            top: true
            right: true
        }
        margins {
            top: 38
            right: 8
        }
        implicitWidth: 280
        implicitHeight: sysMonPopupContent.implicitHeight + 24
        exclusionMode: ExclusionMode.Ignore
        color: "transparent"

        Rectangle {
            anchors.fill: parent
            radius: 12
            color: Qt.rgba(1, 1, 1, 0.3)
            clip: true

            Column {
                id: sysMonPopupContent
                anchors {
                    fill: parent
                    margins: 12
                }
                spacing: 8

                Text {
                    text: "System Monitor"
                    color: "#ffffff"
                    font.pixelSize: 13
                    font.bold: true
                }

                // CPU
                RowLayout {
                    width: parent.width
                    Text {
                        text: "CPU"
                        color: Qt.rgba(1, 1, 1, 0.7)
                        font.pixelSize: 11
                        Layout.fillWidth: true
                    }
                    Text {
                        text: root.shell.cpuPercent + "%"
                        color: "#ffffff"
                        font.pixelSize: 11
                        font.bold: true
                    }
                }

                Rectangle {
                    width: parent.width
                    height: 6
                    radius: 3
                    color: Qt.rgba(1, 1, 1, 0.2)

                    Rectangle {
                        width: parent.width * root.shell.cpuPercent / 100
                        height: parent.height
                        radius: 3
                        color: root.shell.cpuPercent > 90 ? Qt.rgba(0.9, 0.2, 0.2, 0.9)
                             : root.shell.cpuPercent > 70 ? Qt.rgba(0.95, 0.5, 0.15, 0.85)
                             : Qt.rgba(0.4, 0.8, 0.4, 0.7)
                        Behavior on width { NumberAnimation { duration: 300 } }
                    }
                }

                Canvas {
                    id: cpuGraph
                    visible: root.shell.cpuHistoryCount >= 2
                    width: parent.width
                    height: 40

                    property var history: root.shell.cpuHistory
                    onHistoryChanged: requestPaint()

                    onPaint: {
                        var ctx = getContext("2d");
                        ctx.clearRect(0, 0, width, height);
                        var h = history;
                        if (h.length < 2) return;
                        var maxPoints = 60;
                        var stepX = width / (maxPoints - 1);
                        var offset = maxPoints - h.length;

                        ctx.strokeStyle = Qt.rgba(1, 1, 1, 0.1);
                        ctx.lineWidth = 0.5;
                        for (var g = 1; g <= 3; g++) {
                            var gy = height - (height * g * 25 / 100);
                            ctx.beginPath();
                            ctx.moveTo(0, gy);
                            ctx.lineTo(width, gy);
                            ctx.stroke();
                        }

                        ctx.fillStyle = Qt.rgba(0.4, 0.8, 0.4, 0.15);
                        ctx.beginPath();
                        for (var i = 0; i < h.length; i++) {
                            var x = (offset + i) * stepX;
                            var y = height - (height * h[i] / 100);
                            if (i === 0) ctx.moveTo(x, y);
                            else ctx.lineTo(x, y);
                        }
                        ctx.lineTo((offset + h.length - 1) * stepX, height);
                        ctx.lineTo(offset * stepX, height);
                        ctx.closePath();
                        ctx.fill();

                        ctx.strokeStyle = Qt.rgba(0.4, 0.8, 0.4, 0.8);
                        ctx.lineWidth = 1.5;
                        ctx.lineJoin = "round";
                        ctx.beginPath();
                        for (var j = 0; j < h.length; j++) {
                            var x2 = (offset + j) * stepX;
                            var y2 = height - (height * h[j] / 100);
                            if (j === 0) ctx.moveTo(x2, y2);
                            else ctx.lineTo(x2, y2);
                        }
                        ctx.stroke();
                    }
                }

                Rectangle { width: parent.width; height: 1; color: Qt.rgba(1, 1, 1, 0.15) }

                // RAM
                RowLayout {
                    width: parent.width
                    Text {
                        text: "Memory"
                        color: Qt.rgba(1, 1, 1, 0.7)
                        font.pixelSize: 11
                        Layout.fillWidth: true
                    }
                    Text {
                        text: root.shell.ramUsedGb + " / " + root.shell.ramTotalGb + " GB (" + root.shell.ramPercent + "%)"
                        color: "#ffffff"
                        font.pixelSize: 11
                        font.bold: true
                    }
                }

                Rectangle {
                    width: parent.width
                    height: 6
                    radius: 3
                    color: Qt.rgba(1, 1, 1, 0.2)

                    Rectangle {
                        width: parent.width * root.shell.ramPercent / 100
                        height: parent.height
                        radius: 3
                        color: root.shell.ramPercent > 90 ? Qt.rgba(0.9, 0.2, 0.2, 0.9)
                             : root.shell.ramPercent > 70 ? Qt.rgba(0.95, 0.5, 0.15, 0.85)
                             : Qt.rgba(0.3, 0.6, 0.9, 0.7)
                        Behavior on width { NumberAnimation { duration: 300 } }
                    }
                }

                Canvas {
                    id: ramGraph
                    visible: root.shell.ramHistoryCount >= 2
                    width: parent.width
                    height: 40

                    property var history: root.shell.ramHistory
                    onHistoryChanged: requestPaint()

                    onPaint: {
                        var ctx = getContext("2d");
                        ctx.clearRect(0, 0, width, height);
                        var h = history;
                        if (h.length < 2) return;
                        var maxPoints = 60;
                        var stepX = width / (maxPoints - 1);
                        var offset = maxPoints - h.length;

                        ctx.strokeStyle = Qt.rgba(1, 1, 1, 0.1);
                        ctx.lineWidth = 0.5;
                        for (var g = 1; g <= 3; g++) {
                            var gy = height - (height * g * 25 / 100);
                            ctx.beginPath();
                            ctx.moveTo(0, gy);
                            ctx.lineTo(width, gy);
                            ctx.stroke();
                        }

                        ctx.fillStyle = Qt.rgba(0.3, 0.6, 0.9, 0.15);
                        ctx.beginPath();
                        for (var i = 0; i < h.length; i++) {
                            var x = (offset + i) * stepX;
                            var y = height - (height * h[i] / 100);
                            if (i === 0) ctx.moveTo(x, y);
                            else ctx.lineTo(x, y);
                        }
                        ctx.lineTo((offset + h.length - 1) * stepX, height);
                        ctx.lineTo(offset * stepX, height);
                        ctx.closePath();
                        ctx.fill();

                        ctx.strokeStyle = Qt.rgba(0.3, 0.6, 0.9, 0.8);
                        ctx.lineWidth = 1.5;
                        ctx.lineJoin = "round";
                        ctx.beginPath();
                        for (var j = 0; j < h.length; j++) {
                            var x2 = (offset + j) * stepX;
                            var y2 = height - (height * h[j] / 100);
                            if (j === 0) ctx.moveTo(x2, y2);
                            else ctx.lineTo(x2, y2);
                        }
                        ctx.stroke();
                    }
                }

                Rectangle { width: parent.width; height: 1; color: Qt.rgba(1, 1, 1, 0.15) }

                // Temperature
                RowLayout {
                    width: parent.width
                    Text {
                        text: "CPU Temperature"
                        color: Qt.rgba(1, 1, 1, 0.7)
                        font.pixelSize: 11
                        Layout.fillWidth: true
                    }
                    Text {
                        text: root.shell.cpuTemp + "\u00b0C"
                        color: root.shell.cpuTemp > 85 ? Qt.rgba(0.9, 0.2, 0.2, 0.9)
                             : root.shell.cpuTemp > 70 ? Qt.rgba(0.95, 0.5, 0.15, 0.85)
                             : "#ffffff"
                        font.pixelSize: 11
                        font.bold: true
                    }
                }

                Rectangle { width: parent.width; height: 1; color: Qt.rgba(1, 1, 1, 0.15) }

                // Disk
                RowLayout {
                    width: parent.width
                    Text {
                        text: "Disk (/)"
                        color: Qt.rgba(1, 1, 1, 0.7)
                        font.pixelSize: 11
                        Layout.fillWidth: true
                    }
                    Text {
                        text: root.shell.diskUsed + " / " + root.shell.diskTotal + " (" + root.shell.diskPercent + "%)"
                        color: "#ffffff"
                        font.pixelSize: 11
                        font.bold: true
                    }
                }

                Rectangle {
                    width: parent.width
                    height: 6
                    radius: 3
                    color: Qt.rgba(1, 1, 1, 0.2)

                    Rectangle {
                        width: parent.width * root.shell.diskPercent / 100
                        height: parent.height
                        radius: 3
                        color: root.shell.diskPercent > 90 ? Qt.rgba(0.9, 0.2, 0.2, 0.9)
                             : root.shell.diskPercent > 80 ? Qt.rgba(0.95, 0.5, 0.15, 0.85)
                             : Qt.rgba(0.6, 0.5, 0.8, 0.7)
                        Behavior on width { NumberAnimation { duration: 300 } }
                    }
                }

                Rectangle { width: parent.width; height: 1; color: Qt.rgba(1, 1, 1, 0.15) }

                // Network
                RowLayout {
                    width: parent.width
                    Text {
                        text: "Network"
                        color: Qt.rgba(1, 1, 1, 0.7)
                        font.pixelSize: 11
                        Layout.fillWidth: true
                    }
                }

                RowLayout {
                    width: parent.width
                    spacing: 8
                    Text {
                        text: "\u2193 " + root.shell.formatBytesPerSec(root.shell.netRxRate)
                        color: Qt.rgba(0.4, 0.8, 0.4, 1.0)
                        font.pixelSize: 11
                        font.bold: true
                        Layout.fillWidth: true
                    }
                    Text {
                        text: "\u2191 " + root.shell.formatBytesPerSec(root.shell.netTxRate)
                        color: Qt.rgba(0.95, 0.6, 0.3, 1.0)
                        font.pixelSize: 11
                        font.bold: true
                        horizontalAlignment: Text.AlignRight
                    }
                }

                Canvas {
                    id: netGraph
                    visible: root.shell.netHistoryCount >= 2
                    width: parent.width
                    height: 40

                    property var rxHistory: root.shell.netRxHistory
                    property var txHistory: root.shell.netTxHistory
                    property real peak: root.shell.netRxPeak
                    onRxHistoryChanged: requestPaint()
                    onTxHistoryChanged: requestPaint()
                    onPeakChanged: requestPaint()

                    onPaint: {
                        var ctx = getContext("2d");
                        ctx.clearRect(0, 0, width, height);
                        var rx = rxHistory;
                        var tx = txHistory;
                        if (rx.length < 2) return;
                        var maxPoints = 60;
                        var stepX = width / (maxPoints - 1);
                        var offset = maxPoints - rx.length;
                        var scale = peak > 0 ? peak : 1;

                        ctx.strokeStyle = Qt.rgba(1, 1, 1, 0.1);
                        ctx.lineWidth = 0.5;
                        for (var g = 1; g <= 3; g++) {
                            var gy = height - (height * g * 25 / 100);
                            ctx.beginPath();
                            ctx.moveTo(0, gy);
                            ctx.lineTo(width, gy);
                            ctx.stroke();
                        }

                        // RX fill + line
                        ctx.fillStyle = Qt.rgba(0.4, 0.8, 0.4, 0.15);
                        ctx.beginPath();
                        for (var i = 0; i < rx.length; i++) {
                            var x = (offset + i) * stepX;
                            var y = height - (height * Math.min(rx[i] / scale, 1));
                            if (i === 0) ctx.moveTo(x, y);
                            else ctx.lineTo(x, y);
                        }
                        ctx.lineTo((offset + rx.length - 1) * stepX, height);
                        ctx.lineTo(offset * stepX, height);
                        ctx.closePath();
                        ctx.fill();

                        ctx.strokeStyle = Qt.rgba(0.4, 0.8, 0.4, 0.9);
                        ctx.lineWidth = 1.5;
                        ctx.lineJoin = "round";
                        ctx.beginPath();
                        for (var j = 0; j < rx.length; j++) {
                            var x2 = (offset + j) * stepX;
                            var y2 = height - (height * Math.min(rx[j] / scale, 1));
                            if (j === 0) ctx.moveTo(x2, y2);
                            else ctx.lineTo(x2, y2);
                        }
                        ctx.stroke();

                        // TX line
                        ctx.strokeStyle = Qt.rgba(0.95, 0.6, 0.3, 0.9);
                        ctx.lineWidth = 1.5;
                        ctx.beginPath();
                        for (var k = 0; k < tx.length; k++) {
                            var x3 = (offset + k) * stepX;
                            var y3 = height - (height * Math.min(tx[k] / scale, 1));
                            if (k === 0) ctx.moveTo(x3, y3);
                            else ctx.lineTo(x3, y3);
                        }
                        ctx.stroke();
                    }
                }
            }
        }
    }
}
