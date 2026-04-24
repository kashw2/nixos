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
    property int marginTop: 38
    property int marginRight: 8
    property int padding: 12
    property int spacing: 8
    property real maxImplicitHeight: -1

    default property alias contentData: contentColumn.data
    readonly property bool isActive: root.shell.activePopup === popupName

    signal cleared()

    screen: modelData
    visible: isActive && root.shell.activePopupScreen === modelData

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
        anchors.fill: parent
        radius: 12
        color: Theme.surfaceBg
        clip: true

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
