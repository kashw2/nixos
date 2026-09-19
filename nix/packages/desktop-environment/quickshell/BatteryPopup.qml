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
        popupName: "battery"

    // Header
    Text {
        text: "Battery"
        color: Theme.text
        font.pixelSize: Theme.fontTitle
        font.bold: true
    }

    // Large percentage
    Text {
        text: root.shell.batteryPercent + "%"
        color: Theme.text
        font.pixelSize: 28
        font.bold: true
        anchors.horizontalCenter: parent.horizontalCenter
    }

    // Status text
    Text {
        text: root.shell.batteryStatus
        color: Theme.textDim
        font.pixelSize: Theme.fontBody
        anchors.horizontalCenter: parent.horizontalCenter
    }

    // Charge bar (read-only)
    Rectangle {
        width: parent.width
        height: 6
        radius: 3
        color: Theme.surfaceStrong

        Rectangle {
            width: parent.width * root.shell.batteryPercent / 100
            height: parent.height
            radius: 3
            color: {
                if (root.shell.batteryCharging) return Qt.rgba(0.4, 0.8, 0.4, 0.7);
                if (root.shell.batteryPercent <= 10) return Qt.rgba(0.9, 0.2, 0.2, 0.9);
                if (root.shell.batteryPercent <= 25) return Qt.rgba(0.95, 0.5, 0.15, 0.85);
                if (root.shell.batteryPercent <= 50) return Qt.rgba(0.95, 0.85, 0.2, 0.8);
                return Qt.rgba(0.4, 0.8, 0.4, 0.7);
            }

            Behavior on width { NumberAnimation { duration: 300 } }
        }
    }

    // Power draw
    RowLayout {
        visible: root.shell.batteryPowerDraw !== ""
        width: parent.width

        Text {
            text: "Power draw"
            color: Theme.textDim
            font.pixelSize: Theme.fontLabel
            Layout.fillWidth: true
        }

        Text {
            text: root.shell.batteryPowerDraw
            color: Theme.textDim
            font.pixelSize: Theme.fontLabel
        }
    }

    SectionSeparator {}

    // Battery health
    RowLayout {
        width: parent.width

        Text {
            text: "Battery Health"
            color: Theme.textDim
            font.pixelSize: Theme.fontLabel
            Layout.fillWidth: true
        }

        Text {
            text: root.shell.batteryHealthPercent + "%"
            color: Theme.textDim
            font.pixelSize: Theme.fontLabel
        }
    }

    SectionSeparator {
        visible: root.shell.batteryHistoryCount >= 2
    }

    // History header
    Text {
        visible: root.shell.batteryHistoryCount >= 2
        text: "Last Hour"
        color: Theme.textDim
        font.pixelSize: Theme.fontLabel
    }

    // Charge history sparkline
    HistoryGraph {
        visible: root.shell.batteryHistoryCount >= 2
        width: parent.width
        height: 60
        history: root.shell.batteryHistory
        maxPoints: 720
        fillArea: false
        lineColor: Theme.textDim
    }
    }
}
