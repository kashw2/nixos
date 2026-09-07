import Quickshell
import QtQuick
import "."

Item {
    id: root

    property string imageSource: ""
    property var iconNames: []
    property string fallbackText: ""
    property int iconSize: 26

    implicitWidth: iconSize
    implicitHeight: iconSize

    readonly property string resolved: {
        if (imageSource !== "") return imageSource;
        for (var i = 0; i < iconNames.length; i++) {
            var name = iconNames[i];
            if (!name || name === "") continue;
            var path = Quickshell.iconPath(name, true);
            if (path !== "") return path;
        }
        return "";
    }

    Image {
        anchors.fill: parent
        visible: root.resolved !== ""
        source: root.resolved
        sourceSize.width: root.iconSize
        sourceSize.height: root.iconSize
        fillMode: Image.PreserveAspectFit
        smooth: true
        asynchronous: true
    }

    Rectangle {
        anchors.fill: parent
        visible: root.resolved === "" && root.fallbackText !== ""
        radius: Math.max(4, root.iconSize * 0.22)
        color: Theme.surfaceStrong

        Text {
            anchors.centerIn: parent
            text: root.fallbackText
            color: Theme.textDim
            font.pixelSize: Math.max(9, Math.round(root.iconSize * (root.fallbackText.length > 1 ? 0.38 : 0.52)))
            font.bold: true
        }
    }
}
