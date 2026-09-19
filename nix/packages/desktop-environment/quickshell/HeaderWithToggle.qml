import QtQuick
import QtQuick.Layouts
import "."

Rectangle {
    id: root

    property string title
    property bool active: false
    signal toggled()

    width: parent.width
    height: 32
    radius: 6
    color: hoverArea.containsMouse ? Theme.buttonHover : "transparent"

    Behavior on color { ColorAnimation { duration: Theme.animFast } }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 10
        anchors.rightMargin: 10

        Text {
            text: root.title
            color: Theme.text
            font.pixelSize: Theme.fontTitle
            font.bold: true
            Layout.fillWidth: true
        }

        ToggleSwitch {
            active: root.active
            onClicked: root.toggled()
        }
    }

    MouseArea {
        id: hoverArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.toggled()
    }
}
