import QtQuick
import "."

Rectangle {
    id: root

    required property var modelData
    signal activated(string deviceId)

    width: parent.width
    height: 22
    radius: 4
    color: hoverArea.containsMouse ? Theme.surfaceInner
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
            color: root.modelData.isDefault ? Qt.rgba(0.4, 0.85, 0.4, 0.9) : Theme.surfaceStrong
            anchors.verticalCenter: parent.verticalCenter
        }

        Text {
            text: root.modelData.name
            color: Theme.text
            font.pixelSize: 11
            font.bold: root.modelData.isDefault
            elide: Text.ElideRight
            width: parent.width - 20
            anchors.verticalCenter: parent.verticalCenter
        }
    }

    MouseArea {
        id: hoverArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            if (!root.modelData.isDefault) root.activated(root.modelData.id);
        }
    }
}
