import Quickshell
import Quickshell.Hyprland
import QtQuick
import QtQuick.Layouts
import "."

Variants {
    id: root
    required property var shell

    model: Quickshell.screens

    PanelWindow {
        id: notchWindow
        required property var modelData
        screen: modelData

        readonly property var notif: root.shell.toastNotification
        property bool expanded: false
        readonly property bool wantVisible: (root.shell.toastVisible || expanded) && notif !== null && root.shell.activePopup !== "notif"

        visible: wantVisible || notch.y > -notch.height

        anchors {
            top: true
        }
        margins {
            top: 44
        }
        implicitWidth: 320
        implicitHeight: 240
        exclusionMode: ExclusionMode.Ignore
        color: "transparent"
        mask: Region { item: notch }

        Rectangle {
            id: notch
            width: parent.width
            height: notchContent.implicitHeight + 20
            radius: 12
            color: Theme.surfaceBg
            clip: true

            y: notchWindow.wantVisible ? 0 : -height

            Behavior on y {
                NumberAnimation {
                    duration: notchWindow.wantVisible ? 280 : 200
                    easing.type: Easing.OutCubic
                }
            }

            Behavior on height {
                NumberAnimation {
                    duration: 140
                    easing.type: Easing.OutQuad
                }
            }

            RowLayout {
                id: notchContent
                anchors {
                    left: parent.left
                    right: parent.right
                    verticalCenter: parent.verticalCenter
                    leftMargin: 12
                    rightMargin: 12
                }
                spacing: 8

                Item {
                    id: iconSlot
                    Layout.preferredWidth: 28
                    Layout.preferredHeight: 28
                    Layout.alignment: Qt.AlignVCenter

                    function ring() {
                        bell.rotation = 0;
                        bell.opacity = 1;
                        appIcon.opacity = 0;
                        wobble.restart();
                    }

                    Image {
                        id: appIcon
                        anchors.centerIn: parent
                        width: 28
                        height: 28
                        sourceSize.width: 28
                        sourceSize.height: 28
                        opacity: 0
                        source: {
                            var n = notchWindow.notif;
                            if (!n) return "";
                            if ((n.image || "") !== "") return n.image;
                            if ((n.appIcon || "") !== "") return "image://icon/" + n.appIcon;
                            return "";
                        }
                    }

                    BellIcon {
                        id: bell
                        anchors.centerIn: parent
                        transformOrigin: Item.Top
                        count: 0
                    }

                    SequentialAnimation {
                        id: wobble
                        SequentialAnimation {
                            loops: 2
                            NumberAnimation { target: bell; property: "rotation"; to: 18; duration: 90; easing.type: Easing.OutQuad }
                            NumberAnimation { target: bell; property: "rotation"; to: -14; duration: 140; easing.type: Easing.InOutQuad }
                            NumberAnimation { target: bell; property: "rotation"; to: 10; duration: 140; easing.type: Easing.InOutQuad }
                            NumberAnimation { target: bell; property: "rotation"; to: -6; duration: 130; easing.type: Easing.InOutQuad }
                            NumberAnimation { target: bell; property: "rotation"; to: 3; duration: 120; easing.type: Easing.InOutQuad }
                            NumberAnimation { target: bell; property: "rotation"; to: 0; duration: 100; easing.type: Easing.InQuad }
                        }
                        PauseAnimation { duration: 180 }
                        ParallelAnimation {
                            NumberAnimation { target: bell; property: "opacity"; to: 0; duration: 200 }
                            NumberAnimation { target: appIcon; property: "opacity"; to: 1; duration: 200 }
                        }
                    }
                }

                Column {
                    Layout.fillWidth: true
                    spacing: 2

                    Text {
                        text: notchWindow.notif ? (notchWindow.notif.appName || "Notification") : ""
                        color: Theme.textDim
                        font.pixelSize: Theme.fontCaption
                        width: parent.width
                        elide: Text.ElideRight
                    }

                    Text {
                        text: notchWindow.notif ? (notchWindow.notif.summary || "") : ""
                        color: Theme.text
                        font.pixelSize: Theme.fontBody
                        font.bold: true
                        width: parent.width
                        wrapMode: Text.WordWrap
                        elide: notchWindow.expanded ? Text.ElideNone : Text.ElideRight
                        maximumLineCount: notchWindow.expanded ? 99 : 2
                    }

                    Text {
                        visible: notchWindow.expanded && (notchWindow.notif ? (notchWindow.notif.body || "") !== "" : false)
                        text: notchWindow.notif ? (notchWindow.notif.body || "") : ""
                        color: Theme.textDim
                        font.pixelSize: Theme.fontLabel
                        width: parent.width
                        wrapMode: Text.WordWrap
                        elide: Text.ElideRight
                        maximumLineCount: 6
                    }
                }
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: notchWindow.expanded = !notchWindow.expanded
            }
        }

        Connections {
            target: root.shell
            function onToastSeqChanged() {
                notchWindow.expanded = false;
                iconSlot.ring();
            }
        }

        HyprlandFocusGrab {
            active: notchWindow.expanded
            windows: [notchWindow]
            onCleared: {
                notchWindow.expanded = false;
                root.shell.toastVisible = false;
            }
        }
    }
}
