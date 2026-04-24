import QtQuick
import QtQuick.Layouts
import "."

Rectangle {
    id: root

    property bool active: false
    readonly property alias hovered: mouseArea.containsMouse
    default property alias content: contentItem.data

    signal clicked()
    signal entered()
    signal exited()

    implicitHeight: 22
    radius: 4
    color: mouseArea.containsMouse || active ? Theme.buttonHover : "transparent"

    Behavior on color { ColorAnimation { duration: 150 } }

    Item {
        id: contentItem
        anchors.fill: parent
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onEntered: root.entered()
        onExited: root.exited()
        onClicked: root.clicked()
    }
}
