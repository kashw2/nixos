import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
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
        readonly property string homeDir: Quickshell.env("HOME") || ""

        readonly property var appMatches: {
            if (searchText === "") return [];
            var entries = allEntries.filter(function(e) { return !e.noDisplay; });
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

        property var fileMatches: []
        property var dirMatches: []
        property var sessions: []
        property var sessionWindows: ({})

        readonly property var calcMatches: {
            var q = searchText.trim();
            if (q.length < 3) return [];
            if (!/^[0-9+\-*\/%^(). ]+$/.test(q)) return [];
            if (!/[+\-*\/%^]/.test(q)) return [];
            try {
                var v = evalExpression(q);
                if (!isFinite(v)) return [];
                return [{ type: "calc", expr: q, result: formatNumber(v) }];
            } catch (err) {
                return [];
            }
        }

        readonly property var sessionMatches: {
            if (searchText === "") return [];
            var q = searchText.toLowerCase();
            return sessions.filter(function(s) {
                if (s.name.toLowerCase().indexOf(q) !== -1) return true;
                if (s.path.toLowerCase().indexOf(q) !== -1) return true;
                var wins = sessionWindows[s.name] || [];
                for (var i = 0; i < wins.length; i++) {
                    if (wins[i].name.toLowerCase().indexOf(q) !== -1) return true;
                }
                return false;
            });
        }

        function escapeHtml(s) {
            return String(s).replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;");
        }

        function accentHex() {
            var c = Theme.accent;
            function h(v) {
                var s = Math.round(v * 255).toString(16);
                return s.length < 2 ? "0" + s : s;
            }
            return "#" + h(c.r) + h(c.g) + h(c.b);
        }

        function highlightMatch(text, query) {
            var t = String(text);
            if (!query) return launcherWindow.escapeHtml(t);

            var lt = t.toLowerCase();
            var lq = query.toLowerCase();
            var open = "<font color=\"" + launcherWindow.accentHex() + "\"><b>";
            var close = "</b></font>";

            var idx = lt.indexOf(lq);
            if (idx >= 0) {
                return launcherWindow.escapeHtml(t.substring(0, idx))
                    + open + launcherWindow.escapeHtml(t.substring(idx, idx + lq.length)) + close
                    + launcherWindow.escapeHtml(t.substring(idx + lq.length));
            }

            var out = "";
            var qi = 0;
            for (var i = 0; i < t.length; i++) {
                if (qi < lq.length && lt.charAt(i) === lq.charAt(qi)) {
                    out += open + launcherWindow.escapeHtml(t.charAt(i)) + close;
                    qi++;
                } else {
                    out += launcherWindow.escapeHtml(t.charAt(i));
                }
            }
            return qi === lq.length ? out : launcherWindow.escapeHtml(t);
        }

        readonly property var rows: {
            var out = [];
            var groups = [
                { label: "Calculator", items: calcMatches },
                { label: "Applications", items: appMatches.map(function(e) { return { type: "app", entry: e }; }) },
                { label: "Sessions", items: sessionMatches },
                { label: "Folders", items: dirMatches },
                { label: "Files", items: fileMatches }
            ];
            for (var g = 0; g < groups.length; g++) {
                var items = groups[g].items;
                if (items.length === 0) continue;
                out.push({ type: "header", label: groups[g].label, count: items.length });
                for (var i = 0; i < items.length; i++) out.push(items[i]);
            }
            return out;
        }

        readonly property var selectable: {
            var out = [];
            for (var i = 0; i < rows.length; i++) if (rows[i].type !== "header") out.push(i);
            return out;
        }

        property int selectedRow: -1
        readonly property var selected: selectedRow >= 0 && selectedRow < rows.length ? rows[selectedRow] : null

        function evalExpression(src) {
            var i = 0;
            function skip() { while (i < src.length && src.charAt(i) === " ") i++; }
            function primary() {
                skip();
                if (src.charAt(i) === "(") {
                    i++;
                    var inner = sum();
                    skip();
                    if (src.charAt(i) !== ")") throw new Error("unbalanced");
                    i++;
                    return inner;
                }
                var start = i;
                while (i < src.length && "0123456789.".indexOf(src.charAt(i)) !== -1) i++;
                if (i === start) throw new Error("number expected");
                var n = parseFloat(src.substring(start, i));
                if (isNaN(n)) throw new Error("bad number");
                return n;
            }
            function power() {
                var base = primary();
                skip();
                if (src.charAt(i) === "^") { i++; return Math.pow(base, unary()); }
                return base;
            }
            function unary() {
                skip();
                if (src.charAt(i) === "-") { i++; return -unary(); }
                if (src.charAt(i) === "+") { i++; return unary(); }
                return power();
            }
            function product() {
                var v = unary();
                for (;;) {
                    skip();
                    var c = src.charAt(i);
                    if (c === "*") { i++; v *= unary(); }
                    else if (c === "/") { i++; v /= unary(); }
                    else if (c === "%") { i++; v %= unary(); }
                    else return v;
                }
            }
            function sum() {
                var v = product();
                for (;;) {
                    skip();
                    var c = src.charAt(i);
                    if (c === "+") { i++; v += product(); }
                    else if (c === "-") { i++; v -= product(); }
                    else return v;
                }
            }
            var result = sum();
            skip();
            if (i !== src.length) throw new Error("trailing input");
            return result;
        }

        function formatNumber(v) {
            var rounded = parseFloat(v.toFixed(10));
            return String(rounded);
        }

        function formatSize(bytes) {
            var b = Number(bytes);
            if (!isFinite(b)) return "";
            var units = ["B", "KB", "MB", "GB", "TB"];
            var u = 0;
            while (b >= 1024 && u < units.length - 1) { b /= 1024; u++; }
            return (u === 0 ? b.toFixed(0) : b.toFixed(1)) + " " + units[u];
        }

        function formatTime(epoch) {
            var t = Number(epoch);
            if (!isFinite(t) || t <= 0) return "";
            return Qt.formatDateTime(new Date(t * 1000), "yyyy-MM-dd hh:mm");
        }

        function shortenPath(p) {
            if (homeDir !== "" && p.indexOf(homeDir) === 0) return "~" + p.substring(homeDir.length);
            return p;
        }

        function commandOf(entry) {
            if (!entry) return "";
            if (entry.command && entry.command.length !== undefined) return entry.command.join(" ");
            return entry.execString || "";
        }

        function rowIconNames(row) {
            if (!row) return [];
            if (row.type === "app") return [row.entry.icon || "", "application-x-executable"];
            if (row.type === "file") return ["text-x-generic", "text-plain", "unknown"];
            if (row.type === "dir") return ["folder", "inode-directory"];
            if (row.type === "session") return ["utilities-terminal", "terminal"];
            if (row.type === "calc") return ["accessories-calculator", "gnome-calculator", "calc"];
            return [];
        }

        function rowIconFallback(row) {
            if (!row) return "";
            if (row.type === "app") return (row.entry.name || "?").charAt(0).toUpperCase();
            if (row.type === "calc") return "=";
            if (row.type === "dir") return "/";
            if (row.type === "session") return ">_";
            if (row.type === "file") {
                var dot = row.name.lastIndexOf(".");
                var ext = dot > 0 ? row.name.substring(dot + 1) : "";
                return ext !== "" && ext.length <= 4 ? ext.toUpperCase() : "F";
            }
            return "";
        }

        function rowTitle(row) {
            if (!row) return "";
            if (row.type === "app") return row.entry.name || "";
            if (row.type === "file" || row.type === "dir" || row.type === "session") return row.name;
            if (row.type === "calc") return row.result;
            return "";
        }

        function rowSubtitle(row) {
            if (!row) return "";
            if (row.type === "app") return row.entry.genericName || row.entry.comment || "";
            if (row.type === "file") return row.dir;
            if (row.type === "dir") return row.parent;
            if (row.type === "session") {
                return row.windows + (row.windows === 1 ? " window" : " windows")
                    + (row.attached ? "  ·  attached" : "")
                    + "  ·  " + shortenPath(row.path);
            }
            if (row.type === "calc") return row.expr;
            return "";
        }

        function rowKind(row) {
            if (!row) return "";
            if (row.type === "app") return "App";
            if (row.type === "file") return "File";
            if (row.type === "dir") return "Folder";
            if (row.type === "session") return "Session";
            if (row.type === "calc") return "Calc";
            return "";
        }

        function moveSelection(delta) {
            var list = selectable;
            if (list.length === 0) return;
            var at = list.indexOf(selectedRow);
            if (at === -1) { selectedRow = list[0]; return; }
            selectedRow = list[(at + delta + list.length) % list.length];
        }

        function activateSelected() {
            var row = selected;
            if (!row) return;
            if (row.type === "app") {
                row.entry.execute();
            } else if (row.type === "file") {
                Quickshell.execDetached(["kitty", "nvim", "--", row.path]);
            } else if (row.type === "dir") {
                Quickshell.execDetached(["nautilus", "--", row.path]);
            } else if (row.type === "session") {
                Quickshell.execDetached(["kitty", "tmux", "new-session", "-A", "-s", row.name]);
            } else if (row.type === "calc") {
                Quickshell.execDetached(["sh", "-c", "printf '%s' \"$1\" | wl-copy", "sh", row.result]);
            }
            root.shell.closePopup();
        }

        Timer {
            id: fileDebounce
            interval: 220
            onTriggered: {
                fileSearch.running = false;
                fileSearch.running = true;
            }
        }

        onSearchTextChanged: {
            if (searchText.length < 2) {
                fileDebounce.stop();
                fileSearch.running = false;
                fileMatches = [];
                dirMatches = [];
                sessions = [];
                sessionWindows = ({});
            } else {
                fileDebounce.restart();
            }
        }

        onRowsChanged: {
            var list = selectable;
            if (list.length === 0) selectedRow = -1;
            else if (list.indexOf(selectedRow) === -1) selectedRow = list[0];
        }

        Process {
            id: fileSearch
            command: ["sh", Quickshell.shellPath("search.sh"), launcherWindow.searchText]
            stdout: StdioCollector {
                onStreamFinished: {
                    var lines = text.split("\n");
                    var files = [];
                    var dirs = [];
                    var sess = [];
                    var wins = {};
                    for (var i = 0; i < lines.length; i++) {
                        if (lines[i] === "") continue;
                        var f = lines[i].split("|");
                        var kind = f[0];
                        if (kind === "F" && f.length >= 4) {
                            var fpath = f.slice(3).join("|");
                            var fslash = fpath.lastIndexOf("/");
                            files.push({
                                type: "file",
                                path: fpath,
                                name: fslash === -1 ? fpath : fpath.substring(fslash + 1),
                                dir: launcherWindow.shortenPath(fslash === -1 ? "" : fpath.substring(0, fslash)),
                                size: f[1],
                                mtime: f[2]
                            });
                        } else if (kind === "D" && f.length >= 4) {
                            var dpath = f.slice(3).join("|");
                            var dslash = dpath.lastIndexOf("/");
                            dirs.push({
                                type: "dir",
                                path: dpath,
                                name: dslash === -1 ? dpath : dpath.substring(dslash + 1),
                                parent: launcherWindow.shortenPath(dslash === -1 ? "" : dpath.substring(0, dslash)),
                                mtime: f[2]
                            });
                        } else if (kind === "S" && f.length >= 6) {
                            sess.push({
                                type: "session",
                                name: f[1],
                                windows: parseInt(f[2], 10),
                                attached: f[3] === "1",
                                path: f.slice(4, f.length - 1).join("|"),
                                activity: f[f.length - 1]
                            });
                        } else if (kind === "W" && f.length >= 5) {
                            if (!wins[f[1]]) wins[f[1]] = [];
                            wins[f[1]].push({
                                index: f[2],
                                name: f.slice(3, f.length - 1).join("|"),
                                active: f[f.length - 1] === "1"
                            });
                        }
                    }
                    launcherWindow.fileMatches = files;
                    launcherWindow.dirMatches = dirs;
                    launcherWindow.sessionWindows = wins;
                    launcherWindow.sessions = sess;
                }
            }
        }

        readonly property string selectedFilePath:
            selected && (selected.type === "file" || selected.type === "dir") ? selected.path : ""
        property string previewMode: ""
        property string previewBody: ""

        readonly property bool previewIsCodeSurface:
            selected !== null
            && (selected.type === "file" || selected.type === "dir" || selected.type === "session")

        function sessionWindowList(name) {
            var wins = sessionWindows[name] || [];
            var out = [];
            for (var i = 0; i < wins.length; i++) {
                out.push((wins[i].active ? " ● " : "   ") + wins[i].index + "  " + wins[i].name);
            }
            return out.join("\n");
        }

        function fileUrl(path) {
            return "file://" + path.split("/").map(encodeURIComponent).join("/");
        }

        Timer {
            id: previewDebounce
            interval: 120
            onTriggered: {
                filePreview.running = false;
                filePreview.running = true;
            }
        }

        onSelectedRowChanged: {
            previewMode = "";
            previewBody = "";
            filePreview.running = false;
            previewDebounce.stop();
            var row = selected;
            if (!row) return;
            if (row.type === "session") {
                previewMode = "text";
                previewBody = sessionWindowList(row.name);
            } else if (row.type === "file" || row.type === "dir") {
                previewDebounce.restart();
            }
        }

        Process {
            id: filePreview
            command: ["sh", Quickshell.shellPath("preview.sh"),
                launcherWindow.selectedFilePath,
                Quickshell.shellPath(Theme.codeStyle)]
            stdout: StdioCollector {
                onStreamFinished: {
                    var newline = text.indexOf("\n");
                    var marker = newline === -1 ? text : text.substring(0, newline);
                    var body = newline === -1 ? "" : text.substring(newline + 1);
                    if (marker === "MODE:html") {
                        launcherWindow.previewMode = "html";
                        launcherWindow.previewBody = body;
                    } else if (marker === "MODE:text") {
                        launcherWindow.previewMode = "text";
                        launcherWindow.previewBody = body;
                    } else if (marker === "MODE:image") {
                        launcherWindow.previewMode = "image";
                        launcherWindow.previewBody = "";
                    } else if (marker === "MODE:binary") {
                        launcherWindow.previewMode = "binary";
                        launcherWindow.previewBody = "";
                    } else {
                        launcherWindow.previewMode = "";
                        launcherWindow.previewBody = "";
                    }
                }
            }
        }

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
                fileMatches = [];
                selectedRow = -1;
                previewMode = "";
                previewBody = "";
                placeholderIndex = Math.floor(Math.random() * Math.max(1, placeholderExamples.length));
                placeholderText.displayed = currentPlaceholder;
                placeholderSwap.stop();
                placeholderText.opacity = 1;
                placeholderTranslate.y = 0;
                searchField.forceActiveFocus();
            }
        }

        // Click anywhere outside the launcher to dismiss
        MouseArea {
            anchors.fill: parent
            onClicked: root.shell.closePopup()
        }

        LauncherInfoCards {
            shell: root.shell
            shown: launcherWindow.isOnThisScreen && launcherWindow.searchText === ""

            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: launcherBox.top
            anchors.topMargin: launcherBox.searchHeight + 12
            width: launcherBox.width
        }

        Item {
            id: launcherBox
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            anchors.topMargin: parent.height * 0.12
            width: Math.min(parent.width - 80, 1100)

            opacity: launcherWindow.isOnThisScreen ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

            transform: Translate {
                y: launcherWindow.isOnThisScreen ? 0 : -32
                Behavior on y { NumberAnimation { duration: 260; easing.type: Easing.OutCubic } }
            }

            readonly property int headerHeight: 26
            readonly property int itemHeight: 46
            readonly property int itemSpacing: 2
            readonly property int searchHeight: 62
            readonly property int footerHeight: 30
            readonly property bool expanded: launcherWindow.searchText !== ""
            readonly property int panesHeight: {
                if (!expanded) return 0;
                var natural = 24 + footerHeight;
                for (var i = 0; i < launcherWindow.rows.length; i++) {
                    natural += (launcherWindow.rows[i].type === "header" ? headerHeight : itemHeight) + itemSpacing;
                }
                var floor = launcherWindow.previewIsCodeSurface ? 340 : 220;
                return Math.max(floor, Math.min(launcherWindow.height * 0.62, natural));
            }

            height: searchHeight + (expanded ? panesHeight + 10 : 0)

            Behavior on height {
                NumberAnimation { duration: 220; easing.type: Easing.OutCubic }
            }

            ColumnLayout {
                anchors.fill: parent
                spacing: 10

                Rectangle {
                    id: searchCard
                    Layout.fillWidth: true
                    Layout.preferredHeight: launcherBox.searchHeight
                    radius: 12
                    color: Theme.surfaceBg
                    clip: true

                    // Swallow clicks so the outer dismiss MouseArea doesn't fire
                    MouseArea {
                        anchors.fill: parent
                        onClicked: {}
                    }

                    // Lighter pulse sweeping left → right across the darker card background
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
                            to: searchCard.width
                            duration: 3200
                            loops: Animation.Infinite
                            running: launcherWindow.isOnThisScreen
                            easing.type: Easing.InOutSine
                        }
                    }

                    Rectangle {
                        anchors.fill: parent
                        anchors.margins: 12
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
                            Keys.onReturnPressed: launcherWindow.activateSelected()
                            Keys.onDownPressed: launcherWindow.moveSelection(1)
                            Keys.onUpPressed: launcherWindow.moveSelection(-1)

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
                }

                RowLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    spacing: 10
                    opacity: launcherBox.expanded ? 1 : 0
                    Behavior on opacity { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

                    Rectangle {
                        id: selectionPane
                        Layout.fillHeight: true
                        Layout.fillWidth: true
                        Layout.preferredWidth: 1
                        radius: 12
                        color: Theme.surfaceBg
                        clip: true

                        MouseArea {
                            anchors.fill: parent
                            onClicked: {}
                        }

                        Text {
                            anchors.centerIn: parent
                            visible: launcherWindow.rows.length === 0
                            text: "No matches"
                            color: Theme.textDim
                            font.pixelSize: Theme.fontBody
                        }

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: 10
                            spacing: 0

                            ListView {
                                id: resultList
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                clip: true
                                model: launcherWindow.rows
                                currentIndex: launcherWindow.selectedRow
                                onCurrentIndexChanged: if (currentIndex >= 0) positionViewAtIndex(currentIndex, ListView.Contain)
                                spacing: launcherBox.itemSpacing
                                boundsBehavior: Flickable.StopAtBounds

                                add: Transition {
                                    NumberAnimation { property: "opacity"; from: 0; to: 1; duration: 160; easing.type: Easing.OutCubic }
                                    NumberAnimation { property: "y"; from: 8; duration: 160; easing.type: Easing.OutCubic }
                                }
                                displaced: Transition {
                                    NumberAnimation { properties: "y"; duration: 160; easing.type: Easing.OutCubic }
                                }

                                delegate: Item {
                                    id: resultRow
                                    required property int index
                                    required property var modelData
                                    readonly property bool isHeader: modelData.type === "header"
                                    width: ListView.view.width
                                    height: isHeader ? launcherBox.headerHeight : launcherBox.itemHeight

                                    RowLayout {
                                        visible: resultRow.isHeader
                                        anchors.fill: parent
                                        anchors.leftMargin: 10
                                        anchors.rightMargin: 10
                                        spacing: 8

                                        Text {
                                            text: resultRow.isHeader ? resultRow.modelData.label.toUpperCase() : ""
                                            color: Theme.textDim
                                            font.pixelSize: Theme.fontCaption
                                            font.weight: Font.DemiBold
                                            font.letterSpacing: 1
                                        }

                                        Rectangle {
                                            Layout.fillWidth: true
                                            Layout.alignment: Qt.AlignVCenter
                                            height: 1
                                            color: Theme.surfaceStrong
                                        }

                                        Text {
                                            text: resultRow.isHeader ? String(resultRow.modelData.count) : ""
                                            color: Theme.iconDim
                                            font.pixelSize: Theme.fontCaption
                                        }
                                    }

                                    Rectangle {
                                        visible: !resultRow.isHeader
                                        anchors.fill: parent
                                        radius: 6
                                        color: resultRow.index === launcherWindow.selectedRow
                                            ? Theme.surfaceActive
                                            : rowHover.containsMouse ? Theme.surfaceStrong
                                            : "transparent"

                                        Behavior on color { ColorAnimation { duration: 100 } }

                                        RowLayout {
                                            anchors.fill: parent
                                            anchors.leftMargin: 10
                                            anchors.rightMargin: 10
                                            spacing: 10

                                            ResultIcon {
                                                iconSize: 26
                                                iconNames: resultRow.isHeader ? [] : launcherWindow.rowIconNames(resultRow.modelData)
                                                fallbackText: resultRow.isHeader ? "" : launcherWindow.rowIconFallback(resultRow.modelData)
                                                Layout.preferredWidth: 26
                                                Layout.preferredHeight: 26
                                                Layout.alignment: Qt.AlignVCenter
                                            }

                                            Column {
                                                Layout.fillWidth: true
                                                Layout.alignment: Qt.AlignVCenter
                                                spacing: 2

                                                Text {
                                                    text: resultRow.isHeader
                                                        ? ""
                                                        : launcherWindow.highlightMatch(launcherWindow.rowTitle(resultRow.modelData), launcherWindow.searchText)
                                                    textFormat: Text.StyledText
                                                    color: Theme.text
                                                    font.pixelSize: Theme.fontTitle
                                                    font.bold: true
                                                    elide: Text.ElideRight
                                                    width: parent.width
                                                }

                                                Text {
                                                    visible: text !== ""
                                                    text: resultRow.isHeader ? "" : launcherWindow.rowSubtitle(resultRow.modelData)
                                                    color: Theme.textDim
                                                    font.pixelSize: Theme.fontLabel
                                                    elide: Text.ElideLeft
                                                    width: parent.width
                                                }
                                            }

                                            Text {
                                                text: resultRow.isHeader ? "" : launcherWindow.rowKind(resultRow.modelData)
                                                color: Theme.iconDim
                                                font.pixelSize: Theme.fontLabel
                                                Layout.alignment: Qt.AlignVCenter
                                            }
                                        }

                                        MouseArea {
                                            id: rowHover
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onPositionChanged: launcherWindow.selectedRow = resultRow.index
                                            onClicked: {
                                                launcherWindow.selectedRow = resultRow.index;
                                                launcherWindow.activateSelected();
                                            }
                                        }
                                    }
                                }
                            }

                            Rectangle {
                                Layout.fillWidth: true
                                Layout.preferredHeight: launcherBox.footerHeight
                                color: "transparent"

                                Text {
                                    anchors.centerIn: parent
                                    text: "Enter: Open  •  ↑↓: Navigate  •  Esc: Close"
                                    color: Theme.iconDim
                                    font.pixelSize: Theme.fontCaption
                                }
                            }
                        }
                    }

                    Rectangle {
                        id: previewPane
                        Layout.fillHeight: true
                        Layout.fillWidth: true
                        Layout.preferredWidth: 1
                        radius: 12
                        color: Theme.surfaceBg
                        clip: true

                        MouseArea {
                            anchors.fill: parent
                            onClicked: {}
                        }

                        readonly property var row: launcherWindow.selected

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: 18
                            spacing: 14
                            visible: previewPane.row !== null

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 14

                                Rectangle {
                                    Layout.preferredWidth: 46
                                    Layout.preferredHeight: 46
                                    Layout.alignment: Qt.AlignTop
                                    radius: 10
                                    color: Theme.surfaceInner

                                    ResultIcon {
                                        anchors.centerIn: parent
                                        width: 30
                                        height: 30
                                        iconSize: 30
                                        iconNames: launcherWindow.rowIconNames(previewPane.row)
                                        fallbackText: launcherWindow.rowIconFallback(previewPane.row)
                                    }
                                }

                                Column {
                                    Layout.fillWidth: true
                                    Layout.alignment: Qt.AlignTop
                                    spacing: 6

                                    Text {
                                        text: launcherWindow.rowTitle(previewPane.row)
                                        color: Theme.text
                                        font.pixelSize: 16
                                        font.bold: true
                                        elide: Text.ElideRight
                                        width: parent.width
                                    }

                                    Row {
                                        spacing: 8

                                        Text {
                                            text: {
                                                var r = previewPane.row;
                                                if (!r) return "";
                                                if (r.type === "app") return "APPLICATION";
                                                if (r.type === "file") return "FILE";
                                                if (r.type === "dir") return "FOLDER";
                                                if (r.type === "session") return "TMUX SESSION";
                                                return "CALCULATOR";
                                            }
                                            color: Theme.textDim
                                            font.pixelSize: Theme.fontCaption
                                            font.weight: Font.DemiBold
                                            font.letterSpacing: 1
                                        }

                                        Text {
                                            visible: text !== ""
                                            text: previewPane.row && previewPane.row.type === "file"
                                                ? launcherWindow.formatSize(previewPane.row.size)
                                                : ""
                                            color: Theme.iconDim
                                            font.pixelSize: Theme.fontCaption
                                        }
                                    }
                                }
                            }

                            Rectangle {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 1
                                color: Theme.surfaceStrong
                            }

                            GridLayout {
                                Layout.fillWidth: true
                                Layout.alignment: Qt.AlignTop
                                columns: 2
                                columnSpacing: 18
                                rowSpacing: 10

                                Repeater {
                                    model: {
                                        var r = previewPane.row;
                                        if (!r) return [];
                                        if (r.type === "file") return [
                                            { key: "Path", value: launcherWindow.shortenPath(r.path) },
                                            { key: "Modified", value: launcherWindow.formatTime(r.mtime) },
                                            { key: "Enter", value: "Open in Neovim" }
                                        ];
                                        if (r.type === "dir") return [
                                            { key: "Path", value: launcherWindow.shortenPath(r.path) },
                                            { key: "Modified", value: launcherWindow.formatTime(r.mtime) },
                                            { key: "Enter", value: "Open in Nautilus" }
                                        ];
                                        if (r.type === "session") return [
                                            { key: "Windows", value: String(r.windows) },
                                            { key: "Attached", value: r.attached ? "yes" : "no" },
                                            { key: "Path", value: launcherWindow.shortenPath(r.path) },
                                            { key: "Last activity", value: launcherWindow.formatTime(r.activity) },
                                            { key: "Enter", value: "Attach in kitty" }
                                        ];
                                        if (r.type === "calc") return [
                                            { key: "Expression", value: r.expr },
                                            { key: "Result", value: r.result },
                                            { key: "Enter", value: "Copy to clipboard" }
                                        ];
                                        return [
                                            { key: "Command", value: launcherWindow.commandOf(r.entry) },
                                            { key: "Categories", value: (r.entry.categories || []).join(", ") },
                                            { key: "Description", value: r.entry.comment || r.entry.genericName || "" }
                                        ];
                                    }

                                    delegate: Item {
                                        id: detailRow
                                        required property var modelData
                                        Layout.columnSpan: 2
                                        Layout.fillWidth: true
                                        implicitHeight: Math.max(keyText.implicitHeight, valueText.implicitHeight)
                                        visible: detailRow.modelData.value !== ""

                                        Text {
                                            id: keyText
                                            anchors.left: detailRow.left
                                            anchors.top: detailRow.top
                                            width: 96
                                            text: detailRow.modelData.key
                                            color: Theme.textDim
                                            font.pixelSize: Theme.fontBody
                                        }

                                        Text {
                                            id: valueText
                                            anchors.left: keyText.right
                                            anchors.right: detailRow.right
                                            anchors.top: detailRow.top
                                            text: detailRow.modelData.value
                                            color: Theme.text
                                            font.pixelSize: Theme.fontBody
                                            horizontalAlignment: Text.AlignRight
                                            elide: Text.ElideMiddle
                                        }
                                    }
                                }
                            }

                            Rectangle {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                visible: launcherWindow.previewIsCodeSurface
                                radius: 8
                                color: "transparent"
                                clip: true

                                Flickable {
                                    anchors.fill: parent
                                    anchors.margins: 10
                                    visible: launcherWindow.previewMode === "text" || launcherWindow.previewMode === "html"
                                    contentWidth: previewText.implicitWidth
                                    contentHeight: previewText.implicitHeight
                                    boundsBehavior: Flickable.StopAtBounds
                                    clip: true

                                    Text {
                                        id: previewText
                                        text: launcherWindow.previewBody
                                        textFormat: launcherWindow.previewMode === "html"
                                            ? Text.RichText
                                            : Text.PlainText
                                        color: Theme.text
                                        font.family: Theme.fontMono
                                        font.pixelSize: 12
                                    }
                                }

                                Image {
                                    anchors.fill: parent
                                    anchors.margins: 10
                                    visible: launcherWindow.previewMode === "image"
                                    source: launcherWindow.previewMode === "image" && launcherWindow.selectedFilePath !== ""
                                        ? launcherWindow.fileUrl(launcherWindow.selectedFilePath)
                                        : ""
                                    fillMode: Image.PreserveAspectFit
                                    asynchronous: true
                                    smooth: true
                                }

                                Text {
                                    anchors.centerIn: parent
                                    visible: launcherWindow.previewMode === "binary"
                                    text: "Binary file"
                                    color: Theme.iconDim
                                    font.pixelSize: Theme.fontBody
                                }
                            }

                            Item {
                                Layout.fillHeight: true
                                visible: !launcherWindow.previewIsCodeSurface
                            }
                        }

                        Text {
                            anchors.centerIn: parent
                            visible: previewPane.row === null
                            text: "Nothing selected"
                            color: Theme.textDim
                            font.pixelSize: Theme.fontBody
                        }
                    }
                }
            }
        }
    }
}
