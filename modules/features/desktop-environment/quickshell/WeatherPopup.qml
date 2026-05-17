import Quickshell
import QtQuick
import "."

Variants {
    id: root
    required property var shell
    model: Quickshell.screens

    function conditionToIconType(c) {
        if (!c) return "cloudy";
        if (c.indexOf("thunder") !== -1) return "thunder";
        if (c.indexOf("snow") !== -1 || c.indexOf("sleet") !== -1 || c.indexOf("blizzard") !== -1 || c.indexOf("ice") !== -1) return "snow";
        if (c.indexOf("rain") !== -1 || c.indexOf("drizzle") !== -1 || c.indexOf("shower") !== -1) return "rain";
        if (c.indexOf("mist") !== -1 || c.indexOf("fog") !== -1 || c.indexOf("haze") !== -1) return "fog";
        if (c.indexOf("partly") !== -1 || c.indexOf("patchy") !== -1) return "partlycloudy";
        if (c.indexOf("cloud") !== -1 || c.indexOf("overcast") !== -1) return "cloudy";
        if (c.indexOf("sunny") !== -1 || c.indexOf("clear") !== -1) return "sunny";
        return "cloudy";
    }

    function weatherCodeToIconType(code) {
        if (code === 0) return "sunny";
        if (code === 1 || code === 2) return "partlycloudy";
        if (code === 3) return "cloudy";
        if (code === 45 || code === 48) return "fog";
        if (code === 95 || code === 96 || code === 99) return "thunder";
        if ((code >= 71 && code <= 77) || code === 85 || code === 86) return "snow";
        if ((code >= 51 && code <= 67) || (code >= 80 && code <= 82)) return "rain";
        return "cloudy";
    }

    function dayNameFor(dateStr) {
        var parts = dateStr.split("-");
        var dt = new Date(parseInt(parts[0]), parseInt(parts[1]) - 1, parseInt(parts[2]));
        var names = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"];
        return names[dt.getDay()];
    }

    function compassFor(deg) {
        if (deg === null || deg === undefined) return "";
        var dirs = ["N", "NE", "E", "SE", "S", "SW", "W", "NW"];
        return dirs[Math.round(deg / 45) % 8];
    }

    // Tinted backdrop color, derived from the current condition. Subtle so the
    // content still reads cleanly; the alpha keeps it translucent like other popups.
    function backdropFor(iconType) {
        if (Theme.isDark) {
            if (iconType === "sunny")        return Qt.rgba(0.18, 0.12, 0.04, 0.55);
            if (iconType === "partlycloudy") return Qt.rgba(0.08, 0.11, 0.18, 0.55);
            if (iconType === "rain")         return Qt.rgba(0.05, 0.10, 0.22, 0.58);
            if (iconType === "snow")         return Qt.rgba(0.08, 0.15, 0.20, 0.55);
            if (iconType === "thunder")      return Qt.rgba(0.10, 0.05, 0.20, 0.60);
            if (iconType === "fog")          return Qt.rgba(0.10, 0.10, 0.12, 0.55);
            return Qt.rgba(0.07, 0.08, 0.10, 0.55); // cloudy
        } else {
            if (iconType === "sunny")        return Qt.rgba(1.00, 0.92, 0.70, 0.45);
            if (iconType === "partlycloudy") return Qt.rgba(0.85, 0.90, 1.00, 0.40);
            if (iconType === "rain")         return Qt.rgba(0.75, 0.85, 1.00, 0.42);
            if (iconType === "snow")         return Qt.rgba(0.85, 0.95, 1.00, 0.42);
            if (iconType === "thunder")      return Qt.rgba(0.78, 0.72, 1.00, 0.42);
            if (iconType === "fog")          return Qt.rgba(0.86, 0.86, 0.88, 0.40);
            return Qt.rgba(0.80, 0.82, 0.85, 0.38); // cloudy
        }
    }

    BasePopup {
        id: popup
        shell: root.shell
        popupName: "weather"
        popupWidth: 560

        anchors.right: false
        anchors.left: true
        margins.right: 0
        margins.left: popup.screen ? Math.max(8, (popup.screen.width - popup.popupWidth) / 2) : 8

        backgroundColor: root.backdropFor(root.conditionToIconType(root.shell.weatherCondition))

        property real animTime: 0
        Timer {
            interval: 50
            running: popup.visible
            repeat: true
            onTriggered: popup.animTime += 0.05
        }

        readonly property var upcoming: root.shell.weatherForecast.length > 1
            ? root.shell.weatherForecast.slice(1)
            : []
        readonly property var today: root.shell.weatherForecast.length > 0
            ? root.shell.weatherForecast[0]
            : null

        // Header
        Item {
            width: parent.width
            height: 18

            Text {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                text: "Weather"
                color: Theme.text
                font.pixelSize: 13
                font.bold: true
            }

            Text {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                visible: root.shell.weatherLocationName !== ""
                text: root.shell.weatherLocationName
                color: Theme.textDim
                font.pixelSize: 11
                elide: Text.ElideRight
            }
        }

        // Top row: single horizontal banner — icon, temp, condition · stats.
        Item {
            id: topBanner
            width: parent.width
            height: 48

            Row {
                anchors.centerIn: parent
                spacing: 12

                WeatherIcon {
                    anchors.verticalCenter: parent.verticalCenter
                    iconSize: 40
                    iconType: root.conditionToIconType(root.shell.weatherCondition)
                    animTime: popup.animTime
                }

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.shell.weatherTemp !== "" ? root.shell.weatherTemp : "—"
                    color: Theme.text
                    font.pixelSize: 26
                    font.bold: true
                }

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    visible: root.shell.weatherCondition !== ""
                    text: {
                        var c = root.shell.weatherCondition;
                        return c.length > 0 ? c.charAt(0).toUpperCase() + c.slice(1) : "";
                    }
                    color: Theme.textDim
                    font.pixelSize: 13
                }

                // ·
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    visible: popup.today !== null
                    text: "·"
                    color: Theme.iconDim
                    font.pixelSize: 14
                }

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    visible: popup.today !== null
                    text: popup.today ? popup.today.tempMax + "°/" + popup.today.tempMin + "°" : ""
                    color: Theme.text
                    font.pixelSize: 13
                }

                // ·
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    visible: popup.today && popup.today.humidity !== null
                    text: "·"
                    color: Theme.iconDim
                    font.pixelSize: 14
                }

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    visible: popup.today && popup.today.humidity !== null
                    text: popup.today ? popup.today.humidity + "%" : ""
                    color: Theme.textDim
                    font.pixelSize: 13
                }

            }
        }

        // Separator
        Rectangle {
            width: parent.width
            height: 1
            color: Theme.surfaceInner
        }

        // Loading placeholder
        Text {
            visible: popup.upcoming.length === 0
            text: "Loading forecast…"
            color: Theme.textDim
            font.pixelSize: 12
            anchors.horizontalCenter: parent.horizontalCenter
        }

        // All upcoming days laid out as cards in one row.
        Row {
            id: forecastRow
            visible: popup.upcoming.length > 0
            width: parent.width
            spacing: 6

            Repeater {
                model: popup.upcoming

                Rectangle {
                    id: card
                    required property var modelData
                    required property int index

                    width: (forecastRow.width - forecastRow.spacing * (popup.upcoming.length - 1)) / popup.upcoming.length
                    height: 145
                    radius: 10
                    color: Theme.surfaceInner
                    border.color: Theme.surfaceSubtle
                    border.width: 1

                    // Day name pinned to the top
                    Text {
                        id: dayLabel
                        anchors.top: parent.top
                        anchors.topMargin: 4
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: root.dayNameFor(card.modelData.date)
                        color: Theme.text
                        font.pixelSize: 12
                        font.bold: true
                    }

                    // Icon + stats grouped tightly together, centered in the area below the day name
                    Column {
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.verticalCenterOffset: 6
                        anchors.horizontalCenter: parent.horizontalCenter
                        spacing: 2

                        WeatherIcon {
                            anchors.horizontalCenter: parent.horizontalCenter
                            iconSize: 40
                            iconType: root.weatherCodeToIconType(card.modelData.weatherCode)
                            animTime: popup.animTime + card.index * 0.37
                        }

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: card.modelData.tempMax + "°"
                            color: Theme.text
                            font.pixelSize: 14
                            font.bold: true
                        }

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: card.modelData.tempMin + "°"
                            color: Theme.textDim
                            font.pixelSize: 11
                        }

                        Row {
                            anchors.horizontalCenter: parent.horizontalCenter
                            spacing: 3

                            Canvas {
                                width: 7
                                height: 10
                                anchors.verticalCenter: parent.verticalCenter
                                visible: card.modelData.precipChance > 0
                                property color dropColor: Qt.rgba(0.55, 0.75, 1.0, 0.95)
                                onAvailableChanged: if (available) requestPaint()
                                onPaint: {
                                    var ctx = getContext("2d");
                                    ctx.clearRect(0, 0, width, height);
                                    ctx.fillStyle = dropColor;
                                    ctx.beginPath();
                                    ctx.moveTo(3.5, 1);
                                    ctx.bezierCurveTo(6, 4, 6.5, 7, 3.5, 9);
                                    ctx.bezierCurveTo(0.5, 7, 1, 4, 3.5, 1);
                                    ctx.closePath();
                                    ctx.fill();
                                }
                            }

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: (card.modelData.precipChance > 0 ? card.modelData.precipChance : 0) + "%"
                                color: Theme.textDim
                                font.pixelSize: 10
                            }
                        }

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: card.modelData.humidity !== null
                                ? card.modelData.humidity + "% hum"
                                : "—"
                            color: Theme.textDim
                            font.pixelSize: 10
                        }
                    }
                }
            }
        }
    }
}
