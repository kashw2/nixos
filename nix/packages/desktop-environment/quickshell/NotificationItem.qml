import QtQuick
import QtQuick.Layouts
import "."

Rectangle {
    id: root

    required property var modelData
    required property int index
    property bool hovered: false

    signal dismissed()

    implicitHeight: itemContent.implicitHeight + 16
    radius: 8
    color: hovered ? Theme.surfaceStrong : Theme.surfaceSubtle

    Behavior on color { ColorAnimation { duration: Theme.animFast } }

    RowLayout {
        id: itemContent
        anchors {
            fill: parent
            margins: 8
        }
        spacing: 8

        ResultIcon {
            iconSize: 32
            imageSource: root.modelData.image
            iconNames: [root.modelData.appIcon]
            fallbackText: (root.modelData.appName || "?").charAt(0).toUpperCase()
            visible: root.modelData.image !== "" || root.modelData.appIcon !== ""
            Layout.preferredWidth: 32
            Layout.preferredHeight: 32
            Layout.alignment: Qt.AlignTop
        }

        Column {
            Layout.fillWidth: true
            spacing: 4

            RowLayout {
                width: parent.width

                Text {
                    text: root.modelData.appName + "  ·  " + root.modelData.time
                    color: Theme.textDim
                    font.pixelSize: Theme.fontCaption
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                }

                Rectangle {
                    width: 16
                    height: 16
                    radius: 8
                    color: dismissHover.containsMouse ? Theme.surfaceBg : "transparent"

                    Text {
                        anchors.centerIn: parent
                        text: "×"
                        color: Theme.textDim
                        font.pixelSize: Theme.fontBody
                    }

                    MouseArea {
                        id: dismissHover
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.dismissed()
                    }
                }
            }

            Text {
                text: root.modelData.summary
                color: Theme.text
                font.pixelSize: Theme.fontBody
                font.bold: true
                width: parent.width
                wrapMode: Text.WordWrap
                elide: Text.ElideRight
                maximumLineCount: 2
            }

            Text {
                visible: root.modelData.body !== ""
                text: root.modelData.body
                color: Theme.textDim
                font.pixelSize: Theme.fontLabel
                width: parent.width
                wrapMode: Text.WordWrap
                elide: Text.ElideRight
                maximumLineCount: 3
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        z: -1
        onEntered: root.hovered = true
        onExited: root.hovered = false
    }
}
