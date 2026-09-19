import Quickshell
import QtQuick
import "."

Item {
    id: root
    required property var shell
    property bool shown: false
    property real travel: 40

    readonly property int spacing: 10
    readonly property int collapsedHeight: 148
    readonly property int expandedHeight: 320
    readonly property bool mediaVisible: shell.mprisPlayer !== null
    readonly property int cardCount: 3 + (mediaVisible ? 1 : 0) + (shell.hasBattery ? 1 : 0)
    readonly property real cardWidth: (width - (cardCount - 1) * spacing) / cardCount

    // -1 when every card is collapsed, otherwise the open card's slot.
    property int expandedSlot: -1

    implicitHeight: expandedSlot >= 0 ? expandedHeight : collapsedHeight
    Behavior on implicitHeight {
        NumberAnimation { duration: 220; easing.type: Easing.OutCubic }
    }

    onShownChanged: if (!shown) expandedSlot = -1;

    function titleCase(s) {
        return s.length > 0 ? s.charAt(0).toUpperCase() + s.slice(1) : "";
    }

    function toggleSlot(slot) {
        expandedSlot = expandedSlot === slot ? -1 : slot;
    }

    // Entry stagger counts visible cards, so a hidden media card doesn't leave
    // a gap in the sequence.
    function staggerFor(slot) {
        return slot - (slot > 2 && !mediaVisible ? 1 : 0);
    }

    component InfoCard: Rectangle {
        id: card
        property int slot: 0
        property bool expandable: false

        readonly property bool expanded: card.expandable && root.expandedSlot === card.slot

        width: root.cardWidth
        height: card.expanded ? root.expandedHeight : root.collapsedHeight
        radius: 12
        color: Theme.surfaceBg
        clip: true

        Behavior on height {
            NumberAnimation { duration: 220; easing.type: Easing.OutCubic }
        }

        opacity: root.shown ? 1 : 0
        Behavior on opacity {
            NumberAnimation { duration: 140; easing.type: Easing.OutCubic }
        }

        transform: Translate {
            y: root.shown ? 0 : root.travel
            Behavior on y {
                SequentialAnimation {
                    PauseAnimation { duration: root.staggerFor(card.slot) * 60 }
                    NumberAnimation { duration: 260; easing.type: Easing.OutCubic }
                }
            }
        }

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.LeftButton
            onClicked: {
                if (card.expandable) root.toggleSlot(card.slot);
                else root.expandedSlot = -1;
            }
        }

        Canvas {
            id: chevron
            visible: card.expandable
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.rightMargin: 10
            anchors.topMargin: 10
            width: 12
            height: 12

            property color strokeColor: card.expanded ? Theme.text : Theme.iconDim
            onStrokeColorChanged: if (available) requestPaint()
            onAvailableChanged: if (available) requestPaint()

            onPaint: {
                var ctx = getContext("2d");
                ctx.clearRect(0, 0, width, height);
                ctx.strokeStyle = strokeColor;
                ctx.lineWidth = 1.4;
                ctx.lineCap = "round";
                ctx.beginPath();
                ctx.moveTo(2.5, 4.5);
                ctx.lineTo(6, 8);
                ctx.lineTo(9.5, 4.5);
                ctx.stroke();
            }

            transform: Rotation {
                origin.x: 6
                origin.y: 6
                angle: card.expanded ? 180 : 0
                Behavior on angle { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
            }
        }
    }

    component Meter: Item {
        id: meter
        property string label: ""
        property string value: ""
        property real fraction: 0
        property var history: null
        property color barColor: Theme.graphRam

        width: parent ? parent.width : 0
        height: 28

        Text {
            anchors.left: parent.left
            anchors.top: parent.top
            text: meter.label
            color: Theme.textDim
            font.pixelSize: Theme.fontCaption
            font.weight: Font.DemiBold
            font.letterSpacing: 0.6
        }

        Text {
            anchors.right: parent.right
            anchors.top: parent.top
            text: meter.value
            color: Theme.text
            font.pixelSize: Theme.fontCaption
            font.bold: true
        }

        HistoryGraph {
            anchors.bottom: parent.bottom
            visible: meter.history !== null
            width: parent.width
            height: 14
            history: meter.history !== null ? meter.history : []
            level: meter.fraction
            lineColor: Qt.rgba(meter.barColor.r, meter.barColor.g, meter.barColor.b, 0.9)
            showGrid: false
            areaAlpha: 0.18
            lineWidth: 1.2
        }

        Rectangle {
            anchors.bottom: parent.bottom
            visible: meter.history === null
            width: parent.width
            height: 4
            radius: 2
            color: Theme.surfaceStrong

            Rectangle {
                width: parent.width * Math.max(0, Math.min(1, meter.fraction))
                height: parent.height
                radius: 2
                color: meter.barColor
                Behavior on width { NumberAnimation { duration: 300 } }
            }
        }
    }

    component TransportButton: Rectangle {
        id: btn
        property string glyph: ""
        signal activated()

        width: 26
        height: 26
        radius: 13
        color: hover.containsMouse ? Theme.buttonHover : "transparent"

        Text {
            anchors.centerIn: parent
            text: btn.glyph
            color: btn.enabled ? Theme.text : Theme.iconDim
            font.pixelSize: 13
        }

        MouseArea {
            id: hover
            anchors.fill: parent
            hoverEnabled: true
            onClicked: btn.activated()
        }
    }

    component DetailRow: Item {
        id: detail
        property string label: ""
        property string value: ""

        width: parent ? parent.width : 0
        height: 17

        Text {
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            text: detail.label
            color: Theme.textDim
            font.pixelSize: Theme.fontCaption
        }

        Text {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            text: detail.value
            color: Theme.text
            font.pixelSize: Theme.fontCaption
            font.bold: true
        }
    }

    Row {
        width: parent.width
        spacing: root.spacing

        InfoCard {
            id: weatherCard
            slot: 0
            expandable: true

            readonly property string caption: {
                var parts = [];
                if (root.shell.weatherCondition !== "") parts.push(root.titleCase(root.shell.weatherCondition));
                if (root.shell.weatherLocationName !== "") parts.push(root.shell.weatherLocationName);
                return parts.join(" · ");
            }

            Column {
                anchors.fill: parent
                anchors.margins: 14
                spacing: 10

                Row {
                    width: parent.width - 18
                    spacing: 10

                    WeatherIcon {
                        anchors.verticalCenter: parent.verticalCenter
                        iconSize: 34
                        iconType: root.shell.conditionToIconType(root.shell.weatherCondition)
                        animTime: root.shell.weatherAnimTime
                    }

                    Column {
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width - 44
                        spacing: 1

                        Text {
                            text: root.shell.weatherTemp !== "" ? root.shell.weatherTemp : "—"
                            color: Theme.text
                            font.pixelSize: 22
                            font.bold: true
                        }

                        Text {
                            width: parent.width
                            text: weatherCard.caption !== "" ? weatherCard.caption : "No weather data"
                            color: Theme.textDim
                            font.pixelSize: Theme.fontCaption
                            elide: Text.ElideRight
                        }
                    }
                }

                Row {
                    width: parent.width
                    spacing: 6
                    visible: !weatherCard.expanded

                    Repeater {
                        model: root.shell.weatherForecast.slice(1, 4)

                        Rectangle {
                            id: forecastCell
                            required property var modelData
                            required property int index

                            width: (parent.width - 12) / 3
                            height: 58
                            radius: 8
                            color: Theme.surfaceInner

                            Column {
                                anchors.centerIn: parent
                                spacing: 1

                                Text {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    text: root.shell.dayNameFor(forecastCell.modelData.date)
                                    color: Theme.textDim
                                    font.pixelSize: Theme.fontCaption
                                    font.bold: true
                                }

                                WeatherIcon {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    iconSize: 22
                                    iconType: root.shell.weatherCodeToIconType(forecastCell.modelData.weatherCode)
                                    animTime: root.shell.weatherAnimTime + forecastCell.index * 0.37
                                }

                                Text {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    text: forecastCell.modelData.tempMax + "° / " + forecastCell.modelData.tempMin + "°"
                                    color: Theme.text
                                    font.pixelSize: Theme.fontCaption
                                }
                            }
                        }
                    }
                }

                Column {
                    width: parent.width
                    spacing: 2
                    visible: weatherCard.expanded

                    Repeater {
                        model: weatherCard.expanded ? root.shell.weatherForecast : []

                        Item {
                            id: dayRow
                            required property var modelData
                            required property int index

                            width: parent.width
                            height: 24

                            Text {
                                anchors.left: parent.left
                                anchors.verticalCenter: parent.verticalCenter
                                width: 30
                                text: dayRow.index === 0 ? "Today" : root.shell.dayNameFor(dayRow.modelData.date)
                                color: dayRow.index === 0 ? Theme.text : Theme.textDim
                                font.pixelSize: Theme.fontCaption
                                font.bold: dayRow.index === 0
                                elide: Text.ElideRight
                            }

                            WeatherIcon {
                                anchors.left: parent.left
                                anchors.leftMargin: 34
                                anchors.verticalCenter: parent.verticalCenter
                                iconSize: 18
                                iconType: root.shell.weatherCodeToIconType(dayRow.modelData.weatherCode)
                                animTime: root.shell.weatherAnimTime + dayRow.index * 0.37
                            }

                            Text {
                                anchors.left: parent.left
                                anchors.leftMargin: 58
                                anchors.verticalCenter: parent.verticalCenter
                                text: dayRow.modelData.tempMax + "° / " + dayRow.modelData.tempMin + "°"
                                color: Theme.text
                                font.pixelSize: Theme.fontCaption
                            }

                            Text {
                                anchors.right: parent.right
                                anchors.verticalCenter: parent.verticalCenter
                                text: {
                                    var m = dayRow.modelData;
                                    var bits = [];
                                    if (m.precipChance > 0) bits.push(m.precipChance + "%");
                                    if (m.humidity !== null && m.humidity !== undefined) bits.push(m.humidity + "rh");
                                    if (m.windSpeed !== null && m.windSpeed !== undefined)
                                        bits.push(m.windSpeed + " " + root.shell.compassFor(m.windDir));
                                    return bits.join("  ");
                                }
                                color: Theme.textDim
                                font.pixelSize: Theme.fontCaption
                                elide: Text.ElideRight
                            }
                        }
                    }
                }
            }
        }

        InfoCard {
            id: clockCard
            slot: 1

            SystemClock {
                id: cardClock
                precision: SystemClock.Minutes
            }

            Column {
                anchors.centerIn: parent
                width: parent.width - 28
                spacing: 3

                Row {
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: 5

                    Text {
                        text: Qt.formatDateTime(cardClock.date, "h:mm")
                        color: Theme.text
                        font.pixelSize: 34
                        font.bold: true
                    }

                    Text {
                        anchors.bottom: parent.bottom
                        anchors.bottomMargin: 6
                        text: Qt.formatDateTime(cardClock.date, "AP")
                        color: Theme.textDim
                        font.pixelSize: Theme.fontBody
                        font.bold: true
                    }
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: Qt.formatDateTime(cardClock.date, "dddd")
                    color: Theme.text
                    font.pixelSize: Theme.fontBody
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: Qt.formatDateTime(cardClock.date, "d MMMM yyyy")
                    color: Theme.textDim
                    font.pixelSize: Theme.fontCaption
                }
            }
        }

        InfoCard {
            id: mediaCard
            slot: 2
            visible: root.mediaVisible

            readonly property var player: root.shell.mprisPlayer
            readonly property bool hasPlayer: player !== null
            readonly property bool isPlaying: hasPlayer && player.isPlaying

            Column {
                anchors.fill: parent
                anchors.margins: 14
                spacing: 10

                Row {
                    width: parent.width
                    spacing: 12

                    Rectangle {
                        anchors.verticalCenter: parent.verticalCenter
                        width: 52
                        height: 52
                        radius: 8
                        color: Theme.surfaceInner
                        clip: true

                        Image {
                            anchors.fill: parent
                            visible: mediaCard.hasPlayer && mediaCard.player.trackArtUrl !== ""
                            source: mediaCard.hasPlayer ? mediaCard.player.trackArtUrl : ""
                            fillMode: Image.PreserveAspectCrop
                            asynchronous: true
                            cache: true
                        }

                        MediaPlayerIcon {
                            anchors.centerIn: parent
                            visible: !mediaCard.hasPlayer || mediaCard.player.trackArtUrl === ""
                            iconSize: 26
                            iconType: mediaCard.isPlaying ? "playing" : "paused"
                            iconColor: Theme.iconDim
                            animTime: root.shell.weatherAnimTime
                        }
                    }

                    Column {
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width - 64
                        spacing: 2

                        Text {
                            width: parent.width
                            text: mediaCard.isPlaying ? "NOW PLAYING" : "PAUSED"
                            color: Theme.textDim
                            font.pixelSize: Theme.fontCaption
                            font.weight: Font.DemiBold
                            font.letterSpacing: 1
                        }

                        Text {
                            width: parent.width
                            text: mediaCard.hasPlayer && mediaCard.player.trackTitle !== ""
                                ? mediaCard.player.trackTitle
                                : "Unknown title"
                            color: Theme.text
                            font.pixelSize: Theme.fontTitle
                            font.bold: true
                            elide: Text.ElideRight
                        }

                        Text {
                            width: parent.width
                            visible: mediaCard.hasPlayer && mediaCard.player.trackArtist !== ""
                            text: mediaCard.hasPlayer ? mediaCard.player.trackArtist : ""
                            color: Theme.textDim
                            font.pixelSize: Theme.fontLabel
                            elide: Text.ElideRight
                        }
                    }
                }

                Row {
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: 10

                    TransportButton {
                        glyph: "⏮"
                        enabled: mediaCard.hasPlayer && mediaCard.player.canGoPrevious
                        onActivated: mediaCard.player.previous()
                    }

                    TransportButton {
                        glyph: mediaCard.isPlaying ? "⏸" : "⏵"
                        enabled: mediaCard.hasPlayer && mediaCard.player.canTogglePlaying
                        onActivated: mediaCard.player.togglePlaying()
                    }

                    TransportButton {
                        glyph: "⏭"
                        enabled: mediaCard.hasPlayer && mediaCard.player.canGoNext
                        onActivated: mediaCard.player.next()
                    }
                }
            }

        }

        InfoCard {
            id: systemCard
            slot: 3
            expandable: true

            readonly property color diskColor: Qt.rgba(0.6, 0.5, 0.8, 0.7)
            readonly property real netTop: Math.max(1, root.shell.netRxPeak)

            Column {
                anchors.fill: parent
                anchors.margins: 14
                spacing: 6

                Meter {
                    label: "CPU"
                    value: root.shell.cpuPercent.toFixed(0) + "%"
                        + (root.shell.cpuTemp > 0 ? "  " + root.shell.cpuTemp + "°C" : "")
                    fraction: root.shell.cpuPercent / 100
                    history: root.shell.cpuHistoryCount >= 2 ? root.shell.cpuHistory : null
                    barColor: Theme.graphCpu
                }

                Meter {
                    label: "RAM"
                    value: root.shell.ramUsedGb.toFixed(1) + " / " + root.shell.ramTotalGb.toFixed(1) + " GB"
                    fraction: root.shell.ramPercent / 100
                    history: root.shell.ramHistoryCount >= 2 ? root.shell.ramHistory : null
                    barColor: Theme.graphRam
                }

                Meter {
                    label: "DISK"
                    value: root.shell.diskUsed + " / " + root.shell.diskTotal
                    fraction: root.shell.diskPercent / 100
                    barColor: systemCard.diskColor
                }

                Item {
                    width: parent.width
                    height: 14

                    Text {
                        anchors.left: parent.left
                        text: "↓ " + root.shell.formatBytesPerSec(root.shell.netRxRate)
                        color: Qt.rgba(0.4, 0.8, 0.4, 1.0)
                        font.pixelSize: Theme.fontCaption
                        font.bold: true
                    }

                    Text {
                        anchors.right: parent.right
                        text: "↑ " + root.shell.formatBytesPerSec(root.shell.netTxRate)
                        color: Qt.rgba(0.95, 0.6, 0.3, 1.0)
                        font.pixelSize: Theme.fontCaption
                        font.bold: true
                    }
                }

                Column {
                    width: parent.width
                    spacing: 6
                    visible: systemCard.expanded

                    Text {
                        text: "NETWORK"
                        color: Theme.textDim
                        font.pixelSize: Theme.fontCaption
                        font.weight: Font.DemiBold
                        font.letterSpacing: 0.6
                    }

                    HistoryGraph {
                        width: parent.width
                        height: 40
                        history: systemCard.expanded ? root.shell.netRxHistory : []
                        maxValue: systemCard.netTop
                        lineColor: Qt.rgba(0.4, 0.8, 0.4, 0.9)
                    }

                    HistoryGraph {
                        width: parent.width
                        height: 40
                        history: systemCard.expanded ? root.shell.netTxHistory : []
                        maxValue: systemCard.netTop
                        lineColor: Qt.rgba(0.95, 0.6, 0.3, 0.9)
                    }

                    DetailRow {
                        label: "Peak down"
                        value: root.shell.formatBytesPerSec(root.shell.netRxPeak)
                    }
                }
            }
        }

        InfoCard {
            id: batteryCard
            slot: 4
            visible: root.shell.hasBattery

            readonly property color levelColor: root.shell.batteryCharging ? Theme.toggleGreen
                : root.shell.batteryPercent <= 10 ? Theme.accentDanger
                : root.shell.batteryPercent <= 20 ? Qt.rgba(0.95, 0.5, 0.15, 0.85)
                : Theme.graphRam

            Column {
                anchors.fill: parent
                anchors.margins: 14
                spacing: 8

                Row {
                    width: parent.width
                    spacing: 10

                    BatteryIcon {
                        anchors.verticalCenter: parent.verticalCenter
                        percent: root.shell.batteryPercent
                        charging: root.shell.batteryCharging
                    }

                    Column {
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width - 34
                        spacing: 1

                        Text {
                            text: root.shell.batteryPercent + "%"
                            color: Theme.text
                            font.pixelSize: 22
                            font.bold: true
                        }

                        Text {
                            width: parent.width
                            text: root.shell.batteryCharging ? "Charging" : root.titleCase(root.shell.batteryStatus)
                            color: Theme.textDim
                            font.pixelSize: Theme.fontCaption
                            elide: Text.ElideRight
                        }
                    }
                }

                Rectangle {
                    width: parent.width
                    height: 4
                    radius: 2
                    color: Theme.surfaceStrong

                    Rectangle {
                        width: parent.width * Math.max(0, Math.min(1, root.shell.batteryPercent / 100))
                        height: parent.height
                        radius: 2
                        color: batteryCard.levelColor
                        Behavior on width { NumberAnimation { duration: 300 } }
                    }
                }

                Column {
                    width: parent.width
                    spacing: 2

                    DetailRow {
                        label: root.shell.batteryCharging ? "Time to full" : "Time left"
                        value: root.shell.batteryTimeRemaining !== "" ? root.shell.batteryTimeRemaining : "—"
                    }

                    DetailRow {
                        label: "Power draw"
                        value: root.shell.batteryPowerDraw !== "" ? root.shell.batteryPowerDraw : "—"
                    }

                    DetailRow {
                        label: "Health"
                        value: root.shell.batteryHealthPercent + "%"
                    }
                }
            }
        }
    }
}
