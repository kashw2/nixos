import Quickshell
import Quickshell.Hyprland
import QtQuick
import "."

PanelWindow {
    id: root
    required property var shell
    required property string popupName
    required property var modelData

    property int popupWidth: 280
    property int marginTop: 41
    property int marginRight: 8
    property int padding: 12
    property int spacing: 8
    property real maxImplicitHeight: -1
    property color backgroundColor: Theme.surfaceBg

    default property alias contentData: contentColumn.data
    readonly property bool isActive: root.shell.activePopup === popupName
    readonly property bool shown: isActive && root.shell.activePopupScreen === modelData

    signal cleared()

    screen: modelData
    visible: root.shown || card.opacity > 0.01

    HyprlandFocusGrab {
        active: root.isActive && root.shell.activePopupScreen === modelData
        windows: [root]
        onCleared: {
            root.shell.closePopup();
            root.cleared();
        }
    }

    anchors {
        top: true
        right: true
    }
    margins {
        top: root.marginTop
        right: root.marginRight
    }
    implicitWidth: root.popupWidth
    implicitHeight: {
        var h = contentColumn.implicitHeight + root.padding * 2;
        return root.maxImplicitHeight > 0 ? Math.min(h, root.maxImplicitHeight) : h;
    }
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"

    Rectangle {
        id: card
        anchors.fill: parent
        radius: 12
        color: root.backgroundColor
        border.width: 1
        border.color: Theme.hairline
        clip: true

        transformOrigin: Item.Top
        opacity: root.shown ? 1 : 0
        scale: root.shown ? 1 : 0.96

        Behavior on opacity { NumberAnimation { duration: Theme.animPopup; easing.type: Easing.OutCubic } }
        Behavior on scale { NumberAnimation { duration: Theme.animPopup; easing.type: Easing.OutCubic } }

        Rectangle {
            anchors.top: parent.top
            anchors.topMargin: 1
            anchors.horizontalCenter: parent.horizontalCenter
            width: parent.width - 24
            height: 1
            color: Theme.hairlineTop
        }

        Column {
            id: contentColumn
            anchors {
                fill: parent
                margins: root.padding
            }
            spacing: root.spacing
        }
    }
}
