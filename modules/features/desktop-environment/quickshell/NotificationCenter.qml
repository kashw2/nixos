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
        id: notifPopupWindow
        required property var modelData
        screen: modelData

        visible: root.shell.notifPopupOpen && root.shell.notifPopupScreen === modelData

        HyprlandFocusGrab {
            active: root.shell.notifPopupOpen && root.shell.notifPopupScreen === modelData
            windows: [notifPopupWindow]
            onCleared: {
                root.shell.notifPopupOpen = false;
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
        implicitWidth: 320
        implicitHeight: Math.min(notifPopupContent.implicitHeight + 24, 460)
        exclusionMode: ExclusionMode.Ignore
        color: "transparent"

        Rectangle {
            anchors.fill: parent
            radius: 12
            color: Theme.surfaceBg
            clip: true

            Column {
                id: notifPopupContent
                anchors {
                    fill: parent
                    margins: 12
                }
                spacing: 8

                // Header
                RowLayout {
                    width: parent.width

                    Text {
                        text: "Notifications"
                        color: Theme.text
                        font.pixelSize: 13
                        font.bold: true
                        Layout.fillWidth: true
                    }

                    // Clear all button
                    Rectangle {
                        visible: root.shell.notifCount > 0
                        width: clearText.implicitWidth + 12
                        height: 20
                        radius: 4
                        color: clearHover.containsMouse ? Theme.surfaceBg : Theme.surfaceInner

                        Behavior on color { ColorAnimation { duration: 150 } }

                        Text {
                            id: clearText
                            anchors.centerIn: parent
                            text: "Clear all"
                            color: Theme.text
                            font.pixelSize: 11
                        }

                        MouseArea {
                            id: clearHover
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.shell.clearNotifications()
                        }
                    }
                }

                // Separator
                Rectangle {
                    width: parent.width
                    height: 1
                    color: Theme.surfaceSubtle
                }

                // Empty state
                Text {
                    visible: root.shell.notifCount === 0
                    text: "No notifications"
                    color: Theme.iconDim
                    font.pixelSize: 12
                    width: parent.width
                    horizontalAlignment: Text.AlignHCenter
                    topPadding: 20
                    bottomPadding: 20
                }

                // Notification list
                Flickable {
                    visible: root.shell.notifCount > 0
                    width: parent.width
                    height: Math.min(contentHeight, 360)
                    contentHeight: notifList.implicitHeight
                    clip: true

                    Column {
                        id: notifList
                        width: parent.width
                        spacing: 6

                        Repeater {
                            model: root.shell.notifHistory

                            Rectangle {
                                id: notifItem
                                required property var modelData
                                required property int index
                                property bool hovered: false
                                width: notifList.width
                                implicitHeight: notifItemContent.implicitHeight + 16
                                radius: 8
                                color: hovered ? Theme.surfaceStrong : Theme.surfaceSubtle

                                Behavior on color { ColorAnimation { duration: 150 } }

                                RowLayout {
                                    id: notifItemContent
                                    anchors {
                                        fill: parent
                                        margins: 8
                                    }
                                    spacing: 8

                                    Image {
                                        source: {
                                            if (modelData.image !== "") return modelData.image;
                                            if (modelData.appIcon !== "") return "image://icon/" + modelData.appIcon;
                                            return "";
                                        }
                                        visible: source !== ""
                                        Layout.preferredWidth: 32
                                        Layout.preferredHeight: 32
                                        Layout.alignment: Qt.AlignTop
                                        sourceSize.width: 32
                                        sourceSize.height: 32
                                    }

                                    Column {
                                        Layout.fillWidth: true
                                        spacing: 4

                                        RowLayout {
                                            width: parent.width

                                            Text {
                                                text: modelData.appName + "  \u00b7  " + modelData.time
                                                color: Theme.textDim
                                                font.pixelSize: 10
                                                Layout.fillWidth: true
                                                elide: Text.ElideRight
                                            }

                                            // Dismiss button
                                            Rectangle {
                                                width: 16
                                                height: 16
                                                radius: 8
                                                color: dismissHover.containsMouse ? Theme.surfaceBg : "transparent"

                                                Text {
                                                    anchors.centerIn: parent
                                                    text: "\u00d7"
                                                    color: Theme.textDim
                                                    font.pixelSize: 12
                                                }

                                                MouseArea {
                                                    id: dismissHover
                                                    anchors.fill: parent
                                                    hoverEnabled: true
                                                    cursorShape: Qt.PointingHandCursor
                                                    onClicked: root.shell.dismissNotification(notifItem.index)
                                                }
                                            }
                                        }

                                        Text {
                                            text: modelData.summary
                                            color: Theme.text
                                            font.pixelSize: 12
                                            font.bold: true
                                            width: parent.width
                                            wrapMode: Text.WordWrap
                                            elide: Text.ElideRight
                                            maximumLineCount: 2
                                        }

                                        Text {
                                            visible: modelData.body !== ""
                                            text: modelData.body
                                            color: Theme.textDim
                                            font.pixelSize: 11
                                            width: parent.width
                                            wrapMode: Text.WordWrap
                                            elide: Text.ElideRight
                                            maximumLineCount: 3
                                        }
                                    }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    z: -1
                                    onEntered: notifItem.hovered = true
                                    onExited: notifItem.hovered = false
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
