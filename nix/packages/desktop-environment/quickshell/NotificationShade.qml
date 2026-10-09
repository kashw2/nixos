import Quickshell
import Quickshell.Hyprland
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "."

Variants {
    id: root
    required property var shell
    model: Quickshell.screens

    PanelWindow {
        id: shadeWindow
        required property var modelData
        screen: modelData

        readonly property bool isOnThisScreen: root.shell.activePopup === "notifshade"
            && root.shell.activePopupScreen === modelData

        property string searchText: ""

        readonly property var matches: {
            var list = root.shell.notifHistory;
            var q = searchText.trim().toLowerCase();
            if (q === "") return list;
            var out = [];
            for (var i = 0; i < list.length; i++) {
                var n = list[i];
                if ((n.appName || "").toLowerCase().indexOf(q) !== -1
                    || (n.summary || "").toLowerCase().indexOf(q) !== -1
                    || (n.body || "").toLowerCase().indexOf(q) !== -1) {
                    out.push(n);
                }
            }
            return out;
        }

        visible: isOnThisScreen || backdrop.opacity > 0.01

        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }
        exclusionMode: ExclusionMode.Ignore
        focusable: true
        color: "transparent"

        HyprlandFocusGrab {
            active: shadeWindow.isOnThisScreen
            windows: [shadeWindow]
            onCleared: root.shell.closePopup()
        }

        onIsOnThisScreenChanged: {
            if (isOnThisScreen) {
                searchText = "";
                searchInput.text = "";
                searchInput.forceActiveFocus();
            }
        }

        Item {
            id: keyHandler
            anchors.fill: parent
            focus: true
            Keys.onEscapePressed: root.shell.closePopup()
        }

        Item {
            id: backdrop
            anchors.fill: parent
            opacity: shadeWindow.isOnThisScreen ? 1 : 0

            Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }

            MouseArea {
                anchors.fill: parent
                onClicked: root.shell.closePopup()
            }
        }

        Rectangle {
            id: sheet

            readonly property int padding: 16
            readonly property int cornerRadius: 16
            readonly property int edgeMargin: 40
            readonly property real listCap: Math.max(120, shadeWindow.height * 0.45
                - padding * 2 - header.implicitHeight - content.spacing * 2 - 1)
            readonly property real sheetHeight: Math.min(content.implicitHeight + padding * 2,
                shadeWindow.height * 0.45)

            anchors {
                horizontalCenter: parent.horizontalCenter
                bottom: parent.bottom
                bottomMargin: edgeMargin
            }
            width: Math.min(parent.width - 80, 1100)
            height: sheetHeight
            radius: cornerRadius
            color: Theme.surfaceBg
            border.width: 1
            border.color: Theme.hairline
            clip: true

            Behavior on height {
                enabled: shadeWindow.isOnThisScreen
                NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
            }

            transform: Translate {
                y: shadeWindow.isOnThisScreen ? 0 : sheet.height + sheet.edgeMargin
                Behavior on y { NumberAnimation { duration: 260; easing.type: Easing.OutCubic } }
            }

            MouseArea {
                anchors.fill: parent
            }

            Rectangle {
                anchors.top: parent.top
                anchors.topMargin: 1
                anchors.horizontalCenter: parent.horizontalCenter
                width: parent.width - 24
                height: 1
                color: Theme.hairlineTop
            }

            Column {
                id: content
                anchors {
                    left: parent.left
                    right: parent.right
                    top: parent.top
                    margins: sheet.padding
                }
                spacing: 10

                RowLayout {
                    id: header
                    width: content.width

                    Text {
                        text: "Notifications"
                        color: Theme.text
                        font.pixelSize: Theme.fontTitle + 2
                        font.bold: true
                    }

                    Text {
                        visible: root.shell.notifCount > 0
                        text: shadeWindow.matches.length
                        color: Theme.textDim
                        font.pixelSize: Theme.fontLabel
                        Layout.alignment: Qt.AlignVCenter
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.leftMargin: 6
                        implicitHeight: 26
                        radius: 6
                        color: Theme.surfaceInner

                        TextInput {
                            id: searchInput
                            anchors {
                                fill: parent
                                leftMargin: 8
                                rightMargin: 8
                            }
                            verticalAlignment: TextInput.AlignVCenter
                            color: Theme.text
                            font.pixelSize: Theme.fontBody
                            clip: true
                            focus: shadeWindow.isOnThisScreen
                            onTextChanged: shadeWindow.searchText = text
                            Keys.onEscapePressed: root.shell.closePopup()

                            Text {
                                anchors.fill: parent
                                verticalAlignment: Text.AlignVCenter
                                text: "Search notifications"
                                color: Theme.textDim
                                font.pixelSize: Theme.fontBody
                                visible: searchInput.text === ""
                            }
                        }
                    }

                    Rectangle {
                        visible: root.shell.notifCount > 0
                        width: clearText.implicitWidth + 16
                        height: 24
                        radius: 4
                        color: clearHover.containsMouse ? Theme.surfaceBg : Theme.surfaceInner

                        Behavior on color { ColorAnimation { duration: Theme.animFast } }

                        Text {
                            id: clearText
                            anchors.centerIn: parent
                            text: "Clear all"
                            color: Theme.text
                            font.pixelSize: Theme.fontLabel
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

                SectionSeparator { color: Theme.surfaceSubtle }

                Text {
                    visible: shadeWindow.matches.length === 0
                    text: root.shell.notifCount === 0 ? "No notifications" : "No matching notifications"
                    color: Theme.iconDim
                    font.pixelSize: Theme.fontBody
                    width: parent.width
                    horizontalAlignment: Text.AlignHCenter
                    topPadding: 28
                    bottomPadding: 28
                }

                Flickable {
                    ScrollBar.vertical: ThinScrollBar {}
                    visible: shadeWindow.matches.length > 0
                    width: parent.width
                    height: Math.min(contentHeight, sheet.listCap)
                    contentHeight: shadeList.implicitHeight
                    clip: true

                    Column {
                        id: shadeList
                        width: parent.width
                        spacing: 6

                        Repeater {
                            model: shadeWindow.matches

                            NotificationItem {
                                width: shadeList.width
                                onDismissed: {
                                    var i = root.shell.notifHistory.indexOf(modelData);
                                    if (i >= 0) root.shell.dismissNotification(i);
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
