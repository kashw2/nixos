import Quickshell
import Quickshell.Hyprland
import QtQuick
import "."

Variants {
    id: root
    required property var shell

    model: Quickshell.screens

    BasePopup {
        id: popup
        shell: root.shell
        popupName: "power"
        popupWidth: 220
        spacing: 4

        property string pendingAction: ""

        onCleared: pendingAction = ""

        readonly property var actions: [
            { key: "lock",     label: "Lock",      confirm: false },
            { key: "suspend",  label: "Suspend",   confirm: false },
            { key: "logout",   label: "Log out",   confirm: true },
            { key: "reboot",   label: "Reboot",    confirm: true },
            { key: "poweroff", label: "Power off", confirm: true }
        ]

        function run(key) {
            root.shell.closePopup();
            if (key === "lock") {
                var cmd = Quickshell.env("QS_LOCK_CMD");
                if (cmd) Quickshell.execDetached([cmd]);
            } else if (key === "suspend") {
                Quickshell.execDetached(["systemctl", "suspend"]);
            } else if (key === "logout") {
                Hyprland.dispatch("exit");
            } else if (key === "reboot") {
                Quickshell.execDetached(["systemctl", "reboot"]);
            } else if (key === "poweroff") {
                Quickshell.execDetached(["systemctl", "poweroff"]);
            }
        }

        Repeater {
            model: popup.actions

            Rectangle {
                required property var modelData
                readonly property bool armed: popup.pendingAction === modelData.key
                property bool hovered: false

                width: parent.width
                height: 32
                radius: 6
                color: armed ? Theme.accentSoft
                     : hovered ? Theme.buttonHover : "transparent"
                border.width: armed ? 1 : 0
                border.color: Theme.accent

                Behavior on color { ColorAnimation { duration: Theme.animFast } }

                Text {
                    anchors.left: parent.left
                    anchors.leftMargin: 10
                    anchors.verticalCenter: parent.verticalCenter
                    text: parent.modelData.label
                    color: Theme.text
                    font.pixelSize: Theme.fontTitle
                }

                Text {
                    anchors.right: parent.right
                    anchors.rightMargin: 10
                    anchors.verticalCenter: parent.verticalCenter
                    visible: parent.armed
                    text: "confirm"
                    color: Theme.accent
                    font.pixelSize: Theme.fontCaption
                    font.bold: true
                }

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onEntered: parent.hovered = true
                    onExited: parent.hovered = false
                    onClicked: {
                        var d = parent.modelData;
                        if (!d.confirm || parent.armed) popup.run(d.key);
                        else popup.pendingAction = d.key;
                    }
                }
            }
        }
    }
}
