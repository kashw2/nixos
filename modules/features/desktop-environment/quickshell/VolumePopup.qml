import Quickshell
import Quickshell.Hyprland
import QtQuick
import QtQuick.Layouts

Variants {
    id: root
    required property var shell

    model: Quickshell.screens

    PanelWindow {
        id: volumePopupWindow
        required property var modelData
        screen: modelData

        visible: root.shell.volumePopupOpen && root.shell.volumePopupScreen === modelData

        HyprlandFocusGrab {
            active: root.shell.volumePopupOpen && root.shell.volumePopupScreen === modelData
            windows: [volumePopupWindow]
            onCleared: {
                root.shell.volumePopupOpen = false;
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
        implicitWidth: 240
        implicitHeight: volumePopupContent.implicitHeight + 24
        exclusionMode: ExclusionMode.Ignore
        color: "transparent"

        Rectangle {
            anchors.fill: parent
            radius: 12
            color: Qt.rgba(1, 1, 1, 0.3)
            clip: true

            Column {
                id: volumePopupContent
                anchors {
                    fill: parent
                    margins: 12
                }
                spacing: 8

                // Header with mute toggle
                RowLayout {
                    width: parent.width

                    Text {
                        text: "Volume"
                        color: "#ffffff"
                        font.pixelSize: 13
                        font.bold: true
                        Layout.fillWidth: true
                    }

                    Rectangle {
                        width: 36
                        height: 20
                        radius: 10
                        color: !root.shell.volumeMuted ? Qt.rgba(0.4, 0.8, 0.4, 0.6) : Qt.rgba(1, 1, 1, 0.3)

                        Behavior on color { ColorAnimation { duration: 200 } }

                        Rectangle {
                            width: 16
                            height: 16
                            radius: 8
                            y: 2
                            x: !root.shell.volumeMuted ? parent.width - width - 2 : 2
                            color: "#ffffff"

                            Behavior on x { NumberAnimation { duration: 200; easing.type: Easing.InOutQuad } }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.shell.toggleVolumeMute()
                        }
                    }
                }

                RowLayout {
                    width: parent.width
                    spacing: 10

                    // Speaker icon (quiet)
                    Canvas {
                        width: 12
                        height: 12
                        Layout.alignment: Qt.AlignVCenter

                        onPaint: {
                            var ctx = getContext("2d");
                            ctx.clearRect(0, 0, width, height);
                            ctx.fillStyle = Qt.rgba(1, 1, 1, 0.6);
                            ctx.beginPath();
                            ctx.moveTo(1, 4);
                            ctx.lineTo(3, 4);
                            ctx.lineTo(5.5, 1.5);
                            ctx.lineTo(5.5, 10.5);
                            ctx.lineTo(3, 8);
                            ctx.lineTo(1, 8);
                            ctx.closePath();
                            ctx.fill();
                        }
                    }

                    // Slider track
                    Rectangle {
                        Layout.fillWidth: true
                        height: 6
                        radius: 3
                        color: Qt.rgba(1, 1, 1, 0.2)
                        Layout.alignment: Qt.AlignVCenter

                        Rectangle {
                            width: parent.width * Math.min(root.shell.volumePercent, 100) / 100
                            height: parent.height
                            radius: 3
                            color: root.shell.volumeMuted ? Qt.rgba(1, 1, 1, 0.3) : Qt.rgba(1, 1, 1, 0.7)

                            Behavior on width { NumberAnimation { duration: 100 } }
                        }

                        // Slider handle
                        Rectangle {
                            x: parent.width * Math.min(root.shell.volumePercent, 100) / 100 - 7
                            y: -4
                            width: 14
                            height: 14
                            radius: 7
                            color: "#ffffff"

                            Behavior on x { NumberAnimation { duration: 100 } }
                        }

                        MouseArea {
                            anchors.fill: parent
                            anchors.topMargin: -8
                            anchors.bottomMargin: -8
                            cursorShape: Qt.PointingHandCursor

                            function updateVolume(mouse) {
                                var pct = Math.max(0, Math.min(100, Math.round(mouse.x / width * 100)));
                                root.shell.volumePercent = pct;
                                root.shell.setVolume(pct);
                            }

                            onPressed: mouse => updateVolume(mouse)
                            onPositionChanged: mouse => {
                                if (pressed) updateVolume(mouse);
                            }
                        }
                    }

                    // Speaker icon (loud)
                    Canvas {
                        width: 14
                        height: 14
                        Layout.alignment: Qt.AlignVCenter

                        onPaint: {
                            var ctx = getContext("2d");
                            ctx.clearRect(0, 0, width, height);
                            ctx.fillStyle = "#ffffff";
                            ctx.lineWidth = 1.2;
                            ctx.lineCap = "round";
                            ctx.beginPath();
                            ctx.moveTo(0, 5);
                            ctx.lineTo(2.5, 5);
                            ctx.lineTo(5, 2);
                            ctx.lineTo(5, 12);
                            ctx.lineTo(2.5, 9);
                            ctx.lineTo(0, 9);
                            ctx.closePath();
                            ctx.fill();
                            ctx.strokeStyle = "#ffffff";
                            ctx.beginPath();
                            ctx.arc(5.5, 7, 3.5, -Math.PI / 4, Math.PI / 4);
                            ctx.stroke();
                            ctx.beginPath();
                            ctx.arc(5.5, 7, 6, -Math.PI / 4, Math.PI / 4);
                            ctx.stroke();
                        }
                    }
                }

                // Percentage label
                Text {
                    text: root.shell.volumePercent + "%"
                    color: Qt.rgba(1, 1, 1, 0.7)
                    font.pixelSize: 11
                    anchors.horizontalCenter: parent.horizontalCenter
                }

                // Separator
                Rectangle {
                    width: parent.width
                    height: 1
                    color: Qt.rgba(1, 1, 1, 0.15)
                }

                // Mic header with mute toggle
                RowLayout {
                    width: parent.width

                    Text {
                        text: "Microphone"
                        color: "#ffffff"
                        font.pixelSize: 13
                        font.bold: true
                        Layout.fillWidth: true
                    }

                    Rectangle {
                        width: 36
                        height: 20
                        radius: 10
                        color: !root.shell.micMuted ? Qt.rgba(0.4, 0.8, 0.4, 0.6) : Qt.rgba(1, 1, 1, 0.3)

                        Behavior on color { ColorAnimation { duration: 200 } }

                        Rectangle {
                            width: 16
                            height: 16
                            radius: 8
                            y: 2
                            x: !root.shell.micMuted ? parent.width - width - 2 : 2
                            color: "#ffffff"

                            Behavior on x { NumberAnimation { duration: 200; easing.type: Easing.InOutQuad } }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.shell.toggleMicMute()
                        }
                    }
                }

                RowLayout {
                    width: parent.width
                    spacing: 10

                    // Mic icon (quiet)
                    Canvas {
                        width: 12
                        height: 12
                        Layout.alignment: Qt.AlignVCenter

                        onPaint: {
                            var ctx = getContext("2d");
                            ctx.clearRect(0, 0, width, height);
                            ctx.fillStyle = Qt.rgba(1, 1, 1, 0.6);
                            ctx.beginPath();
                            ctx.roundedRect(4, 0, 4, 7, 2, 2);
                            ctx.fill();
                            ctx.strokeStyle = Qt.rgba(1, 1, 1, 0.6);
                            ctx.lineWidth = 1.2;
                            ctx.lineCap = "round";
                            ctx.beginPath();
                            ctx.arc(6, 6, 4, Math.PI, 0);
                            ctx.stroke();
                            ctx.beginPath();
                            ctx.moveTo(6, 10);
                            ctx.lineTo(6, 12);
                            ctx.stroke();
                        }
                    }

                    // Mic slider track
                    Rectangle {
                        Layout.fillWidth: true
                        height: 6
                        radius: 3
                        color: Qt.rgba(1, 1, 1, 0.2)
                        Layout.alignment: Qt.AlignVCenter

                        Rectangle {
                            width: parent.width * Math.min(root.shell.micGainPercent, 100) / 100
                            height: parent.height
                            radius: 3
                            color: root.shell.micMuted ? Qt.rgba(1, 1, 1, 0.3) : Qt.rgba(1, 1, 1, 0.7)

                            Behavior on width { NumberAnimation { duration: 100 } }
                        }

                        Rectangle {
                            x: parent.width * Math.min(root.shell.micGainPercent, 100) / 100 - 7
                            y: -4
                            width: 14
                            height: 14
                            radius: 7
                            color: "#ffffff"

                            Behavior on x { NumberAnimation { duration: 100 } }
                        }

                        MouseArea {
                            anchors.fill: parent
                            anchors.topMargin: -8
                            anchors.bottomMargin: -8
                            cursorShape: Qt.PointingHandCursor

                            function updateGain(mouse) {
                                var pct = Math.max(0, Math.min(100, Math.round(mouse.x / width * 100)));
                                root.shell.micGainPercent = pct;
                                root.shell.setMicGain(pct);
                            }

                            onPressed: mouse => updateGain(mouse)
                            onPositionChanged: mouse => {
                                if (pressed) updateGain(mouse);
                            }
                        }
                    }

                    // Mic icon (loud)
                    Canvas {
                        width: 14
                        height: 14
                        Layout.alignment: Qt.AlignVCenter

                        onPaint: {
                            var ctx = getContext("2d");
                            ctx.clearRect(0, 0, width, height);
                            ctx.fillStyle = "#ffffff";
                            ctx.beginPath();
                            ctx.roundedRect(4.5, 0, 5, 7, 2.5, 2.5);
                            ctx.fill();
                            ctx.strokeStyle = "#ffffff";
                            ctx.lineWidth = 1.3;
                            ctx.lineCap = "round";
                            ctx.beginPath();
                            ctx.arc(7, 6, 5, Math.PI, 0);
                            ctx.stroke();
                            ctx.beginPath();
                            ctx.moveTo(7, 11);
                            ctx.lineTo(7, 13.5);
                            ctx.stroke();
                            ctx.beginPath();
                            ctx.moveTo(4, 13.5);
                            ctx.lineTo(10, 13.5);
                            ctx.stroke();
                        }
                    }
                }

                // Mic percentage label
                Text {
                    text: root.shell.micGainPercent + "%"
                    color: Qt.rgba(1, 1, 1, 0.7)
                    font.pixelSize: 11
                    anchors.horizontalCenter: parent.horizontalCenter
                }
            }
        }
    }
}
