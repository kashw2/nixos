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
        id: overflowWindow
        required property var modelData
        screen: modelData

        visible: root.shell.overflowPopupOpen && root.shell.overflowPopupScreen === modelData

        HyprlandFocusGrab {
            active: root.shell.overflowPopupOpen && root.shell.overflowPopupScreen === modelData
            windows: [overflowWindow]
            onCleared: {
                root.shell.overflowPopupOpen = false;
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

        implicitWidth: 200
        implicitHeight: overflowContent.implicitHeight + 24
        exclusionMode: ExclusionMode.Ignore
        color: "transparent"

        Rectangle {
            anchors.fill: parent
            radius: 12
            color: Theme.surfaceBg
            clip: true

            Column {
                id: overflowContent
                anchors {
                    fill: parent
                    margins: 12
                }
                spacing: 4

                Text {
                    text: "More"
                    color: Theme.text
                    font.pixelSize: 13
                    font.bold: true
                }

                Repeater {
                    model: [
                        { id: "sysMon", label: "System Monitor", visible: true },
                        { id: "brightness", label: "Brightness", visible: root.shell.hasBrightness }
                    ]

                    Rectangle {
                        id: row
                        required property var modelData
                        property bool hovered: false

                        visible: modelData.visible
                        width: overflowContent.width
                        height: 32
                        radius: 6
                        color: hovered ? Theme.buttonHover : "transparent"

                        Behavior on color { ColorAnimation { duration: 150 } }

                        Row {
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.left: parent.left
                            anchors.leftMargin: 8
                            spacing: 10

                            Canvas {
                                width: 14
                                height: 14
                                anchors.verticalCenter: parent.verticalCenter

                                property string iconId: row.modelData.id
                                property color stroke: Theme.iconPrimary
                                onStrokeChanged: requestPaint()

                                onPaint: {
                                    var ctx = getContext("2d");
                                    ctx.clearRect(0, 0, width, height);
                                    ctx.strokeStyle = stroke;
                                    ctx.fillStyle = stroke;
                                    ctx.lineWidth = 1.4;
                                    ctx.lineCap = "round";
                                    ctx.lineJoin = "round";

                                    if (iconId === "sysMon") {
                                        ctx.beginPath();
                                        ctx.roundedRect(0.5, 0.5, 13, 10, 1.5, 1.5);
                                        ctx.stroke();
                                        ctx.beginPath();
                                        ctx.moveTo(5, 11.5);
                                        ctx.lineTo(9, 11.5);
                                        ctx.stroke();
                                        ctx.beginPath();
                                        ctx.moveTo(7, 10.5);
                                        ctx.lineTo(7, 11.5);
                                        ctx.stroke();
                                        ctx.lineWidth = 1.2;
                                        ctx.beginPath();
                                        ctx.moveTo(2, 7);
                                        ctx.lineTo(4, 7);
                                        ctx.lineTo(5.5, 3);
                                        ctx.lineTo(7, 8);
                                        ctx.lineTo(8.5, 4);
                                        ctx.lineTo(10, 7);
                                        ctx.lineTo(12, 7);
                                        ctx.stroke();
                                    } else if (iconId === "brightness") {
                                        var cx = 7, cy = 7, r = 3;
                                        ctx.beginPath();
                                        ctx.arc(cx, cy, r, 0, 2 * Math.PI);
                                        ctx.stroke();
                                        for (var i = 0; i < 8; i++) {
                                            var a = i * Math.PI / 4;
                                            ctx.beginPath();
                                            ctx.moveTo(cx + Math.cos(a) * (r + 1.5), cy + Math.sin(a) * (r + 1.5));
                                            ctx.lineTo(cx + Math.cos(a) * (r + 3), cy + Math.sin(a) * (r + 3));
                                            ctx.stroke();
                                        }
                                    }
                                }
                            }

                            Text {
                                text: row.modelData.label
                                color: Theme.text
                                font.pixelSize: 12
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onEntered: row.hovered = true
                            onExited: row.hovered = false
                            onClicked: {
                                var screen = root.shell.overflowPopupScreen;
                                root.shell.overflowPopupOpen = false;
                                if (row.modelData.id === "sysMon") {
                                    root.shell.sysMonPopupScreen = screen;
                                    root.shell.sysMonPopupOpen = true;
                                } else if (row.modelData.id === "brightness") {
                                    root.shell.brightnessPopupScreen = screen;
                                    root.shell.brightnessPopupOpen = true;
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
