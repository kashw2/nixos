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
        popupName: "bt"

    // Bluetooth toggle
    Rectangle {
        width: parent.width
        height: 32
        radius: 6
        color: btToggleHover.containsMouse ? Theme.buttonHover : "transparent"

        Behavior on color { ColorAnimation { duration: 150 } }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 10
            anchors.rightMargin: 10

            Text {
                text: "Bluetooth"
                color: Theme.text
                font.pixelSize: 13
                font.bold: true
                Layout.fillWidth: true
            }

            ToggleSwitch {
                active: root.shell.bluetoothPowered
                onClicked: root.shell.toggleBluetooth()
            }
        }

        MouseArea {
            id: btToggleHover
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.shell.toggleBluetooth()
        }
    }

    // Separator
    Rectangle {
        width: parent.width
        height: 1
        color: Theme.surfaceSubtle
    }

    // Connected devices header
    Text {
        text: "Connected"
        color: Theme.textDim
        font.pixelSize: 11
        font.bold: true
        visible: root.shell.bluetoothPowered && root.shell.btConnectedDevices.length > 0
    }

    // Connected devices list
    Repeater {
        model: root.shell.bluetoothPowered ? root.shell.btPairedDevices : []

        delegate: Rectangle {
            required property var modelData
            property bool isConnected: root.shell.btConnectedDevices.indexOf(modelData.mac) !== -1
            property bool hovered: false

            visible: isConnected
            width: parent.width
            height: 36
            radius: 6
            color: hovered ? Theme.surfaceActive : Theme.surfaceBg

            Behavior on color { ColorAnimation { duration: 150 } }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 10
                anchors.rightMargin: 10
                spacing: 8

                Text {
                    text: modelData.name
                    color: Theme.text
                    font.pixelSize: 13
                    font.bold: true
                    Layout.fillWidth: true
                }

                Text {
                    text: "Connected"
                    color: Theme.textDim
                    font.pixelSize: 11
                }
            }

            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onEntered: parent.hovered = true
                onExited: parent.hovered = false
                onClicked: root.shell.disconnectBluetoothDevice(modelData.mac)
            }
        }
    }

    // Separator between connected and paired
    Rectangle {
        visible: root.shell.bluetoothPowered && root.shell.btConnectedDevices.length > 0
        width: parent.width
        height: 1
        color: Theme.surfaceSubtle
    }

    // Paired devices header
    Text {
        text: "Paired"
        color: Theme.textDim
        font.pixelSize: 11
        font.bold: true
        visible: root.shell.bluetoothPowered && root.shell.btPairedDevices.length > 0
    }

    // Paired devices list
    Flickable {
        visible: root.shell.bluetoothPowered
        width: parent.width
        height: Math.min(contentHeight, 250)
        contentHeight: btDeviceColumn.implicitHeight
        clip: true

        Column {
            id: btDeviceColumn
            width: parent.width
            spacing: 2

            Repeater {
                model: root.shell.btPairedDevices

                delegate: Rectangle {
                    required property var modelData
                    property bool isConnected: root.shell.btConnectedDevices.indexOf(modelData.mac) !== -1
                    property bool hovered: false

                    visible: !isConnected
                    width: btDeviceColumn.width
                    height: 36
                    radius: 6
                    color: hovered ? Theme.buttonHover : "transparent"

                    Behavior on color { ColorAnimation { duration: 150 } }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 10
                        anchors.rightMargin: 10
                        spacing: 8

                        Text {
                            text: modelData.name
                            color: Theme.text
                            font.pixelSize: 13
                            Layout.fillWidth: true
                        }

                        Text {
                            text: "Paired"
                            color: Theme.textDim
                            font.pixelSize: 11
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onEntered: parent.hovered = true
                        onExited: parent.hovered = false
                        onClicked: root.shell.connectBluetoothDevice(modelData.mac)
                    }
                }
            }
        }
    }

    // Separator between paired and available
    Rectangle {
        visible: root.shell.bluetoothPowered && root.shell.btDiscoveredDevices.length > 0
        width: parent.width
        height: 1
        color: Theme.surfaceSubtle
    }

    // Available devices header
    RowLayout {
        width: parent.width
        visible: root.shell.bluetoothPowered
        spacing: 6

        Text {
            text: "Available"
            color: Theme.textDim
            font.pixelSize: 11
            font.bold: true
            Layout.fillWidth: true
        }

        Text {
            text: root.shell.btScanning ? "Scanning…" : ""
            color: Theme.iconDim
            font.pixelSize: 10
            font.italic: true
        }
    }

    // Available (discovered, unpaired) devices list
    Flickable {
        visible: root.shell.bluetoothPowered
        width: parent.width
        height: Math.min(contentHeight, 180)
        contentHeight: btAvailableColumn.implicitHeight
        clip: true

        Column {
            id: btAvailableColumn
            width: parent.width
            spacing: 2

            Repeater {
                model: root.shell.btDiscoveredDevices

                delegate: Rectangle {
                    required property var modelData
                    property bool hovered: false

                    width: btAvailableColumn.width
                    height: 36
                    radius: 6
                    color: hovered ? Theme.buttonHover : "transparent"

                    Behavior on color { ColorAnimation { duration: 150 } }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 10
                        anchors.rightMargin: 10
                        spacing: 8

                        Text {
                            text: modelData.name
                            color: Theme.text
                            font.pixelSize: 13
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }

                        Text {
                            text: "Pair"
                            color: Theme.textDim
                            font.pixelSize: 11
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onEntered: parent.hovered = true
                        onExited: parent.hovered = false
                        onClicked: root.shell.pairBluetoothDevice(modelData.mac)
                    }
                }
            }

            Text {
                visible: root.shell.btDiscoveredDevices.length === 0
                text: root.shell.btScanning ? "Searching for devices…" : "No devices found"
                color: Theme.iconDim
                font.pixelSize: 12
                font.italic: true
                leftPadding: 10
            }
        }
    }

    // Bluetooth off message
    Text {
        visible: !root.shell.bluetoothPowered
        text: "Bluetooth is disabled"
        color: Theme.textDim
        font.pixelSize: 12
    }
    }
}
