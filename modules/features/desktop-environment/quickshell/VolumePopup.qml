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
        popupName: "volume"

    // Header with mute toggle
    RowLayout {
        width: parent.width

        Text {
            text: "Volume"
            color: Theme.text
            font.pixelSize: 13
            font.bold: true
            Layout.fillWidth: true
        }

        ToggleSwitch {
            active: !root.shell.volumeMuted
            onClicked: root.shell.toggleVolumeMute()
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
            property color iconFill: Theme.textDim
            onIconFillChanged: requestPaint()

            onPaint: {
                var ctx = getContext("2d");
                ctx.clearRect(0, 0, width, height);
                ctx.fillStyle = iconFill;
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
            color: Theme.surfaceStrong
            Layout.alignment: Qt.AlignVCenter

            Rectangle {
                width: parent.width * Math.min(root.shell.volumePercent, 100) / 100
                height: parent.height
                radius: 3
                color: root.shell.volumeMuted ? Theme.surfaceBg : Theme.textDim

                Behavior on width { NumberAnimation { duration: 100 } }
            }

            // Slider handle
            Rectangle {
                x: parent.width * Math.min(root.shell.volumePercent, 100) / 100 - 7
                y: -4
                width: 14
                height: 14
                radius: 7
                color: Theme.iconPrimary

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
            property color iconFill: Theme.iconPrimary
            onIconFillChanged: requestPaint()

            onPaint: {
                var ctx = getContext("2d");
                ctx.clearRect(0, 0, width, height);
                ctx.fillStyle = iconFill;
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
                ctx.strokeStyle = iconFill;
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
        color: Theme.textDim
        font.pixelSize: 11
        anchors.horizontalCenter: parent.horizontalCenter
    }

    Column {
        width: parent.width
        spacing: 2
        visible: root.shell.audioSinks.length > 0

        Text {
            text: "Output"
            color: Theme.iconDim
            font.pixelSize: 10
        }

        Repeater {
            model: root.shell.audioSinks

            Rectangle {
                required property var modelData
                width: parent.width
                height: 22
                radius: 4
                color: sinkHover.containsMouse ? Theme.surfaceInner
                     : modelData.isDefault ? Theme.surfaceSubtle
                     : "transparent"

                Row {
                    anchors.fill: parent
                    anchors.leftMargin: 6
                    anchors.rightMargin: 6
                    spacing: 6

                    Rectangle {
                        width: 8
                        height: 8
                        radius: 4
                        color: modelData.isDefault ? Qt.rgba(0.4, 0.85, 0.4, 0.9) : Theme.surfaceStrong
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Text {
                        text: modelData.name
                        color: Theme.text
                        font.pixelSize: 11
                        font.bold: modelData.isDefault
                        elide: Text.ElideRight
                        width: parent.width - 20
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }

                MouseArea {
                    id: sinkHover
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (!modelData.isDefault) root.shell.setDefaultAudioDevice(modelData.id);
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

    // Mic header with mute toggle
    RowLayout {
        width: parent.width

        Text {
            text: "Microphone"
            color: Theme.text
            font.pixelSize: 13
            font.bold: true
            Layout.fillWidth: true
        }

        ToggleSwitch {
            active: !root.shell.micMuted
            onClicked: root.shell.toggleMicMute()
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
            property color iconFill: Theme.textDim
            onIconFillChanged: requestPaint()

            onPaint: {
                var ctx = getContext("2d");
                ctx.clearRect(0, 0, width, height);
                ctx.fillStyle = iconFill;
                ctx.beginPath();
                ctx.roundedRect(4, 0, 4, 7, 2, 2);
                ctx.fill();
                ctx.strokeStyle = iconFill;
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
            color: Theme.surfaceStrong
            Layout.alignment: Qt.AlignVCenter

            Rectangle {
                width: parent.width * Math.min(root.shell.micGainPercent, 100) / 100
                height: parent.height
                radius: 3
                color: root.shell.micMuted ? Theme.surfaceBg : Theme.textDim

                Behavior on width { NumberAnimation { duration: 100 } }
            }

            Rectangle {
                x: parent.width * Math.min(root.shell.micGainPercent, 100) / 100 - 7
                y: -4
                width: 14
                height: 14
                radius: 7
                color: Theme.iconPrimary

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
            property color iconFill: Theme.iconPrimary
            onIconFillChanged: requestPaint()

            onPaint: {
                var ctx = getContext("2d");
                ctx.clearRect(0, 0, width, height);
                ctx.fillStyle = iconFill;
                ctx.beginPath();
                ctx.roundedRect(4.5, 0, 5, 7, 2.5, 2.5);
                ctx.fill();
                ctx.strokeStyle = iconFill;
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
        color: Theme.textDim
        font.pixelSize: 11
        anchors.horizontalCenter: parent.horizontalCenter
    }

    // Mic input level meter — shows that the input source is
    // actually capturing audio. Bars stay dark when muted.
    Item {
        width: parent.width
        height: 14

        Row {
            anchors.centerIn: parent
            spacing: 2

            Repeater {
                model: 20

                Rectangle {
                    required property int index
                    property real threshold: (index + 0.5) / 20
                    property bool active: !root.shell.micMuted && root.shell.micLevel >= threshold

                    width: 7
                    height: index < 10 ? 7 : (index < 16 ? 10 : 13)
                    radius: 1
                    anchors.verticalCenter: parent.verticalCenter
                    color: {
                        if (!active) return Theme.surfaceSubtle;
                        if (threshold > 0.8) return Qt.rgba(0.95, 0.3, 0.3, 0.9);
                        if (threshold > 0.55) return Qt.rgba(0.95, 0.85, 0.2, 0.85);
                        return Qt.rgba(0.4, 0.85, 0.4, 0.85);
                    }
                    Behavior on color { ColorAnimation { duration: 80 } }
                }
            }
        }
    }

    // Caption shown when muted, otherwise show "Input"
    Text {
        text: root.shell.micMuted ? "input muted" : "input level"
        color: Theme.iconDim
        font.pixelSize: 9
        anchors.horizontalCenter: parent.horizontalCenter
    }

    Column {
        width: parent.width
        spacing: 2
        visible: root.shell.audioSources.length > 0

        Text {
            text: "Input"
            color: Theme.iconDim
            font.pixelSize: 10
        }

        Repeater {
            model: root.shell.audioSources

            Rectangle {
                required property var modelData
                width: parent.width
                height: 22
                radius: 4
                color: sourceHover.containsMouse ? Theme.surfaceInner
                     : modelData.isDefault ? Theme.surfaceSubtle
                     : "transparent"

                Row {
                    anchors.fill: parent
                    anchors.leftMargin: 6
                    anchors.rightMargin: 6
                    spacing: 6

                    Rectangle {
                        width: 8
                        height: 8
                        radius: 4
                        color: modelData.isDefault ? Qt.rgba(0.4, 0.85, 0.4, 0.9) : Theme.surfaceStrong
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Text {
                        text: modelData.name
                        color: Theme.text
                        font.pixelSize: 11
                        font.bold: modelData.isDefault
                        elide: Text.ElideRight
                        width: parent.width - 20
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }

                MouseArea {
                    id: sourceHover
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (!modelData.isDefault) root.shell.setDefaultAudioDevice(modelData.id);
                    }
                }
            }
        }
    }
    }
}
