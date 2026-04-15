import Quickshell
import QtQuick
import QtQuick.Layouts

Variants {
    required property var shell

    model: Quickshell.screens

    PanelWindow {
        id: toastWindow
        required property var modelData
        screen: modelData

        visible: shell.toastVisible && shell.toastNotification !== null && !shell.notifPopupOpen

        anchors {
            top: true
            right: true
        }
        margins {
            top: 38
            right: 8
        }
        implicitWidth: 300
        implicitHeight: toastContent.implicitHeight + 24
        exclusionMode: ExclusionMode.Ignore
        color: "transparent"

        Rectangle {
            anchors.fill: parent
            radius: 12
            color: Qt.rgba(1, 1, 1, 0.3)
            clip: true

            RowLayout {
                id: toastContent
                anchors {
                    fill: parent
                    margins: 12
                }
                spacing: 8

                Image {
                    source: {
                        if (!shell.toastNotification) return "";
                        if ((shell.toastNotification.image || "") !== "") return shell.toastNotification.image;
                        if ((shell.toastNotification.appIcon || "") !== "") return "image://icon/" + shell.toastNotification.appIcon;
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
                            text: shell.toastNotification ? (shell.toastNotification.appName || "Notification") : ""
                            color: Qt.rgba(1, 1, 1, 0.6)
                            font.pixelSize: 10
                            Layout.fillWidth: true
                            elide: Text.ElideRight
                        }

                        Rectangle {
                            width: 16
                            height: 16
                            radius: 8
                            color: toastDismissHover.containsMouse ? Qt.rgba(1, 1, 1, 0.3) : "transparent"

                            Text {
                                anchors.centerIn: parent
                                text: "\u00d7"
                                color: Qt.rgba(1, 1, 1, 0.7)
                                font.pixelSize: 12
                            }

                            MouseArea {
                                id: toastDismissHover
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: shell.toastVisible = false
                            }
                        }
                    }

                    Text {
                        text: shell.toastNotification ? (shell.toastNotification.summary || "") : ""
                        color: "#ffffff"
                        font.pixelSize: 12
                        font.bold: true
                        width: parent.width
                        wrapMode: Text.WordWrap
                        elide: Text.ElideRight
                        maximumLineCount: 2
                    }

                    Text {
                        visible: shell.toastNotification ? ((shell.toastNotification.body || "") !== "") : false
                        text: shell.toastNotification ? (shell.toastNotification.body || "") : ""
                        color: Qt.rgba(1, 1, 1, 0.7)
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
                z: -1
                onClicked: {
                    shell.toastVisible = false;
                    shell.notifPopupScreen = toastWindow.modelData;
                    shell.notifPopupOpen = true;
                }
            }
        }
    }
}
