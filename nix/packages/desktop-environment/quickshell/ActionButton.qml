import QtQuick
import "."

Rectangle {
    id: root

    property string label: ""
    property bool busy: false

    signal clicked()

    width: 56
    height: 24
    radius: 4
    color: hover.containsMouse ? Theme.surfaceActive : Theme.surfaceBg
    opacity: root.busy ? 0.5 : 1.0

    Behavior on color { ColorAnimation { duration: Theme.animFast } }

    Text {
        anchors.centerIn: parent
        text: root.label
        color: Theme.text
        font.pixelSize: Theme.fontLabel
    }

    MouseArea {
        id: hover
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: root.busy ? Qt.BusyCursor : Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
