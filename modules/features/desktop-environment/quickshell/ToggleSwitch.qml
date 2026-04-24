import QtQuick
import "."

Rectangle {
    id: root

    property bool active: false
    signal clicked()

    property int trackWidth: 36
    property int trackHeight: 20
    property int knobSize: 16
    property int knobPadding: 2
    property color activeColor: Theme.toggleGreen
    property color inactiveColor: Theme.surfaceBg

    implicitWidth: trackWidth
    implicitHeight: trackHeight
    width: trackWidth
    height: trackHeight
    radius: trackHeight / 2
    color: active ? activeColor : inactiveColor

    Behavior on color { ColorAnimation { duration: 200 } }

    Rectangle {
        id: knob
        width: root.knobSize
        height: root.knobSize
        radius: height / 2
        color: Theme.iconPrimary
        anchors.verticalCenter: parent.verticalCenter
        x: root.active ? root.width - width - root.knobPadding : root.knobPadding

        Behavior on x { NumberAnimation { duration: 200; easing.type: Easing.InOutQuad } }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
