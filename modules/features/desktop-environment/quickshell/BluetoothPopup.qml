import Quickshell
import Quickshell.Hyprland
import QtQuick
import QtQuick.Layouts

Variants {
    id: root
    required property var shell

    model: Quickshell.screens

    PanelWindow {
        id: btPopupWindow
        required property var modelData
        screen: modelData

        visible: root.shell.btPopupOpen && root.shell.btPopupScreen === modelData

        HyprlandFocusGrab {
            active: root.shell.btPopupOpen && root.shell.btPopupScreen === modelData
            windows: [btPopupWindow]
            onCleared: {
                root.shell.btPopupOpen = false;
            }
        }
        anchors {
            top: true
            right: true
        }
        margins {
            top: 38
            right: 8
        }
        implicitWidth: 280
        implicitHeight: btPopupContent.implicitHeight + 24
        exclusionMode: ExclusionMode.Ignore
        color: "transparent"

        Rectangle {
            anchors.fill: parent
            radius: 12
            color: Qt.rgba(1, 1, 1, 0.3)
            clip: true

            Column {
                id: btPopupContent
                anchors {
                    fill: parent
                    margins: 12
                }
                spacing: 8

                // Bluetooth toggle
                Rectangle {
                    width: parent.width
                    height: 32
                    radius: 6
                    color: btToggleHover.containsMouse ? Qt.rgba(1, 1, 1, 0.3) : "transparent"

                    Behavior on color { ColorAnimation { duration: 150 } }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 10
                        anchors.rightMargin: 10

                        Text {
                            text: "Bluetooth"
                            color: "#ffffff"
                            font.pixelSize: 13
                            font.bold: true
                            Layout.fillWidth: true
                        }

                        Rectangle {
                            width: 36
                            height: 20
                            radius: 10
                            color: root.shell.bluetoothPowered ? Qt.rgba(0.4, 0.8, 0.4, 0.6) : Qt.rgba(1, 1, 1, 0.3)

                            Behavior on color { ColorAnimation { duration: 200 } }

                            Rectangle {
                                width: 16
                                height: 16
                                radius: 8
                                y: 2
                                x: root.shell.bluetoothPowered ? parent.width - width - 2 : 2
                                color: "#ffffff"

                                Behavior on x { NumberAnimation { duration: 200; easing.type: Easing.InOutQuad } }
                            }
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
                    color: Qt.rgba(1, 1, 1, 0.1)
                }

                // Connected devices header
                Text {
                    text: "Connected"
                    color: Qt.rgba(1, 1, 1, 0.6)
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
                        width: btPopupContent.width
                        height: 36
                        radius: 6
                        color: hovered ? Qt.rgba(1, 1, 1, 0.4) : Qt.rgba(1, 1, 1, 0.3)

                        Behavior on color { ColorAnimation { duration: 150 } }

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 10
                            anchors.rightMargin: 10
                            spacing: 8

                            Text {
                                text: modelData.name
                                color: "#ffffff"
                                font.pixelSize: 13
                                font.bold: true
                                Layout.fillWidth: true
                            }

                            Text {
                                text: "Connected"
                                color: Qt.rgba(1, 1, 1, 0.7)
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
                    color: Qt.rgba(1, 1, 1, 0.1)
                }

                // Paired devices header
                Text {
                    text: "Paired"
                    color: Qt.rgba(1, 1, 1, 0.6)
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
                                color: hovered ? Qt.rgba(1, 1, 1, 0.3) : "transparent"

                                Behavior on color { ColorAnimation { duration: 150 } }

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 10
                                    anchors.rightMargin: 10
                                    spacing: 8

                                    Text {
                                        text: modelData.name
                                        color: "#ffffff"
                                        font.pixelSize: 13
                                        Layout.fillWidth: true
                                    }

                                    Text {
                                        text: "Paired"
                                        color: Qt.rgba(1, 1, 1, 0.5)
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
                    color: Qt.rgba(1, 1, 1, 0.1)
                }

                // Available devices header
                RowLayout {
                    width: parent.width
                    visible: root.shell.bluetoothPowered
                    spacing: 6

                    Text {
                        text: "Available"
                        color: Qt.rgba(1, 1, 1, 0.6)
                        font.pixelSize: 11
                        font.bold: true
                        Layout.fillWidth: true
                    }

                    Text {
                        text: root.shell.btScanning ? "Scanning…" : ""
                        color: Qt.rgba(1, 1, 1, 0.4)
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
                                color: hovered ? Qt.rgba(1, 1, 1, 0.3) : "transparent"

                                Behavior on color { ColorAnimation { duration: 150 } }

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 10
                                    anchors.rightMargin: 10
                                    spacing: 8

                                    Text {
                                        text: modelData.name
                                        color: "#ffffff"
                                        font.pixelSize: 13
                                        elide: Text.ElideRight
                                        Layout.fillWidth: true
                                    }

                                    Text {
                                        text: "Pair"
                                        color: Qt.rgba(1, 1, 1, 0.5)
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
                            color: Qt.rgba(1, 1, 1, 0.4)
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
                    color: Qt.rgba(1, 1, 1, 0.5)
                    font.pixelSize: 12
                }
            }
        }
    }
}
