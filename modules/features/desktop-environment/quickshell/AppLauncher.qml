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
        id: launcherWindow
        required property var modelData
        screen: modelData

        property string searchText: ""
        readonly property bool isActive: root.shell.activePopup === "applauncher"
        readonly property bool isOnThisScreen: isActive && root.shell.activePopupScreen === modelData
        readonly property var allEntries: DesktopEntries.applications.values
        readonly property var filteredEntries: {
            var entries = allEntries.filter(function(e) { return !e.noDisplay; });
            if (searchText === "") {
                entries.sort(function(a, b) { return a.name.localeCompare(b.name); });
                return entries;
            }
            var q = searchText.toLowerCase();
            var scored = [];
            for (var i = 0; i < entries.length; i++) {
                var e = entries[i];
                var name = (e.name || "").toLowerCase();
                var generic = (e.genericName || "").toLowerCase();
                var comment = (e.comment || "").toLowerCase();
                var score = -1;
                if (name.indexOf(q) === 0) score = 0;
                else if (name.indexOf(q) !== -1) score = 1;
                else if (generic.indexOf(q) !== -1) score = 2;
                else if (comment.indexOf(q) !== -1) score = 3;
                if (score >= 0) scored.push({ entry: e, score: score });
            }
            scored.sort(function(a, b) {
                if (a.score !== b.score) return a.score - b.score;
                return a.entry.name.localeCompare(b.entry.name);
            });
            return scored.map(function(s) { return s.entry; });
        }
        property int selectedIndex: 0

        visible: isOnThisScreen

        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }
        exclusionMode: ExclusionMode.Ignore
        focusable: true
        color: "transparent"

        HyprlandFocusGrab {
            active: launcherWindow.isOnThisScreen
            windows: [launcherWindow]
            onCleared: root.shell.closePopup()
        }

        onIsOnThisScreenChanged: {
            if (isOnThisScreen) {
                searchText = "";
                searchField.text = "";
                selectedIndex = 0;
                searchField.forceActiveFocus();
            }
        }

        onFilteredEntriesChanged: selectedIndex = 0

        function launchSelected() {
            var entries = filteredEntries;
            if (entries.length === 0) return;
            var idx = Math.max(0, Math.min(selectedIndex, entries.length - 1));
            entries[idx].execute();
            root.shell.closePopup();
        }

        // Click anywhere outside the launcher box to dismiss
        MouseArea {
            anchors.fill: parent
            onClicked: root.shell.closePopup()
        }

        Rectangle {
            id: launcherBox
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            anchors.topMargin: parent.height * 0.12
            width: Math.min(parent.width - 80, 600)

            readonly property int itemHeight: 48
            readonly property int itemSpacing: 2
            readonly property int collapsedHeight: 62
            readonly property int maxListHeight: Math.min(parent.height * 0.6, 7 * (itemHeight + itemSpacing))
            readonly property bool expanded: launcherWindow.searchText !== ""
            readonly property int contentHeight: {
                if (!expanded) return 0;
                if (launcherWindow.filteredEntries.length === 0) return 28;
                var natural = launcherWindow.filteredEntries.length * (itemHeight + itemSpacing) - itemSpacing;
                return Math.min(maxListHeight, natural);
            }

            height: collapsedHeight + (expanded ? contentHeight + 8 : 0)

            Behavior on height {
                NumberAnimation { duration: 220; easing.type: Easing.OutCubic }
            }

            radius: 12
            color: Theme.surfaceBg
            clip: true

            // Swallow clicks so the outer dismiss MouseArea doesn't fire
            MouseArea {
                anchors.fill: parent
                onClicked: {}
            }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 12
                spacing: 8

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 38
                    radius: 8
                    color: Theme.surfaceInner

                    TextInput {
                        id: searchField
                        anchors.fill: parent
                        anchors.leftMargin: 12
                        anchors.rightMargin: 12
                        verticalAlignment: TextInput.AlignVCenter
                        color: Theme.text
                        font.pixelSize: 14
                        clip: true
                        focus: launcherWindow.isOnThisScreen
                        onTextChanged: launcherWindow.searchText = text
                        Keys.onEscapePressed: root.shell.closePopup()
                        Keys.onReturnPressed: launcherWindow.launchSelected()
                        Keys.onDownPressed: {
                            var len = launcherWindow.filteredEntries.length;
                            if (len > 0) launcherWindow.selectedIndex = (launcherWindow.selectedIndex + 1) % len;
                        }
                        Keys.onUpPressed: {
                            var len = launcherWindow.filteredEntries.length;
                            if (len > 0) launcherWindow.selectedIndex = (launcherWindow.selectedIndex - 1 + len) % len;
                        }

                        Text {
                            anchors.fill: parent
                            verticalAlignment: Text.AlignVCenter
                            text: "Search"
                            color: Theme.textDim
                            font.pixelSize: 14
                            visible: !searchField.text && !searchField.activeFocus
                        }
                    }
                }

                ListView {
                    id: appList
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    model: launcherWindow.filteredEntries
                    currentIndex: launcherWindow.selectedIndex
                    onCurrentIndexChanged: positionViewAtIndex(currentIndex, ListView.Contain)
                    spacing: 2
                    boundsBehavior: Flickable.StopAtBounds
                    opacity: launcherBox.expanded ? 1 : 0
                    Behavior on opacity { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

                    add: Transition {
                        NumberAnimation { property: "opacity"; from: 0; to: 1; duration: 160; easing.type: Easing.OutCubic }
                        NumberAnimation { property: "y"; from: 8; duration: 160; easing.type: Easing.OutCubic }
                    }
                    displaced: Transition {
                        NumberAnimation { properties: "y"; duration: 160; easing.type: Easing.OutCubic }
                    }

                    delegate: Rectangle {
                        id: appItem
                        required property int index
                        required property var modelData
                        width: ListView.view.width
                        height: 48
                        radius: 6
                        color: index === launcherWindow.selectedIndex
                            ? Theme.surfaceActive
                            : itemHover.containsMouse ? Theme.surfaceStrong
                            : "transparent"

                        Behavior on color { ColorAnimation { duration: 100 } }

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 10
                            anchors.rightMargin: 10
                            spacing: 10

                            Image {
                                source: appItem.modelData.icon ? "image://icon/" + appItem.modelData.icon : ""
                                visible: source !== ""
                                Layout.preferredWidth: 32
                                Layout.preferredHeight: 32
                                Layout.alignment: Qt.AlignVCenter
                                sourceSize.width: 32
                                sourceSize.height: 32
                                fillMode: Image.PreserveAspectFit
                                smooth: true
                            }

                            Column {
                                Layout.fillWidth: true
                                Layout.alignment: Qt.AlignVCenter
                                spacing: 2

                                Text {
                                    text: appItem.modelData.name || ""
                                    color: Theme.text
                                    font.pixelSize: 13
                                    font.bold: true
                                    elide: Text.ElideRight
                                    width: parent.width
                                }

                                Text {
                                    visible: text !== ""
                                    text: appItem.modelData.genericName || appItem.modelData.comment || ""
                                    color: Theme.textDim
                                    font.pixelSize: 11
                                    elide: Text.ElideRight
                                    width: parent.width
                                }
                            }
                        }

                        MouseArea {
                            id: itemHover
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onPositionChanged: launcherWindow.selectedIndex = appItem.index
                            onClicked: {
                                launcherWindow.selectedIndex = appItem.index;
                                launcherWindow.launchSelected();
                            }
                        }
                    }
                }

                Text {
                    visible: launcherBox.expanded && launcherWindow.filteredEntries.length === 0
                    text: "No matches"
                    color: Theme.textDim
                    font.pixelSize: 12
                    Layout.alignment: Qt.AlignHCenter
                    Layout.bottomMargin: 8
                    opacity: visible ? 1 : 0
                    Behavior on opacity { NumberAnimation { duration: 180 } }
                }
            }
        }
    }
}
