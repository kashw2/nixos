import Quickshell
import Quickshell.Hyprland
import QtQuick
import QtQuick.Layouts
import "."

Variants {
    id: root
    required property var shell

    model: Quickshell.screens

    PanelWindow {
        id: batteryPopupWindow
        required property var modelData
        screen: modelData

        visible: root.shell.batteryPopupOpen && root.shell.batteryPopupScreen === modelData

        HyprlandFocusGrab {
            active: root.shell.batteryPopupOpen && root.shell.batteryPopupScreen === modelData
            windows: [batteryPopupWindow]
            onCleared: {
                root.shell.batteryPopupOpen = false;
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
        implicitHeight: batteryPopupContent.implicitHeight + 24
        exclusionMode: ExclusionMode.Ignore
        color: "transparent"

        Rectangle {
            anchors.fill: parent
            radius: 12
            color: Theme.surfaceBg
            clip: true

            Column {
                id: batteryPopupContent
                anchors {
                    fill: parent
                    margins: 12
                }
                spacing: 8

                // Header
                Text {
                    text: "Battery"
                    color: Theme.text
                    font.pixelSize: 13
                    font.bold: true
                }

                // Large percentage
                Text {
                    text: root.shell.batteryPercent + "%"
                    color: Theme.text
                    font.pixelSize: 28
                    font.bold: true
                    anchors.horizontalCenter: parent.horizontalCenter
                }

                // Status text
                Text {
                    text: root.shell.batteryStatus
                    color: Theme.textDim
                    font.pixelSize: 12
                    anchors.horizontalCenter: parent.horizontalCenter
                }

                // Charge bar (read-only)
                Rectangle {
                    width: parent.width
                    height: 6
                    radius: 3
                    color: Theme.surfaceStrong

                    Rectangle {
                        width: parent.width * root.shell.batteryPercent / 100
                        height: parent.height
                        radius: 3
                        color: {
                            if (root.shell.batteryCharging) return Qt.rgba(0.4, 0.8, 0.4, 0.7);
                            if (root.shell.batteryPercent <= 10) return Qt.rgba(0.9, 0.2, 0.2, 0.9);
                            if (root.shell.batteryPercent <= 25) return Qt.rgba(0.95, 0.5, 0.15, 0.85);
                            if (root.shell.batteryPercent <= 50) return Qt.rgba(0.95, 0.85, 0.2, 0.8);
                            return Qt.rgba(0.4, 0.8, 0.4, 0.7);
                        }

                        Behavior on width { NumberAnimation { duration: 300 } }
                    }
                }

                // Power draw
                RowLayout {
                    visible: root.shell.batteryPowerDraw !== ""
                    width: parent.width

                    Text {
                        text: "Power draw"
                        color: Theme.textDim
                        font.pixelSize: 11
                        Layout.fillWidth: true
                    }

                    Text {
                        text: root.shell.batteryPowerDraw
                        color: Theme.textDim
                        font.pixelSize: 11
                    }
                }

                // Separator
                Rectangle {
                    width: parent.width
                    height: 1
                    color: Theme.surfaceInner
                }

                // Power profile
                Text {
                    text: "Power Profile"
                    color: Theme.text
                    font.pixelSize: 13
                    font.bold: true
                }

                Rectangle {
                    width: parent.width
                    height: 28
                    radius: 6
                    color: Theme.surfaceInner

                    Row {
                        anchors.fill: parent
                        anchors.margins: 2

                        Repeater {
                            model: ["power-saver", "balanced", "performance"]

                            Rectangle {
                                required property string modelData
                                required property int index
                                property bool isActive: root.shell.powerProfile === modelData
                                property bool hovered: false

                                width: parent.width / 3
                                height: parent.height
                                radius: 4
                                color: isActive ? Theme.surfaceActive : hovered ? Theme.surfaceInner : "transparent"

                                Behavior on color { ColorAnimation { duration: 150 } }

                                Text {
                                    anchors.centerIn: parent
                                    text: {
                                        if (modelData === "power-saver") return "Saver";
                                        if (modelData === "balanced") return "Balanced";
                                        return "Performance";
                                    }
                                    color: isActive ? Theme.text : Theme.textDim
                                    font.pixelSize: 11
                                    font.bold: isActive
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onEntered: parent.hovered = true
                                    onExited: parent.hovered = false
                                    onClicked: root.shell.setPowerProfile(modelData)
                                }
                            }
                        }
                    }
                }

                // Separator
                Rectangle {
                    width: parent.width
                    height: 1
                    color: Theme.surfaceInner
                }

                // Battery health
                RowLayout {
                    width: parent.width

                    Text {
                        text: "Battery Health"
                        color: Theme.textDim
                        font.pixelSize: 11
                        Layout.fillWidth: true
                    }

                    Text {
                        text: root.shell.batteryHealthPercent + "%"
                        color: Theme.textDim
                        font.pixelSize: 11
                    }
                }

                // Separator
                Rectangle {
                    visible: root.shell.batteryHistoryCount >= 2
                    width: parent.width
                    height: 1
                    color: Theme.surfaceInner
                }

                // History header
                Text {
                    visible: root.shell.batteryHistoryCount >= 2
                    text: "Last Hour"
                    color: Theme.textDim
                    font.pixelSize: 11
                }

                // Charge history sparkline
                Canvas {
                    id: historyGraph
                    visible: root.shell.batteryHistoryCount >= 2
                    width: parent.width
                    height: 60

                    property var history: root.shell.batteryHistory
                    property color gridStroke: Theme.surfaceSubtle
                    property color lineStroke: Theme.textDim
                    onHistoryChanged: requestPaint()
                    onGridStrokeChanged: requestPaint()
                    onLineStrokeChanged: requestPaint()

                    onPaint: {
                        var ctx = getContext("2d");
                        ctx.clearRect(0, 0, width, height);
                        var h = history;
                        if (h.length < 2) return;

                        var maxPoints = 720;
                        var stepX = width / (maxPoints - 1);
                        var offset = maxPoints - h.length;

                        // Grid lines at 25%, 50%, 75%
                        ctx.strokeStyle = gridStroke;
                        ctx.lineWidth = 0.5;
                        for (var g = 1; g <= 3; g++) {
                            var gy = height - (height * g * 25 / 100);
                            ctx.beginPath();
                            ctx.moveTo(0, gy);
                            ctx.lineTo(width, gy);
                            ctx.stroke();
                        }

                        // Sparkline
                        ctx.strokeStyle = lineStroke;
                        ctx.lineWidth = 1.5;
                        ctx.lineJoin = "round";
                        ctx.beginPath();
                        for (var i = 0; i < h.length; i++) {
                            var x = (offset + i) * stepX;
                            var y = height - (height * h[i] / 100);
                            if (i === 0) ctx.moveTo(x, y);
                            else ctx.lineTo(x, y);
                        }
                        ctx.stroke();
                    }
                }
            }
        }
    }
}
