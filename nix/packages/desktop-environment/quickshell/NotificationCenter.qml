import Quickshell
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "."

Variants {
    id: root
    required property var shell
    model: Quickshell.screens

    BasePopup {
        shell: root.shell
        popupName: "notif"
        popupWidth: 320
        maxImplicitHeight: 460

    // Header
    RowLayout {
        width: parent.width

        Text {
            text: "Notifications"
            color: Theme.text
            font.pixelSize: Theme.fontTitle
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

    // Empty state
    Text {
        visible: root.shell.notifCount === 0
        text: "No notifications"
        color: Theme.iconDim
        font.pixelSize: Theme.fontBody
        width: parent.width
        horizontalAlignment: Text.AlignHCenter
        topPadding: 20
        bottomPadding: 20
    }

    // Notification list
    Flickable {
        ScrollBar.vertical: ThinScrollBar {}
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

                NotificationItem {
                    width: notifList.width
                    onDismissed: root.shell.dismissNotification(index)
                }
            }
        }
    }
    }
}
