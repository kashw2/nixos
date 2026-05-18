import Quickshell
import Quickshell.Services.Mpris
import QtQuick
import QtQuick.Layouts
import "."

Variants {
    id: root
    required property var shell
    model: Quickshell.screens

    function fmtTime(seconds) {
        if (!seconds || seconds < 0 || isNaN(seconds)) return "0:00";
        var m = Math.floor(seconds / 60);
        var s = Math.floor(seconds % 60);
        return m + ":" + (s < 10 ? "0" : "") + s;
    }

    BasePopup {
        id: popup
        shell: root.shell
        popupName: "media"
        popupWidth: 380

        anchors.right: false
        anchors.left: true
        margins.right: 0
        margins.left: popup.screen ? Math.max(8, (popup.screen.width - popup.popupWidth) / 2) : 8

        readonly property var player: root.shell.mprisPlayer
        readonly property bool hasPlayer: player !== null
        readonly property bool isPlaying: hasPlayer && player.isPlaying
        readonly property var allPlayers: Mpris.players ? Mpris.players.values : []

        // Re-poll position 5x/sec while popup is open so the scrubber animates smoothly.
        Timer {
            interval: 200
            running: popup.visible && popup.isPlaying
            repeat: true
            onTriggered: if (popup.player) popup.player.positionChanged()
        }

        // Header
        Item {
            width: parent.width
            height: 18

            Text {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                text: "Now playing"
                color: Theme.text
                font.pixelSize: 13
                font.bold: true
            }

            Text {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                visible: popup.hasPlayer
                text: popup.player ? popup.player.identity : ""
                color: Theme.textDim
                font.pixelSize: 11
                elide: Text.ElideRight
            }
        }

        // Empty state
        Text {
            visible: !popup.hasPlayer
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            text: "No media playing"
            color: Theme.textDim
            font.pixelSize: 12
        }

        // Now-playing card
        RowLayout {
            visible: popup.hasPlayer
            width: parent.width
            spacing: 12

            // Album art (or fallback glyph)
            Rectangle {
                Layout.preferredWidth: 96
                Layout.preferredHeight: 96
                radius: 8
                color: Theme.surfaceInner
                clip: true

                Image {
                    anchors.fill: parent
                    visible: popup.player && popup.player.trackArtUrl !== ""
                    source: popup.player ? popup.player.trackArtUrl : ""
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    cache: true
                }

                MediaPlayerIcon {
                    anchors.centerIn: parent
                    visible: !popup.player || popup.player.trackArtUrl === ""
                    iconSize: 48
                    iconType: !popup.hasPlayer ? "stopped"
                        : popup.isPlaying ? "playing" : "paused"
                    iconColor: Theme.iconDim
                    animTime: popup.player ? Date.now() / 250 : 0
                }
            }

            // Track metadata
            ColumnLayout {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter
                spacing: 2

                Text {
                    Layout.fillWidth: true
                    text: popup.player && popup.player.trackTitle !== "" ? popup.player.trackTitle : "Unknown title"
                    color: Theme.text
                    font.pixelSize: 14
                    font.bold: true
                    elide: Text.ElideRight
                }

                Text {
                    Layout.fillWidth: true
                    visible: popup.player && popup.player.trackArtist !== ""
                    text: popup.player ? popup.player.trackArtist : ""
                    color: Theme.textDim
                    font.pixelSize: 12
                    elide: Text.ElideRight
                }

                Text {
                    Layout.fillWidth: true
                    visible: popup.player && popup.player.trackAlbum !== ""
                    text: popup.player ? popup.player.trackAlbum : ""
                    color: Theme.textDim
                    font.pixelSize: 11
                    elide: Text.ElideRight
                }
            }
        }

        // Scrubber
        RowLayout {
            visible: popup.hasPlayer
            width: parent.width
            spacing: 8

            Text {
                text: popup.player ? root.fmtTime(popup.player.position) : "0:00"
                color: Theme.textDim
                font.pixelSize: 10
                Layout.preferredWidth: 36
                horizontalAlignment: Text.AlignRight
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter
                height: 6
                radius: 3
                color: Theme.surfaceStrong

                readonly property real progress: {
                    if (!popup.player) return 0;
                    if (!popup.player.length || popup.player.length <= 0) return 0;
                    return Math.max(0, Math.min(1, popup.player.position / popup.player.length));
                }

                Rectangle {
                    width: parent.width * parent.progress
                    height: parent.height
                    radius: 3
                    color: Theme.iconPrimary
                }

                Rectangle {
                    x: parent.width * parent.progress - 6
                    y: -3
                    width: 12
                    height: 12
                    radius: 6
                    color: Theme.iconPrimary
                    visible: popup.player && popup.player.canSeek
                }

                MouseArea {
                    anchors.fill: parent
                    anchors.topMargin: -8
                    anchors.bottomMargin: -8
                    cursorShape: popup.player && popup.player.canSeek ? Qt.PointingHandCursor : Qt.ArrowCursor
                    enabled: popup.player && popup.player.canSeek
                    onClicked: function(mouse) {
                        if (!popup.player || !popup.player.length) return;
                        var frac = Math.max(0, Math.min(1, mouse.x / width));
                        popup.player.position = frac * popup.player.length;
                    }
                }
            }

            Text {
                text: popup.player ? root.fmtTime(popup.player.length) : "0:00"
                color: Theme.textDim
                font.pixelSize: 10
                Layout.preferredWidth: 36
            }
        }

        // Transport controls
        RowLayout {
            visible: popup.hasPlayer
            width: parent.width
            spacing: 16

            Item { Layout.fillWidth: true }

            BarButton {
                implicitWidth: 34
                implicitHeight: 28
                enabled: popup.player && popup.player.canGoPrevious
                opacity: enabled ? 1.0 : 0.4
                onClicked: if (popup.player) popup.player.previous()

                Canvas {
                    anchors.centerIn: parent
                    width: 14
                    height: 14
                    onPaint: {
                        var ctx = getContext("2d");
                        ctx.clearRect(0, 0, width, height);
                        ctx.fillStyle = Theme.iconPrimary;
                        ctx.beginPath();
                        ctx.moveTo(11, 2);
                        ctx.lineTo(11, 12);
                        ctx.lineTo(5, 7);
                        ctx.closePath();
                        ctx.fill();
                        ctx.fillRect(3, 2, 1.5, 10);
                    }
                }
            }

            BarButton {
                implicitWidth: 44
                implicitHeight: 32
                enabled: popup.player !== null && popup.player.canTogglePlaying
                onClicked: if (popup.player) popup.player.togglePlaying()

                Canvas {
                    anchors.centerIn: parent
                    width: 16
                    height: 16
                    property bool playing: popup.isPlaying
                    onPlayingChanged: requestPaint()
                    onPaint: {
                        var ctx = getContext("2d");
                        ctx.clearRect(0, 0, width, height);
                        ctx.fillStyle = Theme.iconPrimary;
                        if (playing) {
                            ctx.fillRect(3, 2, 3, 12);
                            ctx.fillRect(10, 2, 3, 12);
                        } else {
                            ctx.beginPath();
                            ctx.moveTo(4, 2);
                            ctx.lineTo(14, 8);
                            ctx.lineTo(4, 14);
                            ctx.closePath();
                            ctx.fill();
                        }
                    }
                }
            }

            BarButton {
                implicitWidth: 34
                implicitHeight: 28
                enabled: popup.player && popup.player.canGoNext
                opacity: enabled ? 1.0 : 0.4
                onClicked: if (popup.player) popup.player.next()

                Canvas {
                    anchors.centerIn: parent
                    width: 14
                    height: 14
                    onPaint: {
                        var ctx = getContext("2d");
                        ctx.clearRect(0, 0, width, height);
                        ctx.fillStyle = Theme.iconPrimary;
                        ctx.beginPath();
                        ctx.moveTo(3, 2);
                        ctx.lineTo(3, 12);
                        ctx.lineTo(9, 7);
                        ctx.closePath();
                        ctx.fill();
                        ctx.fillRect(9.5, 2, 1.5, 10);
                    }
                }
            }

            Item { Layout.fillWidth: true }
        }

        // Source switcher: visible only when 2+ players are present
        Item {
            width: parent.width
            height: sourceFlow.implicitHeight
            visible: popup.allPlayers.length > 1

            Flow {
                id: sourceFlow
                width: parent.width
                spacing: 6

                Repeater {
                    model: popup.allPlayers

                    Rectangle {
                        id: chip
                        required property var modelData
                        readonly property bool isActive: popup.player && popup.player.dbusName === chip.modelData.dbusName

                        implicitWidth: chipLabel.implicitWidth + 16
                        implicitHeight: 22
                        radius: 11
                        color: chip.isActive ? Theme.surfaceActive : Theme.surfaceInner
                        border.color: Theme.surfaceSubtle
                        border.width: 1

                        Text {
                            id: chipLabel
                            anchors.centerIn: parent
                            text: chip.modelData.identity !== "" ? chip.modelData.identity : "Player"
                            color: chip.isActive ? Theme.text : Theme.textDim
                            font.pixelSize: 11
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.shell.preferredMprisPlayerDbusName = chip.modelData.dbusName
                        }
                    }
                }
            }
        }
    }
}
