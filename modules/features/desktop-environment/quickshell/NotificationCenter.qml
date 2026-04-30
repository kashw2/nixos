import Quickshell
import QtQuick
import QtQuick.Layouts
import "."

Variants {
    id: root
    required property var shell
    model: Quickshell.screens

    BasePopup {
        id: popup
        shell: root.shell
        popupName: "notif"
        popupWidth: 340
        maxImplicitHeight: 480

        property var notifGroups: {
            var groups = [];
            var seen = ({});
            var hist = root.shell.notifHistory;
            for (var i = 0; i < hist.length; i++) {
                var n = hist[i];
                var key = n.appName || "Unknown";
                var entry = {
                    appName: n.appName || "Unknown",
                    summary: n.summary,
                    body: n.body,
                    appIcon: n.appIcon,
                    image: n.image,
                    time: n.time,
                    flatIndex: i
                };
                if (seen.hasOwnProperty(key)) {
                    groups[seen[key]].notifications.push(entry);
                } else {
                    seen[key] = groups.length;
                    groups.push({ appName: key, notifications: [entry] });
                }
            }
            return groups;
        }

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

        Rectangle {
            width: parent.width
            height: 1
            color: Theme.surfaceSubtle
        }

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

        Flickable {
            visible: root.shell.notifCount > 0
            width: parent.width
            height: Math.min(contentHeight, 380)
            contentHeight: notifList.implicitHeight
            clip: true

            Column {
                id: notifList
                width: parent.width
                spacing: 12

                Repeater {
                    model: popup.notifGroups

                    delegate: Item {
                        id: groupItem
                        required property var modelData

                        property bool isExpanded: root.shell.notifExpandedGroups.indexOf(modelData.appName) !== -1
                        property int notifCount: modelData.notifications.length
                        property int peekVisible: Math.min(notifCount - 1, 2)
                        property int peekOffset: 6

                        width: notifList.width
                        implicitHeight: isExpanded
                            ? expandedCol.implicitHeight
                            : (topCard.implicitHeight + peekVisible * peekOffset)

                        Behavior on implicitHeight {
                            NumberAnimation { duration: 180; easing.type: Easing.OutCubic }
                        }

                        // Peek cards behind top
                        Repeater {
                            model: groupItem.isExpanded ? 0 : groupItem.peekVisible

                            delegate: Rectangle {
                                required property int index
                                property int depth: index + 1
                                anchors.horizontalCenter: parent.horizontalCenter
                                y: depth * groupItem.peekOffset
                                width: parent.width - depth * 14
                                height: topCard.height
                                radius: 8
                                color: Theme.surfaceSubtle
                                z: -depth
                            }
                        }

                        // Top card (collapsed)
                        Rectangle {
                            id: topCard
                            visible: !groupItem.isExpanded
                            anchors {
                                left: parent.left
                                right: parent.right
                                top: parent.top
                            }
                            radius: 8
                            color: groupHover.containsMouse ? Theme.surfaceStrong : Theme.surfaceSubtle
                            implicitHeight: topContent.implicitHeight + 16

                            Behavior on color { ColorAnimation { duration: 150 } }

                            RowLayout {
                                id: topContent
                                anchors {
                                    fill: parent
                                    margins: 8
                                }
                                spacing: 8

                                Image {
                                    source: {
                                        var n = groupItem.modelData.notifications[0];
                                        if (!n) return "";
                                        if ((n.image || "") !== "") return n.image;
                                        if ((n.appIcon || "") !== "") return "image://icon/" + n.appIcon;
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
                                            text: {
                                                var n = groupItem.modelData.notifications[0];
                                                return (groupItem.modelData.appName || "Unknown") + "  \u00b7  " + (n ? (n.time || "") : "");
                                            }
                                            color: Theme.textDim
                                            font.pixelSize: 10
                                            Layout.fillWidth: true
                                            elide: Text.ElideRight
                                        }

                                        Text {
                                            visible: groupItem.notifCount > 1
                                            text: groupItem.notifCount
                                            color: Theme.textDim
                                            font.pixelSize: 10
                                            font.bold: true
                                        }
                                    }

                                    Text {
                                        text: {
                                            var n = groupItem.modelData.notifications[0];
                                            return n ? (n.summary || "") : "";
                                        }
                                        color: Theme.text
                                        font.pixelSize: 12
                                        font.bold: true
                                        width: parent.width
                                        wrapMode: Text.WordWrap
                                        elide: Text.ElideRight
                                        maximumLineCount: 2
                                    }

                                    Text {
                                        visible: {
                                            var n = groupItem.modelData.notifications[0];
                                            return n ? ((n.body || "") !== "") : false;
                                        }
                                        text: {
                                            var n = groupItem.modelData.notifications[0];
                                            return n ? (n.body || "") : "";
                                        }
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
                                id: groupHover
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: groupItem.notifCount > 1 ? Qt.PointingHandCursor : Qt.ArrowCursor
                                onClicked: {
                                    if (groupItem.notifCount > 1) {
                                        root.shell.toggleNotifGroup(groupItem.modelData.appName);
                                    }
                                }
                            }
                        }

                        // Expanded list of notifications in this group
                        Column {
                            id: expandedCol
                            visible: groupItem.isExpanded
                            anchors {
                                left: parent.left
                                right: parent.right
                                top: parent.top
                            }
                            spacing: 4

                            Repeater {
                                model: groupItem.modelData.notifications

                                delegate: Rectangle {
                                    id: notifCard
                                    required property var modelData
                                    width: expandedCol.width
                                    radius: 8
                                    color: itemHover.containsMouse ? Theme.surfaceStrong : Theme.surfaceSubtle
                                    implicitHeight: itemContent.implicitHeight + 16

                                    Behavior on color { ColorAnimation { duration: 150 } }

                                    RowLayout {
                                        id: itemContent
                                        anchors {
                                            fill: parent
                                            margins: 8
                                        }
                                        spacing: 8

                                        Image {
                                            source: {
                                                if ((notifCard.modelData.image || "") !== "") return notifCard.modelData.image;
                                                if ((notifCard.modelData.appIcon || "") !== "") return "image://icon/" + notifCard.modelData.appIcon;
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
                                                    text: (notifCard.modelData.appName || "Unknown") + "  \u00b7  " + (notifCard.modelData.time || "")
                                                    color: Theme.textDim
                                                    font.pixelSize: 10
                                                    Layout.fillWidth: true
                                                    elide: Text.ElideRight
                                                }

                                                Rectangle {
                                                    Layout.preferredWidth: 16
                                                    Layout.preferredHeight: 16
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
                                                        onClicked: root.shell.dismissNotification(notifCard.modelData.flatIndex)
                                                    }
                                                }
                                            }

                                            Text {
                                                text: notifCard.modelData.summary || ""
                                                color: Theme.text
                                                font.pixelSize: 12
                                                font.bold: true
                                                width: parent.width
                                                wrapMode: Text.WordWrap
                                                elide: Text.ElideRight
                                                maximumLineCount: 2
                                            }

                                            Text {
                                                visible: (notifCard.modelData.body || "") !== ""
                                                text: notifCard.modelData.body || ""
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
                                        id: itemHover
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        z: -1
                                    }
                                }
                            }

                            Rectangle {
                                visible: groupItem.notifCount > 1
                                width: parent.width
                                height: 22
                                radius: 11
                                color: collapseHover.containsMouse ? Theme.surfaceStrong : Theme.surfaceSubtle

                                Text {
                                    anchors.centerIn: parent
                                    text: "Show less"
                                    color: Theme.textDim
                                    font.pixelSize: 10
                                }

                                MouseArea {
                                    id: collapseHover
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.shell.toggleNotifGroup(groupItem.modelData.appName)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
