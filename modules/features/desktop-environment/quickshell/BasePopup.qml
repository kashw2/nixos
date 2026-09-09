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
    property bool followAnchor: true

    readonly property real anchorCentre: root.shell.popupAnchorX + root.shell.popupAnchorWidth / 2
    readonly property real screenWidth: modelData ? modelData.width : 0
    readonly property real anchoredLeft: Math.max(8, Math.min(root.anchorCentre - root.popupWidth / 2, root.screenWidth - root.popupWidth - 8))
    property int padding: 12
    property int spacing: 8
    property real maxImplicitHeight: -1
    property color backgroundColor: Theme.surfaceBg
    property color borderColor: Theme.hairline
    property Component backdrop: null

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
        left: true
    }
    margins {
        top: root.marginTop
        left: root.anchoredLeft
    }
    implicitWidth: root.popupWidth
    implicitHeight: {
        var h = contentColumn.implicitHeight + root.padding * 2;
        return root.maxImplicitHeight > 0 ? Math.min(h, root.maxImplicitHeight) : h;
    }
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"

    Behavior on implicitHeight {
        enabled: root.shown
        NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
    }

    Rectangle {
        id: card
        anchors.fill: parent
        radius: 12
        color: root.backgroundColor
        border.width: 1
        border.color: root.borderColor
        clip: true

        Behavior on border.color { ColorAnimation { duration: 320 } }

        transformOrigin: Item.Top
        opacity: root.shown ? 1 : 0
        scale: root.shown ? 1 : 0.96

        Behavior on opacity { NumberAnimation { duration: Theme.animPopup; easing.type: Easing.OutCubic } }
        Behavior on scale { NumberAnimation { duration: Theme.animPopup; easing.type: Easing.OutCubic } }

        Loader {
            anchors.fill: parent
            z: -1
            active: root.backdrop !== null
            sourceComponent: root.backdrop
        }

        Rectangle {
            anchors.top: parent.top
            anchors.topMargin: 1
            anchors.horizontalCenter: parent.horizontalCenter
            width: parent.width - 24
            height: 1
            color: Theme.hairlineTop
        }

        Rectangle {
            id: anchorMark
            visible: root.followAnchor && root.shell.popupAnchorWidth > 0
            y: 0
            width: 28
            height: 2
            radius: 1
            color: Theme.accent
            x: Math.max(8, Math.min(root.anchorCentre - root.anchoredLeft - width / 2, card.width - width - 8))

            Behavior on x { NumberAnimation { duration: Theme.animPopup; easing.type: Easing.OutCubic } }
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
