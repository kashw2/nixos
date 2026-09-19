import Quickshell
import QtQuick
import QtQuick.Layouts
import "."

Variants {
    id: root
    required property var shell
    model: Quickshell.screens

    BasePopup {
        shell: root.shell
        popupName: "overflow"
        popupWidth: 200
        spacing: 4

    Text {
        text: "More"
        color: Theme.text
        font.pixelSize: Theme.fontTitle
        font.bold: true
    }

    Repeater {
        model: [
            { id: "sysMon", label: "System Monitor", visible: true },
            { id: "brightness", label: "Brightness", visible: root.shell.hasBrightness }
        ]

        Rectangle {
            id: row
            required property var modelData
            property bool hovered: false

            visible: modelData.visible
            width: parent.width
            height: 32
            radius: 6
            color: hovered ? Theme.buttonHover : "transparent"

            Behavior on color { ColorAnimation { duration: Theme.animFast } }

            Row {
                anchors.verticalCenter: parent.verticalCenter
                anchors.left: parent.left
                anchors.leftMargin: 8
                spacing: 10

                Item {
                    width: 14
                    height: 14
                    anchors.verticalCenter: parent.verticalCenter

                    SysMonIcon {
                        anchors.centerIn: parent
                        visible: row.modelData.id === "sysMon"
                        cpuHistory: root.shell.cpuHistory
                        ramHistory: root.shell.ramHistory
                        netHistory: root.shell.netTotalHistory
                    }

                    BrightnessIcon {
                        anchors.centerIn: parent
                        visible: row.modelData.id === "brightness"
                        percent: root.shell.brightnessPercent
                    }
                }

                Text {
                    text: row.modelData.label
                    color: Theme.text
                    font.pixelSize: Theme.fontBody
                    anchors.verticalCenter: parent.verticalCenter
                }
            }

            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onEntered: row.hovered = true
                onExited: row.hovered = false
                onClicked: root.shell.openPopup(row.modelData.id, root.shell.activePopupScreen)
            }
        }
    }
    }
}
