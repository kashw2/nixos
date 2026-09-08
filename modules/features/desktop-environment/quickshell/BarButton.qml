import QtQuick
import QtQuick.Layouts
import "."

Rectangle {
    id: root

    property bool active: false
    readonly property alias hovered: mouseArea.containsMouse
    default property alias content: contentItem.data

    property bool pulseArmed: false

    signal clicked()
    signal wheel(int delta)
    signal entered()
    signal exited()

    function pulse() {
        if (root.pulseArmed) pulseAnim.restart();
    }

    implicitHeight: 22
    radius: 4
    color: mouseArea.containsMouse || active ? Theme.buttonHover : "transparent"

    transformOrigin: Item.Center
    scale: mouseArea.pressed ? 0.86 : 1.0

    Behavior on color { ColorAnimation { duration: Theme.animFast } }
    Behavior on scale { NumberAnimation { duration: 160; easing.type: Easing.OutBack; easing.overshoot: 2.6 } }

    Timer {
        interval: 1500
        running: true
        onTriggered: root.pulseArmed = true
    }

    Rectangle {
        id: pulseOverlay
        anchors.fill: parent
        radius: parent.radius
        color: Theme.accent
        opacity: 0

        SequentialAnimation {
            id: pulseAnim
            NumberAnimation { target: pulseOverlay; property: "opacity"; to: 0.45; duration: 90; easing.type: Easing.OutCubic }
            NumberAnimation { target: pulseOverlay; property: "opacity"; to: 0; duration: 340; easing.type: Easing.OutCubic }
        }
    }

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
        onWheel: event => root.wheel(event.angleDelta.y)
    }
}
