import Quickshell
import Quickshell.Networking
import QtQuick
import QtQuick.Layouts
import "."

Variants {
    id: root
    required property var shell
    model: Quickshell.screens

    BasePopup {
        shell: root.shell
        popupName: "wifi"

        onCleared: {
            root.shell.selectedNetworkName = "";
            root.shell.passwordInput = "";
            root.shell.eapIdentityInput = "";
            root.shell.eapPasswordInput = "";
            root.shell.eapError = "";
            root.shell.eapConnecting = false;
        }

    // WiFi toggle
    Rectangle {
        width: parent.width
        height: 32
        radius: 6
        color: wifiToggleHover.containsMouse ? Theme.buttonHover : "transparent"

        Behavior on color { ColorAnimation { duration: 150 } }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 10
            anchors.rightMargin: 10

            Text {
                text: "WiFi"
                color: Theme.text
                font.pixelSize: 13
                font.bold: true
                Layout.fillWidth: true
            }

            ToggleSwitch {
                active: Networking.wifiEnabled
                onClicked: Networking.wifiEnabled = !Networking.wifiEnabled
            }
        }

        MouseArea {
            id: wifiToggleHover
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: Networking.wifiEnabled = !Networking.wifiEnabled
        }
    }

    // Separator
    Rectangle {
        width: parent.width
        height: 1
        color: Theme.surfaceSubtle
    }

    // Ethernet connected section
    Text {
        text: "Ethernet"
        color: Theme.textDim
        font.pixelSize: 11
        font.bold: true
        visible: root.shell.ethernetConnected
    }

    Rectangle {
        visible: root.shell.ethernetConnected
        width: parent.width
        height: 36
        radius: 6
        color: ethHover.containsMouse ? Theme.surfaceActive : Theme.surfaceBg

        Behavior on color { ColorAnimation { duration: 150 } }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 10
            anchors.rightMargin: 10
            spacing: 8

            Text {
                text: root.shell.ethernetInterface ? root.shell.ethernetInterface : "Ethernet"
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
            id: ethHover
            anchors.fill: parent
            hoverEnabled: true
        }
    }

    // Separator
    Rectangle {
        visible: root.shell.ethernetConnected
        width: parent.width
        height: 1
        color: Theme.surfaceSubtle
    }

    // WiFi connected section
    Text {
        text: "Connected"
        color: Theme.textDim
        font.pixelSize: 11
        font.bold: true
        visible: Networking.wifiEnabled && root.shell.connectedNetwork !== null
    }

    Rectangle {
        visible: Networking.wifiEnabled && root.shell.connectedNetwork !== null
        width: parent.width
        height: 36
        radius: 6
        color: currentNetHover.containsMouse ? Theme.surfaceActive : Theme.surfaceBg

        Behavior on color { ColorAnimation { duration: 150 } }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 10
            anchors.rightMargin: 10
            spacing: 8

            Text {
                text: root.shell.connectedNetwork ? root.shell.connectedNetwork.name : ""
                color: Theme.text
                font.pixelSize: 13
                font.bold: true
                Layout.fillWidth: true
            }

            Text {
                text: root.shell.connectedNetwork ? Math.round(root.shell.connectedNetwork.signalStrength * 100) + "%" : ""
                color: Theme.textDim
                font.pixelSize: 11
            }
        }

        MouseArea {
            id: currentNetHover
            anchors.fill: parent
            hoverEnabled: true
        }
    }

    // Separator
    Rectangle {
        visible: Networking.wifiEnabled && root.shell.connectedNetwork !== null
        width: parent.width
        height: 1
        color: Theme.surfaceSubtle
    }

    // Available networks header
    Text {
        text: "Available"
        color: Theme.textDim
        font.pixelSize: 11
        font.bold: true
        visible: Networking.wifiEnabled
    }

    // Network list
    Flickable {
        visible: Networking.wifiEnabled
        width: parent.width
        height: Math.min(contentHeight, 250)
        contentHeight: networkColumn.implicitHeight
        clip: true

        Column {
            id: networkColumn
            width: parent.width
            spacing: 2

            Repeater {
                model: root.shell.wifiDev ? root.shell.wifiDev.networks : []

                delegate: Column {
                    required property var modelData
                    width: networkColumn.width
                    visible: !modelData.connected

                    Rectangle {
                        id: netItem
                        property bool hovered: false
                        property bool isSelected: root.shell.selectedNetworkName === modelData.name

                        width: parent.width
                        height: 36
                        radius: 6
                        color: hovered ? Theme.surfaceBg
                            : isSelected ? Theme.surfaceSubtle
                            : "transparent"

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
                                visible: modelData.security !== WifiSecurityType.None && !modelData.known
                                text: "\ud83d\udd12"
                                font.pixelSize: 10
                            }

                            Text {
                                text: Math.round(modelData.signalStrength * 100) + "%"
                                color: Theme.textDim
                                font.pixelSize: 11
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onEntered: netItem.hovered = true
                            onExited: netItem.hovered = false
                            onClicked: {
                                if (modelData.known) {
                                    modelData.connect();
                                    root.shell.closePopup();
                                } else if (modelData.security === WifiSecurityType.WpaEap || modelData.security === WifiSecurityType.Wpa2Eap) {
                                    root.shell.selectedNetworkName = modelData.name;
                                    root.shell.eapIdentityInput = "";
                                    root.shell.eapPasswordInput = "";
                                    root.shell.eapError = "";
                                    root.shell.eapConnecting = false;
                                    eapIdentityField.forceActiveFocus();
                                } else {
                                    root.shell.selectedNetworkName = modelData.name;
                                    root.shell.passwordInput = "";
                                    pskField.forceActiveFocus();
                                }
                            }
                        }
                    }

                    // Password input row
                    Rectangle {
                        visible: root.shell.selectedNetworkName === modelData.name && !modelData.known && modelData.security !== WifiSecurityType.WpaEap && modelData.security !== WifiSecurityType.Wpa2Eap
                        width: parent.width
                        height: visible ? 36 : 0
                        radius: 6
                        color: Theme.surfaceSubtle

                        Behavior on height { NumberAnimation { duration: 150 } }

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 10
                            anchors.rightMargin: 10
                            spacing: 6

                            Rectangle {
                                Layout.fillWidth: true
                                height: 24
                                radius: 4
                                color: Theme.surfaceInner

                                TextInput {
                                    id: pskField
                                    anchors.fill: parent
                                    anchors.leftMargin: 6
                                    anchors.rightMargin: 6
                                    verticalAlignment: TextInput.AlignVCenter
                                    color: Theme.text
                                    font.pixelSize: 12
                                    echoMode: TextInput.Password
                                    clip: true
                                    onTextChanged: root.shell.passwordInput = text
                                    Keys.onReturnPressed: {
                                        if (root.shell.passwordInput.length > 0) {
                                            modelData.connectWithPsk(root.shell.passwordInput);
                                            root.shell.selectedNetworkName = "";
                                            root.shell.passwordInput = "";
                                            root.shell.closePopup();
                                        }
                                    }
                                }
                            }

                            Rectangle {
                                width: 56
                                height: 24
                                radius: 4
                                color: connectHover.containsMouse ? Theme.surfaceActive : Theme.surfaceBg

                                Behavior on color { ColorAnimation { duration: 150 } }

                                Text {
                                    anchors.centerIn: parent
                                    text: "Connect"
                                    color: Theme.text
                                    font.pixelSize: 11
                                }

                                MouseArea {
                                    id: connectHover
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        if (root.shell.passwordInput.length > 0) {
                                            modelData.connectWithPsk(root.shell.passwordInput);
                                            root.shell.selectedNetworkName = "";
                                            root.shell.passwordInput = "";
                                            root.shell.closePopup();
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // EAP credentials form
                    Rectangle {
                        visible: root.shell.selectedNetworkName === modelData.name && !modelData.known && (modelData.security === WifiSecurityType.WpaEap || modelData.security === WifiSecurityType.Wpa2Eap)
                        width: parent.width
                        height: visible ? eapColumn.implicitHeight + 16 : 0
                        radius: 6
                        color: Theme.surfaceSubtle
                        clip: true

                        Behavior on height { NumberAnimation { duration: 150 } }

                        Column {
                            id: eapColumn
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.top: parent.top
                            anchors.margins: 8
                            spacing: 6

                            // Identity/username field
                            Rectangle {
                                width: parent.width
                                height: 24
                                radius: 4
                                color: Theme.surfaceInner

                                TextInput {
                                    id: eapIdentityField
                                    anchors.fill: parent
                                    anchors.leftMargin: 6
                                    anchors.rightMargin: 6
                                    verticalAlignment: TextInput.AlignVCenter
                                    color: Theme.text
                                    font.pixelSize: 12
                                    clip: true
                                    onTextChanged: root.shell.eapIdentityInput = text

                                    Text {
                                        anchors.fill: parent
                                        verticalAlignment: Text.AlignVCenter
                                        text: "Identity"
                                        color: Theme.textDim
                                        font.pixelSize: 12
                                        visible: !eapIdentityField.text && !eapIdentityField.activeFocus
                                    }

                                    Keys.onReturnPressed: eapPasswordField.forceActiveFocus()
                                }
                            }

                            // Password field
                            Rectangle {
                                width: parent.width
                                height: 24
                                radius: 4
                                color: Theme.surfaceInner

                                TextInput {
                                    id: eapPasswordField
                                    anchors.fill: parent
                                    anchors.leftMargin: 6
                                    anchors.rightMargin: 6
                                    verticalAlignment: TextInput.AlignVCenter
                                    color: Theme.text
                                    font.pixelSize: 12
                                    echoMode: TextInput.Password
                                    clip: true
                                    onTextChanged: root.shell.eapPasswordInput = text

                                    Text {
                                        anchors.fill: parent
                                        verticalAlignment: Text.AlignVCenter
                                        text: "Password"
                                        color: Theme.textDim
                                        font.pixelSize: 12
                                        visible: !eapPasswordField.text && !eapPasswordField.activeFocus
                                    }

                                    Keys.onReturnPressed: {
                                        if (root.shell.eapIdentityInput.length > 0 && root.shell.eapPasswordInput.length > 0 && !root.shell.eapConnecting) {
                                            root.shell.eapConnecting = true;
                                            root.shell.eapError = "";
                                            root.shell.startEapConnection(modelData.name, root.shell.eapIdentityInput, root.shell.eapPasswordInput);
                                        }
                                    }
                                }
                            }

                            // Connect button and status row
                            RowLayout {
                                width: parent.width
                                spacing: 6

                                Text {
                                    visible: root.shell.eapConnecting
                                    text: "Connecting..."
                                    color: Theme.textDim
                                    font.pixelSize: 11
                                    Layout.fillWidth: true
                                }

                                Text {
                                    visible: root.shell.eapError !== "" && !root.shell.eapConnecting
                                    text: root.shell.eapError
                                    color: "#ff6b6b"
                                    font.pixelSize: 11
                                    Layout.fillWidth: true
                                }

                                Item {
                                    visible: !root.shell.eapConnecting && root.shell.eapError === ""
                                    Layout.fillWidth: true
                                }

                                Rectangle {
                                    width: 56
                                    height: 24
                                    radius: 4
                                    color: eapConnectHover.containsMouse ? Theme.surfaceActive : Theme.surfaceBg
                                    opacity: root.shell.eapConnecting ? 0.5 : 1.0

                                    Behavior on color { ColorAnimation { duration: 150 } }

                                    Text {
                                        anchors.centerIn: parent
                                        text: "Connect"
                                        color: Theme.text
                                        font.pixelSize: 11
                                    }

                                    MouseArea {
                                        id: eapConnectHover
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: root.shell.eapConnecting ? Qt.BusyCursor : Qt.PointingHandCursor
                                        onClicked: {
                                            if (root.shell.eapIdentityInput.length > 0 && root.shell.eapPasswordInput.length > 0 && !root.shell.eapConnecting) {
                                                root.shell.eapConnecting = true;
                                                root.shell.eapError = "";
                                                root.shell.startEapConnection(modelData.name, root.shell.eapIdentityInput, root.shell.eapPasswordInput);
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // WiFi disabled message
    Text {
        visible: root.shell.wifiDev !== null && !Networking.wifiEnabled
        text: "WiFi is disabled"
        color: Theme.textDim
        font.pixelSize: 12
    }

    // No wifi device message
    Text {
        visible: root.shell.wifiDev === null
        text: "No WiFi adapter found"
        color: Theme.textDim
        font.pixelSize: 12
    }
    }
}
