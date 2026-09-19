import QtQuick
import "."

Rectangle {
    id: root

    property alias text: input.text
    property alias echoMode: input.echoMode
    property string placeholder: ""

    signal accepted()

    function focusInput() { input.forceActiveFocus(); }

    height: 24
    radius: 4
    color: Theme.surfaceInner

    TextInput {
        id: input
        anchors.fill: parent
        anchors.leftMargin: 6
        anchors.rightMargin: 6
        verticalAlignment: TextInput.AlignVCenter
        color: Theme.text
        font.pixelSize: Theme.fontBody
        clip: true

        Keys.onReturnPressed: root.accepted()

        Text {
            anchors.fill: parent
            verticalAlignment: Text.AlignVCenter
            text: root.placeholder
            color: Theme.textDim
            font.pixelSize: Theme.fontBody
            visible: root.placeholder !== "" && !input.text && !input.activeFocus
        }
    }
}
