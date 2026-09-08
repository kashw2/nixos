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
        popupName: "sysMon"

    Text {
        text: "System Monitor"
        color: Theme.text
        font.pixelSize: Theme.fontTitle
        font.bold: true
    }

    RowLayout {
        width: parent.width
        Text {
            text: "CPU"
            color: Theme.textDim
            font.pixelSize: Theme.fontLabel
            Layout.fillWidth: true
        }
        Text {
            text: root.shell.cpuPercent + "%"
            color: Theme.text
            font.pixelSize: Theme.fontLabel
            font.bold: true
        }
    }

    Rectangle {
        width: parent.width
        height: 6
        radius: 3
        color: Theme.surfaceStrong

        Rectangle {
            width: parent.width * root.shell.cpuPercent / 100
            height: parent.height
            radius: 3
            color: root.shell.cpuPercent > 90 ? Qt.rgba(0.9, 0.2, 0.2, 0.9)
                 : root.shell.cpuPercent > 70 ? Qt.rgba(0.95, 0.5, 0.15, 0.85)
                 : Qt.rgba(0.4, 0.8, 0.4, 0.7)
            Behavior on width { NumberAnimation { duration: 300 } }
        }
    }

    HistoryGraph {
        visible: root.shell.cpuHistoryCount >= 2
        width: parent.width
        height: 40
        history: root.shell.cpuHistory
        lineColor: Theme.graphCpu
    }

    SectionSeparator {}

    RowLayout {
        width: parent.width
        Text {
            text: "Memory"
            color: Theme.textDim
            font.pixelSize: Theme.fontLabel
            Layout.fillWidth: true
        }
        Text {
            text: root.shell.ramUsedGb + " / " + root.shell.ramTotalGb + " GB (" + root.shell.ramPercent + "%)"
            color: Theme.text
            font.pixelSize: Theme.fontLabel
            font.bold: true
        }
    }

    Rectangle {
        width: parent.width
        height: 6
        radius: 3
        color: Theme.surfaceStrong

        Rectangle {
            width: parent.width * root.shell.ramPercent / 100
            height: parent.height
            radius: 3
            color: root.shell.ramPercent > 90 ? Qt.rgba(0.9, 0.2, 0.2, 0.9)
                 : root.shell.ramPercent > 70 ? Qt.rgba(0.95, 0.5, 0.15, 0.85)
                 : Qt.rgba(0.3, 0.6, 0.9, 0.7)
            Behavior on width { NumberAnimation { duration: 300 } }
        }
    }

    HistoryGraph {
        visible: root.shell.ramHistoryCount >= 2
        width: parent.width
        height: 40
        history: root.shell.ramHistory
        lineColor: Qt.rgba(0.3, 0.6, 0.9, 0.8)
    }

    SectionSeparator {}

    RowLayout {
        width: parent.width
        Text {
            text: "CPU Temperature"
            color: Theme.textDim
            font.pixelSize: Theme.fontLabel
            Layout.fillWidth: true
        }
        Text {
            text: root.shell.cpuTemp + "\u00b0C"
            color: root.shell.cpuTemp > 85 ? Qt.rgba(0.9, 0.2, 0.2, 0.9)
                 : root.shell.cpuTemp > 70 ? Qt.rgba(0.95, 0.5, 0.15, 0.85)
                 : Theme.text
            font.pixelSize: Theme.fontLabel
            font.bold: true
        }
    }

    SectionSeparator {}

    RowLayout {
        width: parent.width
        Text {
            text: "Disk (/)"
            color: Theme.textDim
            font.pixelSize: Theme.fontLabel
            Layout.fillWidth: true
        }
        Text {
            text: root.shell.diskUsed + " / " + root.shell.diskTotal + " (" + root.shell.diskPercent + "%)"
            color: Theme.text
            font.pixelSize: Theme.fontLabel
            font.bold: true
        }
    }

    Rectangle {
        width: parent.width
        height: 6
        radius: 3
        color: Theme.surfaceStrong

        Rectangle {
            width: parent.width * root.shell.diskPercent / 100
            height: parent.height
            radius: 3
            color: root.shell.diskPercent > 90 ? Qt.rgba(0.9, 0.2, 0.2, 0.9)
                 : root.shell.diskPercent > 80 ? Qt.rgba(0.95, 0.5, 0.15, 0.85)
                 : Qt.rgba(0.6, 0.5, 0.8, 0.7)
            Behavior on width { NumberAnimation { duration: 300 } }
        }
    }

    SectionSeparator {}

    RowLayout {
        width: parent.width
        Text {
            text: "Network"
            color: Theme.textDim
            font.pixelSize: Theme.fontLabel
            Layout.fillWidth: true
        }
    }

    RowLayout {
        width: parent.width
        spacing: 8
        Text {
            text: "\u2193 " + root.shell.formatBytesPerSec(root.shell.netRxRate)
            color: Qt.rgba(0.4, 0.8, 0.4, 1.0)
            font.pixelSize: Theme.fontLabel
            font.bold: true
            Layout.fillWidth: true
        }
        Text {
            text: "\u2191 " + root.shell.formatBytesPerSec(root.shell.netTxRate)
            color: Qt.rgba(0.95, 0.6, 0.3, 1.0)
            font.pixelSize: Theme.fontLabel
            font.bold: true
            horizontalAlignment: Text.AlignRight
        }
    }

    HistoryGraph {
        visible: root.shell.netHistoryCount >= 2
        width: parent.width
        height: 40
        history: root.shell.netRxHistory
        secondaryHistory: root.shell.netTxHistory
        maxValue: root.shell.netRxPeak
        lineColor: Qt.rgba(0.4, 0.8, 0.4, 0.9)
        secondaryColor: Qt.rgba(0.95, 0.6, 0.3, 0.9)
    }
    }
}
