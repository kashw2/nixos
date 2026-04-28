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

        property var placeholderExamples: {
            var names = allEntries
                .filter(function(e) { return !e.noDisplay && e.name; })
                .map(function(e) { return e.name; });
            for (var i = names.length - 1; i > 0; i--) {
                var j = Math.floor(Math.random() * (i + 1));
                var t = names[i]; names[i] = names[j]; names[j] = t;
            }
            return names.slice(0, 24);
        }
        property int placeholderIndex: 0
        readonly property string currentPlaceholder: placeholderExamples.length > 0
            ? placeholderExamples[placeholderIndex % placeholderExamples.length]
            : "Search"

        Timer {
            interval: 2200
            running: launcherWindow.isOnThisScreen && launcherWindow.searchText === ""
            repeat: true
            onTriggered: {
                if (launcherWindow.placeholderExamples.length > 0) {
                    launcherWindow.placeholderIndex = (launcherWindow.placeholderIndex + 1) % launcherWindow.placeholderExamples.length;
                }
            }
        }

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
                placeholderIndex = Math.floor(Math.random() * Math.max(1, placeholderExamples.length));
                placeholderText.displayed = currentPlaceholder;
                placeholderSwap.stop();
                placeholderText.opacity = 1;
                placeholderTranslate.y = 0;
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

            opacity: launcherWindow.isOnThisScreen ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

            transform: Translate {
                y: launcherWindow.isOnThisScreen ? 0 : -32
                Behavior on y { NumberAnimation { duration: 260; easing.type: Easing.OutCubic } }
            }

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

            // Lighter pulse sweeping left → right across the darker box background
            Rectangle {
                id: pulseSweep
                width: parent.width * 0.45
                height: parent.height
                y: 0
                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop { position: 0.0; color: Qt.rgba(1, 1, 1, 0) }
                    GradientStop { position: 0.5; color: Qt.rgba(1, 1, 1, 0.06) }
                    GradientStop { position: 1.0; color: Qt.rgba(1, 1, 1, 0) }
                }

                NumberAnimation on x {
                    from: -pulseSweep.width
                    to: launcherBox.width
                    duration: 3200
                    loops: Animation.Infinite
                    running: launcherWindow.isOnThisScreen
                    easing.type: Easing.InOutSine
                }
            }

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
                    clip: true

                    Canvas {
                        id: waveCanvas
                        anchors.fill: parent
                        z: -1

                        property real phase: 0

                        Timer {
                            interval: 32
                            running: launcherWindow.isOnThisScreen
                            repeat: true
                            onTriggered: {
                                waveCanvas.phase += 0.045;
                                waveCanvas.requestPaint();
                            }
                        }

                        onPaint: {
                            var ctx = getContext("2d");
                            ctx.clearRect(0, 0, width, height);

                            var midY = height / 2;
                            var amp = height * 0.32;
                            var freq = (2 * Math.PI / width) * 1.6;

                            function drawWave(amplitude, frequencyMul, phaseShift, alpha, lineWidth) {
                                ctx.strokeStyle = Qt.rgba(1, 1, 1, alpha);
                                ctx.lineWidth = lineWidth;
                                ctx.lineCap = "round";
                                ctx.lineJoin = "round";
                                ctx.beginPath();
                                for (var x = 0; x <= width; x += 2) {
                                    var y = midY + Math.sin(x * freq * frequencyMul + waveCanvas.phase * phaseShift) * amplitude;
                                    if (x === 0) ctx.moveTo(x, y);
                                    else ctx.lineTo(x, y);
                                }
                                ctx.stroke();
                            }

                            drawWave(amp, 1.0, 1.0, 0.10, 1.6);
                            drawWave(amp * 0.7, 1.5, -1.4, 0.07, 1.2);
                            drawWave(amp * 0.45, 0.7, 0.6, 0.05, 1.0);
                        }
                    }

                    TextInput {
                        id: searchField
                        anchors.fill: parent
                        anchors.leftMargin: 12
                        anchors.rightMargin: 12
                        verticalAlignment: TextInput.AlignVCenter
                        color: Theme.text
                        font.pixelSize: 14
                        font.weight: Font.DemiBold
                        clip: true
                        cursorDelegate: Item {}
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
                            id: placeholderText
                            anchors.fill: parent
                            verticalAlignment: Text.AlignVCenter
                            color: Theme.textDim
                            font.pixelSize: 14
                            font.weight: Font.DemiBold
                            visible: !searchField.text

                            property string displayed: ""
                            text: displayed
                            Component.onCompleted: displayed = launcherWindow.currentPlaceholder

                            transform: Translate { id: placeholderTranslate; y: 0 }

                            Connections {
                                target: launcherWindow
                                function onCurrentPlaceholderChanged() {
                                    if (placeholderText.displayed !== launcherWindow.currentPlaceholder) {
                                        placeholderSwap.restart();
                                    }
                                }
                            }

                            SequentialAnimation {
                                id: placeholderSwap
                                ParallelAnimation {
                                    NumberAnimation { target: placeholderText; property: "opacity"; to: 0; duration: 180; easing.type: Easing.InOutCubic }
                                    NumberAnimation { target: placeholderTranslate; property: "y"; to: -6; duration: 180; easing.type: Easing.InOutCubic }
                                }
                                ScriptAction {
                                    script: {
                                        placeholderText.displayed = launcherWindow.currentPlaceholder;
                                        placeholderTranslate.y = 6;
                                    }
                                }
                                ParallelAnimation {
                                    NumberAnimation { target: placeholderText; property: "opacity"; to: 1; duration: 220; easing.type: Easing.OutCubic }
                                    NumberAnimation { target: placeholderTranslate; property: "y"; to: 0; duration: 220; easing.type: Easing.OutCubic }
                                }
                            }
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
