import Quickshell
import QtQuick
import "."

Variants {
    id: root
    required property var shell

    model: Quickshell.screens

    PanelWindow {
        id: batteryTooltipWindow
        required property var modelData
        screen: modelData

        visible: root.shell.batteryHovered && !root.shell.batteryPopupOpen && root.shell.batteryTimeRemaining !== "" && root.shell.batteryHoveredScreen === modelData

        anchors {
            top: true
            left: true
        }
        margins {
            top: 34
            left: root.shell.batteryIconX + root.shell.batteryIconWidth / 2 - (batteryTooltipText.implicitWidth + 16) / 2
        }
        implicitWidth: batteryTooltipText.implicitWidth + 16
        implicitHeight: batteryTooltipText.implicitHeight + 10
        exclusionMode: ExclusionMode.Ignore
        color: "transparent"

        Rectangle {
            anchors.fill: parent
            radius: 6
            color: Theme.surfaceBg

            Text {
                id: batteryTooltipText
                anchors.centerIn: parent
                text: (root.shell.batteryCharging ? "Full in " : "") + root.shell.batteryTimeRemaining + (root.shell.batteryCharging ? "" : " remaining")
                color: Theme.text
                font.pixelSize: 11
            }
        }
    }
}
