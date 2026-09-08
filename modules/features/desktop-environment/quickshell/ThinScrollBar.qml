import QtQuick
import QtQuick.Controls
import "."

ScrollBar {
    id: root

    policy: ScrollBar.AsNeeded
    padding: 0
    implicitWidth: 4

    contentItem: Rectangle {
        implicitWidth: 4
        radius: 2
        color: Theme.iconPrimary
        opacity: root.pressed ? 0.75
               : root.hovered ? 0.50
               : root.active ? 0.32 : 0.16

        Behavior on opacity { NumberAnimation { duration: Theme.animFast } }
    }

    background: Item {}
}
