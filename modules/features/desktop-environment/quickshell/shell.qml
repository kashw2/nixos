import Quickshell
import Quickshell.Hyprland
import Quickshell.Networking
import Quickshell.Services.Notifications
import Quickshell.Services.Mpris
import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import "."

ShellRoot {
    id: shell

    property bool showFullDate: true
    // Valid activePopup names: "wifi", "bt", "volume", "brightness", "battery", "notif", "sysMon", "overflow", "weather", "media"
    property string activePopup: ""
    property var activePopupScreen: null
    property string selectedNetworkName: ""
    property string passwordInput: ""
    property string eapIdentityInput: ""
    property string eapPasswordInput: ""
    property bool eapConnecting: false
    property string eapError: ""

    property var wifiDev: {
        var devs = Networking.devices.values;
        for (var i = 0; i < devs.length; i++) {
            if (devs[i].type === DeviceType.Wifi) return devs[i];
        }
        return null;
    }

    property var connectedNetwork: {
        if (!wifiDev) return null;
        var nets = wifiDev.networks.values;
        for (var i = 0; i < nets.length; i++) {
            if (nets[i].connected) return nets[i];
        }
        return null;
    }

    property bool ethernetConnected: false
    property string ethernetInterface: ""

    property bool hasBluetooth: false
    property bool bluetoothPowered: false
    property var btPairedDevices: []
    property var btConnectedDevices: []
    property var btDiscoveredDevices: []
    property bool btScanning: false

    property bool hasBattery: false
    property int batteryPercent: 0
    property bool batteryCharging: false
    property string batteryStatus: ""
    property string batteryTimeRemaining: ""
    property string batteryPowerDraw: ""
    property string powerProfile: ""
    property int batteryHealthPercent: 100
    property var batteryHistory: []
    property int batteryHistoryCount: 0
    property bool batteryHovered: false
    property var batteryHoveredScreen: null
    property real batteryIconX: 0
    property real batteryIconWidth: 0
    property int batteryLastNotifiedThreshold: 0
    readonly property var batteryThresholds: [20, 10, 5]

    property bool hasBrightness: false
    property int brightnessPercent: 0

    property int volumePercent: 0
    property bool volumeMuted: false

    property int micGainPercent: 0
    property bool micMuted: false
    property real micLevel: 0

    // Audio devices for the volume popup's output/input selectors.
    // Each entry: { id: int, name: string, isDefault: bool }
    property var audioSinks: []
    property var audioSources: []

    property string weatherCondition: ""
    property string weatherTemp: ""
    property bool weatherEffectsEnabled: true
    property string weatherEffectOverride: ""
    property string weatherEffectType: {
        if (!weatherEffectsEnabled) return "none";
        var c = weatherEffectOverride !== "" ? weatherEffectOverride : weatherCondition;
        if (c === "") return "none";
        if (c.indexOf("thunder") !== -1) return "thunder";
        if (c.indexOf("snow") !== -1 || c.indexOf("sleet") !== -1 || c.indexOf("blizzard") !== -1 || c.indexOf("ice") !== -1) return "snow";
        if (c.indexOf("rain") !== -1 || c.indexOf("drizzle") !== -1 || c.indexOf("shower") !== -1) return "rain";
        return "none";
    }
    function cycleWeatherEffect() {
        var modes = ["", "rain", "snow", "thunder"];
        var idx = modes.indexOf(weatherEffectOverride);
        weatherEffectOverride = modes[(idx + 1) % modes.length];
    }

    // Each entry: { date, weatherCode, tempMax, tempMin, precipChance }
    property var weatherForecast: []
    property string weatherLocationName: ""

    // Shared animation clock for weather icons.
    property real weatherAnimTime: 0
    Timer {
        interval: 50
        running: true
        repeat: true
        onTriggered: shell.weatherAnimTime += 0.05
    }

    // MPRIS: set by clicking a source chip in MediaPlayerPopup; cleared when that player goes away.
    property string preferredMprisPlayerDbusName: ""

    readonly property var mprisPlayer: {
        var players = Mpris.players ? Mpris.players.values : [];
        if (players.length === 0) return null;
        if (preferredMprisPlayerDbusName !== "") {
            for (var i = 0; i < players.length; i++) {
                if (players[i].dbusName === preferredMprisPlayerDbusName) return players[i];
            }
        }
        for (var j = 0; j < players.length; j++) {
            if (players[j].isPlaying) return players[j];
        }
        return players[0];
    }

    property bool toastVisible: false
    property var toastNotification: null
    property var notifHistory: []
    property int notifCount: 0

    // System monitor
    property real cpuPercent: 0
    property var cpuHistory: []
    property int cpuHistoryCount: 0
    property real cpuPrevIdle: 0
    property real cpuPrevTotal: 0
    property real ramPercent: 0
    property real ramUsedGb: 0
    property real ramTotalGb: 0
    property var ramHistory: []
    property int ramHistoryCount: 0
    property int cpuTemp: 0
    property string diskUsed: ""
    property string diskTotal: ""
    property int diskPercent: 0
    property real netRxBytes: 0
    property real netTxBytes: 0
    property real netPrevRx: 0
    property real netPrevTx: 0
    property real netPrevTime: 0
    property real netRxRate: 0
    property real netTxRate: 0
    property var netRxHistory: []
    property var netTxHistory: []
    property int netHistoryCount: 0
    property real netRxPeak: 1

    function formatBytesPerSec(bps) {
        if (bps < 1024) return bps.toFixed(0) + " B/s";
        if (bps < 1024 * 1024) return (bps / 1024).toFixed(1) + " KB/s";
        if (bps < 1024 * 1024 * 1024) return (bps / (1024 * 1024)).toFixed(1) + " MB/s";
        return (bps / (1024 * 1024 * 1024)).toFixed(2) + " GB/s";
    }

    function pushHistory(arr, value, maxLen) {
        var copy = arr.slice();
        copy.push(value);
        if (copy.length > maxLen) copy = copy.slice(copy.length - maxLen);
        return copy;
    }

    function addNotification(appName, summary, body, appIcon, image) {
        var list = shell.notifHistory.slice();
        list.unshift({
            appName: appName || "Unknown",
            summary: summary || "",
            body: body || "",
            appIcon: appIcon || "",
            image: image || "",
            time: Qt.formatDateTime(new Date(), "h:mm AP")
        });
        if (list.length > 100) list = list.slice(0, 100);
        shell.notifHistory = list;
        shell.notifCount = list.length;
    }

    function clearNotifications() {
        shell.notifHistory = [];
        shell.notifCount = 0;
    }

    function dismissNotification(index) {
        var list = shell.notifHistory.slice();
        list.splice(index, 1);
        shell.notifHistory = list;
        shell.notifCount = list.length;
    }

    function showBatteryNotification(threshold) {
        var summary = "Battery low: " + threshold + "%";
        var body = threshold <= 5
            ? "Plug in immediately — battery critical."
            : threshold <= 10
                ? "Battery very low. Connect a charger soon."
                : "Battery low. Consider plugging in.";
        addNotification("Battery", summary, body, "battery-low", "");
        toastNotification = {
            appName: "Battery",
            summary: summary,
            body: body,
            appIcon: "battery-low",
            image: ""
        };
        toastVisible = true;
        toastTimer.restart();
    }

    function checkBatteryNotifications() {
        if (!hasBattery) return;
        if (batteryCharging) {
            batteryLastNotifiedThreshold = 0;
            return;
        }
        if (batteryPercent > batteryThresholds[0]) {
            batteryLastNotifiedThreshold = 0;
            return;
        }
        for (var i = 0; i < batteryThresholds.length; i++) {
            var t = batteryThresholds[i];
            if (batteryPercent <= t && batteryLastNotifiedThreshold < t) {
                batteryLastNotifiedThreshold = t;
                showBatteryNotification(t);
                break;
            }
        }
    }

    function setBrightness(pct) {
        brightnessSet.target = pct;
        brightnessSet.running = true;
    }

    function setVolume(pct) { audioCtrl.setVolume(pct); }
    function toggleVolumeMute() { audioCtrl.toggleVolumeMute(); }
    function setMicGain(pct) { audioCtrl.setMicGain(pct); }
    function toggleMicMute() { audioCtrl.toggleMicMute(); }
    function setDefaultAudioDevice(id) { audioCtrl.setDefaultDevice(id); }

    onActivePopupChanged: {
        if (activePopup === "volume") audioCtrl.refreshDevices();
    }

    onBatteryPercentChanged: checkBatteryNotifications()
    onBatteryChargingChanged: checkBatteryNotifications()

    function setPowerProfile(profile) {
        powerProfileSet.profile = profile;
        powerProfileSet.running = true;
    }

    function openPopup(name, screen) {
        shell.activePopup = name;
        shell.activePopupScreen = screen;
    }

    function togglePopup(name, screen) {
        if (shell.activePopup === name) {
            shell.activePopup = "";
            shell.activePopupScreen = null;
        } else {
            openPopup(name, screen);
        }
    }

    function closePopup() {
        shell.activePopup = "";
        shell.activePopupScreen = null;
    }

    function toggleBluetooth() { btCtrl.toggle(); }
    function connectBluetoothDevice(mac) { btCtrl.connectDevice(mac); }
    function disconnectBluetoothDevice(mac) { btCtrl.disconnectDevice(mac); }
    function pairBluetoothDevice(mac) { btCtrl.pairDevice(mac); }
    function refreshBluetooth() { btCtrl.refresh(); }

    function startEapConnection(ssid, identity, password) {
        eapConnectionAdd.ssid = ssid;
        eapConnectionAdd.identity = identity;
        eapConnectionAdd.password = password;
        eapConnectionAdd.running = true;
    }

    NotificationServer {
        id: notifServer
        keepOnReload: true
        bodySupported: true
        actionsSupported: true
        imageSupported: true

        onNotification: notification => {
            notification.tracked = true;
            shell.addNotification(notification.appName, notification.summary, notification.body, notification.appIcon, notification.image);
            shell.toastNotification = notification;
            shell.toastVisible = true;
            toastTimer.restart();
        }
    }

    Timer {
        id: toastTimer
        interval: 5000
        onTriggered: shell.toastVisible = false
    }

    Process {
        id: batCheck
        command: ["sh", "-c", "cat /sys/class/power_supply/BAT*/capacity 2>/dev/null && echo STATUS:$(cat /sys/class/power_supply/BAT*/status 2>/dev/null)"]
        running: true
        stdout: SplitParser {
            onRead: data => {
                var line = data.toString().trim();
                if (line.startsWith("STATUS:")) {
                    var status = line.substring(7);
                    shell.batteryStatus = status;
                    shell.batteryCharging = (status === "Charging" || status === "Full");
                } else {
                    var val = parseInt(line);
                    if (!isNaN(val)) {
                        shell.hasBattery = true;
                        shell.batteryPercent = val;
                    }
                }
            }
        }
    }

    Process {
        id: batteryTimeCheck
        command: ["upower", "-i", "/org/freedesktop/UPower/devices/battery_BAT0"]
        running: true
        property bool found: false
        stdout: SplitParser {
            onRead: data => {
                var line = data.toString().trim();
                if (line.startsWith("time to empty:") || line.startsWith("time to full:")) {
                    shell.batteryTimeRemaining = line.split(":").slice(1).join(":").trim();
                    batteryTimeCheck.found = true;
                }
            }
        }
        onExited: {
            if (!found) shell.batteryTimeRemaining = "";
            found = false;
        }
    }

    Process {
        id: batteryPowerCheck
        command: ["sh", "-c", "cat /sys/class/power_supply/BAT*/power_now 2>/dev/null || (echo CALC && cat /sys/class/power_supply/BAT*/current_now /sys/class/power_supply/BAT*/voltage_now 2>/dev/null)"]
        running: true
        property var values: []
        stdout: SplitParser {
            onRead: data => {
                var line = data.toString().trim();
                if (line === "CALC") {
                    batteryPowerCheck.values = ["CALC"];
                } else {
                    batteryPowerCheck.values.push(line);
                }
            }
        }
        onExited: {
            var v = values;
            if (v.length > 0 && v[0] !== "CALC") {
                var uw = parseInt(v[0]);
                if (!isNaN(uw) && uw > 0) {
                    shell.batteryPowerDraw = (uw / 1000000).toFixed(1) + "W";
                } else {
                    shell.batteryPowerDraw = "";
                }
            } else if (v.length >= 3 && v[0] === "CALC") {
                var ua = parseInt(v[1]);
                var uv = parseInt(v[2]);
                if (!isNaN(ua) && !isNaN(uv) && ua > 0 && uv > 0) {
                    shell.batteryPowerDraw = (ua * uv / 1e12).toFixed(1) + "W";
                } else {
                    shell.batteryPowerDraw = "";
                }
            } else {
                shell.batteryPowerDraw = "";
            }
            values = [];
        }
    }

    Process {
        id: powerProfileCheck
        command: ["powerprofilesctl", "get"]
        running: true
        stdout: SplitParser {
            onRead: data => {
                shell.powerProfile = data.toString().trim();
            }
        }
    }

    Process {
        id: powerProfileSet
        property string profile: ""
        command: ["powerprofilesctl", "set", profile]
        onRunningChanged: {
            if (!running) powerProfileCheck.running = true;
        }
    }

    Process {
        id: batteryHealthCheck
        command: ["sh", "-c", "echo DESIGN:$(cat /sys/class/power_supply/BAT*/energy_full_design 2>/dev/null || cat /sys/class/power_supply/BAT*/charge_full_design 2>/dev/null) && echo FULL:$(cat /sys/class/power_supply/BAT*/energy_full 2>/dev/null || cat /sys/class/power_supply/BAT*/charge_full 2>/dev/null)"]
        running: true
        property int designEnergy: 0
        property int fullEnergy: 0
        stdout: SplitParser {
            onRead: data => {
                var line = data.toString().trim();
                if (line.startsWith("DESIGN:")) {
                    batteryHealthCheck.designEnergy = parseInt(line.substring(7)) || 0;
                } else if (line.startsWith("FULL:")) {
                    batteryHealthCheck.fullEnergy = parseInt(line.substring(5)) || 0;
                }
            }
        }
        onExited: {
            if (designEnergy > 0 && fullEnergy > 0) {
                shell.batteryHealthPercent = Math.round(fullEnergy / designEnergy * 100);
            }
            designEnergy = 0;
            fullEnergy = 0;
        }
    }

    Process {
        id: brightnessCheck
        command: ["sh", "-c", "brightnessctl -m | head -1"]
        running: true
        stdout: SplitParser {
            onRead: data => {
                var line = data.toString().trim();
                var parts = line.split(",");
                if (parts.length >= 4) {
                    shell.hasBrightness = true;
                    var pct = parseInt(parts[3]);
                    if (!isNaN(pct)) shell.brightnessPercent = pct;
                }
            }
        }
    }

    Process {
        id: brightnessSet
        property int target: 0
        command: ["brightnessctl", "set", target + "%"]
        onRunningChanged: {
            if (!running) brightnessCheck.running = true;
        }
    }

    AudioController {
        id: audioCtrl
        shell: shell
    }

    Process {
        id: ethCheck
        command: ["nmcli", "-t", "-f", "DEVICE,TYPE,STATE", "device"]
        running: true
        stdout: SplitParser {
            onRead: data => {
                var parts = data.toString().split(":");
                if (parts.length >= 3 && parts[1] === "ethernet" && parts[2] === "connected") {
                    shell.ethernetConnected = true;
                    shell.ethernetInterface = parts[0];
                }
            }
        }
    }

    Process {
        id: eapConnectionAdd
        property string ssid: ""
        property string identity: ""
        property string password: ""
        command: ["nmcli", "connection", "add", "type", "wifi", "con-name", ssid, "ssid", ssid, "wifi-sec.key-mgmt", "wpa-eap", "802-1x.eap", "peap", "802-1x.phase2-auth", "mschapv2", "802-1x.identity", identity, "802-1x.password", password]
        onExited: (code, status) => {
            if (code === 0) {
                eapConnectionUp.ssid = ssid;
                eapConnectionUp.running = true;
            } else {
                shell.eapError = "Failed to create connection profile";
                shell.eapConnecting = false;
            }
        }
    }

    Process {
        id: eapConnectionUp
        property string ssid: ""
        command: ["nmcli", "connection", "up", ssid]
        onExited: (code, status) => {
            if (code === 0) {
                shell.selectedNetworkName = "";
                shell.eapIdentityInput = "";
                shell.eapPasswordInput = "";
                shell.eapError = "";
                shell.eapConnecting = false;
                shell.closePopup();
            } else {
                shell.eapError = "Authentication failed";
                shell.eapConnecting = false;
                eapConnectionDelete.ssid = ssid;
                eapConnectionDelete.running = true;
            }
        }
    }

    Process {
        id: eapConnectionDelete
        property string ssid: ""
        command: ["nmcli", "connection", "delete", ssid]
    }

    Timer {
        interval: 5000
        running: true
        repeat: true
        onTriggered: {
            shell.ethernetConnected = false;
            shell.ethernetInterface = "";
            ethCheck.running = true;
            batCheck.running = true;
            batteryTimeCheck.running = true;
            batteryPowerCheck.running = true;
            powerProfileCheck.running = true;
            batteryHealthCheck.running = true;
            brightnessCheck.running = true;
            audioCtrl.refresh();
            if (shell.activePopup === "volume") audioCtrl.refreshDevices();
            btCtrl.refresh();
            cpuCheck.running = true;
            ramCheck.running = true;
            tempCheck.running = true;
            netCheck.running = true;
            shell.cpuHistory = pushHistory(shell.cpuHistory, shell.cpuPercent, 60);
            shell.cpuHistoryCount = shell.cpuHistory.length;
            shell.ramHistory = pushHistory(shell.ramHistory, shell.ramPercent, 60);
            shell.ramHistoryCount = shell.ramHistory.length;
            if (shell.hasBattery) {
                shell.batteryHistory = pushHistory(shell.batteryHistory, shell.batteryPercent, 720);
                shell.batteryHistoryCount = shell.batteryHistory.length;
            }
        }
    }

    BluetoothController {
        id: btCtrl
        shell: shell
    }

    Process {
        id: weatherCheck
        command: ["curl", "-sf", "--max-time", "5", "wttr.in/?format=%C|%t"]
        running: true
        stdout: SplitParser {
            onRead: data => {
                var line = data.toString().trim();
                var parts = line.split("|");
                if (parts.length >= 2) {
                    shell.weatherCondition = parts[0].trim().toLowerCase();
                    shell.weatherTemp = parts[1].trim().replace("+", "");
                }
            }
        }
    }

    Timer {
        interval: 600000
        running: true
        repeat: true
        onTriggered: weatherCheck.running = true
    }

    // 7-day forecast via Open-Meteo. Location resolved from IP via ipinfo.io.
    Process {
        id: weatherForecastCheck
        command: ["sh", "-c", "info=$(curl -sf --max-time 5 https://ipinfo.io/json); [ -z \"$info\" ] && exit 0; loc=$(printf '%s' \"$info\" | grep -oE '\"loc\": *\"[^\"]*\"' | sed -E 's/.*\"([^\"]*)\"$/\\1/'); city=$(printf '%s' \"$info\" | grep -oE '\"city\": *\"[^\"]*\"' | sed -E 's/.*\"([^\"]*)\"$/\\1/'); [ -z \"$loc\" ] && exit 0; lat=${loc%,*}; lon=${loc#*,}; data=$(curl -sf --max-time 5 \"https://api.open-meteo.com/v1/forecast?latitude=${lat}&longitude=${lon}&daily=weather_code,temperature_2m_max,temperature_2m_min,precipitation_probability_max,wind_speed_10m_max,wind_direction_10m_dominant&hourly=relative_humidity_2m&timezone=auto&forecast_days=7\" | tr -d '\\n'); [ -z \"$data\" ] && exit 0; printf '%s|%s\\n' \"$city\" \"$data\""]
        running: true
        stdout: SplitParser {
            onRead: data => {
                var line = data.toString();
                var sep = line.indexOf("|");
                if (sep < 0) return;
                var city = line.substring(0, sep);
                var json = line.substring(sep + 1).trim();
                if (json === "") return;
                try {
                    var parsed = JSON.parse(json);
                    if (!parsed.daily) return;
                    var d = parsed.daily;

                    // Aggregate hourly humidity into a daily mean keyed by date.
                    var humByDate = {};
                    var h = parsed.hourly;
                    if (h && h.time && h.relative_humidity_2m) {
                        for (var hi = 0; hi < h.time.length; hi++) {
                            var dk = h.time[hi].substring(0, 10);
                            if (!humByDate[dk]) humByDate[dk] = { sum: 0, n: 0 };
                            humByDate[dk].sum += h.relative_humidity_2m[hi];
                            humByDate[dk].n += 1;
                        }
                    }

                    var days = [];
                    for (var i = 0; i < d.time.length; i++) {
                        var bucket = humByDate[d.time[i]];
                        var humAvg = bucket && bucket.n > 0 ? Math.round(bucket.sum / bucket.n) : null;
                        days.push({
                            date: d.time[i],
                            weatherCode: d.weather_code[i],
                            tempMax: Math.round(d.temperature_2m_max[i]),
                            tempMin: Math.round(d.temperature_2m_min[i]),
                            precipChance: d.precipitation_probability_max[i] != null ? d.precipitation_probability_max[i] : 0,
                            windSpeed: d.wind_speed_10m_max && d.wind_speed_10m_max[i] != null ? Math.round(d.wind_speed_10m_max[i]) : null,
                            windDir: d.wind_direction_10m_dominant && d.wind_direction_10m_dominant[i] != null ? d.wind_direction_10m_dominant[i] : null,
                            humidity: humAvg
                        });
                    }
                    shell.weatherLocationName = city;
                    shell.weatherForecast = days;
                } catch(e) {}
            }
        }
    }

    Timer {
        interval: 3600000
        running: true
        repeat: true
        onTriggered: weatherForecastCheck.running = true
    }

    Process {
        id: cpuCheck
        command: ["sh", "-c", "head -1 /proc/stat"]
        running: true
        stdout: SplitParser {
            onRead: data => {
                var line = data.toString().trim();
                var parts = line.split(/\s+/);
                if (parts.length < 5) return;
                var idle = parseInt(parts[4]) + (parseInt(parts[5]) || 0);
                var total = 0;
                for (var i = 1; i < parts.length; i++) total += parseInt(parts[i]) || 0;
                if (shell.cpuPrevTotal > 0) {
                    var diffIdle = idle - shell.cpuPrevIdle;
                    var diffTotal = total - shell.cpuPrevTotal;
                    if (diffTotal > 0) {
                        shell.cpuPercent = Math.round((1 - diffIdle / diffTotal) * 100);
                    }
                }
                shell.cpuPrevIdle = idle;
                shell.cpuPrevTotal = total;
            }
        }
    }

    Process {
        id: ramCheck
        command: ["sh", "-c", "grep -E '^(MemTotal|MemAvailable):' /proc/meminfo"]
        running: true
        property real memTotal: 0
        property real memAvail: 0
        stdout: SplitParser {
            onRead: data => {
                var line = data.toString().trim();
                if (line.startsWith("MemTotal:")) {
                    ramCheck.memTotal = parseInt(line.split(/\s+/)[1]) || 0;
                } else if (line.startsWith("MemAvailable:")) {
                    ramCheck.memAvail = parseInt(line.split(/\s+/)[1]) || 0;
                }
            }
        }
        onExited: {
            if (memTotal > 0) {
                shell.ramTotalGb = Math.round(memTotal / 1048576 * 10) / 10;
                var used = memTotal - memAvail;
                shell.ramUsedGb = Math.round(used / 1048576 * 10) / 10;
                shell.ramPercent = Math.round(used / memTotal * 100);
            }
            memTotal = 0;
            memAvail = 0;
        }
    }

    Process {
        id: tempCheck
        command: ["sh", "-c", "cat /sys/class/thermal/thermal_zone*/temp 2>/dev/null | sort -rn | head -1"]
        running: true
        stdout: SplitParser {
            onRead: data => {
                var val = parseInt(data.toString().trim());
                if (!isNaN(val)) shell.cpuTemp = Math.round(val / 1000);
            }
        }
    }

    Process {
        id: diskCheck
        command: ["df", "-h", "/"]
        running: true
        property bool headerSkipped: false
        stdout: SplitParser {
            onRead: data => {
                var line = data.toString().trim();
                if (!diskCheck.headerSkipped) { diskCheck.headerSkipped = true; return; }
                var parts = line.split(/\s+/);
                if (parts.length >= 5) {
                    shell.diskTotal = parts[1];
                    shell.diskUsed = parts[2];
                    shell.diskPercent = parseInt(parts[4]) || 0;
                }
            }
        }
        onExited: { headerSkipped = false; }
    }

    Timer {
        interval: 60000
        running: true
        repeat: true
        onTriggered: diskCheck.running = true
    }

    Process {
        id: netCheck
        command: ["sh", "-c", "cat /proc/net/dev"]
        running: true
        property real accRx: 0
        property real accTx: 0
        stdout: SplitParser {
            onRead: data => {
                var line = data.toString().trim();
                var idx = line.indexOf(":");
                if (idx < 0) return;
                var iface = line.substring(0, idx).trim();
                if (iface === "lo" || iface.indexOf("docker") === 0
                    || iface.indexOf("veth") === 0 || iface.indexOf("br-") === 0
                    || iface.indexOf("virbr") === 0 || iface.indexOf("tun") === 0
                    || iface.indexOf("tap") === 0) return;
                var parts = line.substring(idx + 1).trim().split(/\s+/);
                if (parts.length < 16) return;
                netCheck.accRx += parseFloat(parts[0]) || 0;
                netCheck.accTx += parseFloat(parts[8]) || 0;
            }
        }
        onExited: {
            var now = Date.now() / 1000;
            if (shell.netPrevTime > 0 && now > shell.netPrevTime) {
                var dt = now - shell.netPrevTime;
                var rxR = Math.max(0, (accRx - shell.netPrevRx) / dt);
                var txR = Math.max(0, (accTx - shell.netPrevTx) / dt);
                shell.netRxRate = rxR;
                shell.netTxRate = txR;
                var rxH = pushHistory(shell.netRxHistory, rxR, 60);
                var txH = pushHistory(shell.netTxHistory, txR, 60);
                shell.netRxHistory = rxH;
                shell.netTxHistory = txH;
                shell.netHistoryCount = rxH.length;
                var peak = 1;
                for (var i = 0; i < rxH.length; i++) {
                    if (rxH[i] > peak) peak = rxH[i];
                    if (txH[i] > peak) peak = txH[i];
                }
                shell.netRxPeak = peak;
            }
            shell.netPrevRx = accRx;
            shell.netPrevTx = accTx;
            shell.netPrevTime = now;
            shell.netRxBytes = accRx;
            shell.netTxBytes = accTx;
            accRx = 0;
            accTx = 0;
        }
    }

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    // Bar - one per screen
    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: barWindow
            required property var modelData
            screen: modelData

            // Tray overflow kicks in on narrow monitors. Hides lower-priority
            // icons (sysMon, brightness) behind the chevron.
            property bool trayOverflow: width > 0 && width < 1200

            anchors {
                top: true
                left: true
                right: true
            }
            implicitHeight: 30
            color: Theme.barBg

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 8
                anchors.rightMargin: 8
                spacing: 0

                // === Left: Workspace indicators ===
                Row {
                    spacing: 2
                    Layout.alignment: Qt.AlignLeft

                    Repeater {
                        model: Hyprland.workspaces.values

                        Rectangle {
                            required property var modelData
                            property int wsId: modelData ? modelData.id : -1
                            property string wsName: modelData && modelData.name ? modelData.name : ""
                            property bool hasCustomName: wsName !== "" && wsName !== String(wsId)
                            property string label: hasCustomName ? wsName.substring(0, 3) : String(wsId)
                            property bool isActive: Hyprland.focusedWorkspace !== null && Hyprland.focusedWorkspace.id === wsId
                            property bool hovered: false

                            visible: wsId > 0
                            implicitWidth: Math.max(24, wsLabel.implicitWidth + 10)
                            width: visible ? implicitWidth : 0
                            height: 22
                            radius: 4
                            color: isActive ? Theme.workspaceActive
                                : hovered ? Theme.workspaceHover
                                : "transparent"

                            Behavior on color { ColorAnimation { duration: 150 } }

                            Text {
                                id: wsLabel
                                anchors.centerIn: parent
                                text: parent.label
                                color: Theme.text
                                font.pixelSize: 12
                                font.bold: parent.isActive
                            }

                            MouseArea {
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onEntered: parent.hovered = true
                                onExited: parent.hovered = false
                                onClicked: Hyprland.dispatch("workspace " + parent.wsId)
                            }
                        }
                    }
                }

                Item { Layout.fillWidth: true }

                // === Tray overflow chevron ===
                BarButton {
                    id: overflowButton
                    visible: barWindow.trayOverflow
                    Layout.alignment: Qt.AlignRight
                    implicitWidth: 26
                    active: shell.activePopup === "overflow"
                    onClicked: shell.togglePopup("overflow", barWindow.modelData)

                    Row {
                        anchors.centerIn: parent
                        spacing: 2

                        Repeater {
                            model: 3

                            Rectangle {
                                width: 3
                                height: 3
                                radius: 1.5
                                color: Theme.iconPrimary
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }
                    }
                }

                // === Battery icon ===
                BarButton {
                    id: batteryButton
                    visible: shell.hasBattery
                    Layout.alignment: Qt.AlignRight
                    implicitWidth: 34
                    active: shell.activePopup === "battery"
                    onEntered: {
                        shell.batteryHovered = true;
                        shell.batteryHoveredScreen = barWindow.modelData;
                        var pos = batteryButton.mapToItem(null, 0, 0);
                        shell.batteryIconX = pos.x;
                        shell.batteryIconWidth = batteryButton.width;
                    }
                    onExited: shell.batteryHovered = false
                    onClicked: shell.togglePopup("battery", barWindow.modelData)

                    BatteryIcon {
                        anchors.centerIn: parent
                        percent: shell.batteryPercent
                        charging: shell.batteryCharging
                    }
                }

                // === System monitor sparkline (CPU + RAM) ===
                BarButton {
                    id: sysMonButton
                    visible: !barWindow.trayOverflow
                    Layout.alignment: Qt.AlignRight
                    implicitWidth: 30
                    active: shell.activePopup === "sysMon"
                    onClicked: shell.togglePopup("sysMon", barWindow.modelData)

                    SysMonIcon {
                        anchors.centerIn: parent
                        cpuHistory: shell.cpuHistory
                        ramHistory: shell.ramHistory
                    }
                }

                // === Brightness icon ===
                BarButton {
                    id: brightnessButton
                    visible: shell.hasBrightness && !barWindow.trayOverflow
                    Layout.alignment: Qt.AlignRight
                    implicitWidth: 30
                    active: shell.activePopup === "brightness"
                    onClicked: shell.togglePopup("brightness", barWindow.modelData)

                    BrightnessIcon {
                        anchors.centerIn: parent
                        percent: shell.brightnessPercent
                    }
                }

                // === Volume icon ===
                BarButton {
                    id: volumeButton
                    Layout.alignment: Qt.AlignRight
                    implicitWidth: 30
                    active: shell.activePopup === "volume"
                    onClicked: shell.togglePopup("volume", barWindow.modelData)

                    VolumeIcon {
                        anchors.centerIn: parent
                        volume: shell.volumePercent
                        muted: shell.volumeMuted
                    }
                }

                // === Bluetooth icon ===
                BarButton {
                    id: btButton
                    visible: shell.hasBluetooth
                    Layout.alignment: Qt.AlignRight
                    implicitWidth: 30
                    active: shell.activePopup === "bt"
                    onClicked: {
                        shell.togglePopup("bt", barWindow.modelData);
                        if (shell.activePopup === "bt") btControllerCheck.running = true;
                    }

                    BluetoothIcon {
                        anchors.centerIn: parent
                        powered: shell.bluetoothPowered
                    }
                }

                // === Right: WiFi icon ===
                BarButton {
                    id: wifiButton
                    Layout.alignment: Qt.AlignRight
                    implicitWidth: 30
                    active: shell.activePopup === "wifi"
                    onClicked: {
                        shell.togglePopup("wifi", barWindow.modelData);
                        if (shell.activePopup === "wifi" && shell.wifiDev) shell.wifiDev.scannerEnabled = true;
                        shell.selectedNetworkName = "";
                        shell.passwordInput = "";
                    }

                    WifiIcon {
                        anchors.centerIn: parent
                        visible: !shell.ethernetConnected
                        enabled: Networking.wifiEnabled
                    }

                    EthernetIcon {
                        anchors.centerIn: parent
                        visible: shell.ethernetConnected
                        active: Networking.wifiEnabled
                    }
                }

                // === Notification bell icon ===
                BarButton {
                    id: notifButton
                    Layout.alignment: Qt.AlignRight
                    implicitWidth: 30
                    active: shell.activePopup === "notif"
                    onClicked: shell.togglePopup("notif", barWindow.modelData)

                    BellIcon {
                        anchors.centerIn: parent
                        count: shell.notifCount
                    }

                    // Unread badge
                    Rectangle {
                        visible: shell.notifCount > 0
                        x: parent.width - 10
                        y: 1
                        width: Math.max(12, badgeText.implicitWidth + 4)
                        height: 12
                        radius: 6
                        color: Theme.accentDanger

                        Text {
                            id: badgeText
                            anchors.centerIn: parent
                            text: shell.notifCount > 99 ? "99+" : shell.notifCount
                            color: "#ffffff"
                            font.pixelSize: 8
                            font.bold: true
                        }
                    }
                }
            }

            // === Centre: Media + Date / Time + Weather (anchored to true centre, separate widgets) ===
            Row {
                id: centreRow
                anchors.centerIn: parent
                spacing: 8

                Rectangle {
                    id: mediaArea
                    property bool hovered: false

                    visible: shell.mprisPlayer !== null
                    width: mediaRow.implicitWidth + 16
                    height: 22
                    radius: 4
                    color: shell.activePopup === "media" ? Theme.surfaceActive
                         : hovered ? Theme.buttonHover : "transparent"
                    anchors.verticalCenter: parent.verticalCenter

                    Behavior on color { ColorAnimation { duration: 150 } }

                    Row {
                        id: mediaRow
                        anchors.centerIn: parent
                        spacing: 6

                        MediaPlayerIcon {
                            anchors.verticalCenter: parent.verticalCenter
                            iconSize: 14
                            iconType: !shell.mprisPlayer ? "stopped"
                                : shell.mprisPlayer.isPlaying ? "playing" : "paused"
                            animTime: shell.weatherAnimTime
                        }

                        Text {
                            id: mediaTitle
                            anchors.verticalCenter: parent.verticalCenter
                            text: shell.mprisPlayer && shell.mprisPlayer.trackTitle !== ""
                                ? shell.mprisPlayer.trackTitle : ""
                            color: Theme.text
                            font.pixelSize: 13
                            elide: Text.ElideRight
                            width: Math.min(implicitWidth, 160)
                            visible: text !== ""
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onEntered: parent.hovered = true
                        onExited: parent.hovered = false
                        onClicked: shell.togglePopup("media", barWindow.modelData)
                    }
                }

                Rectangle {
                    id: dateArea
                    property bool hovered: false

                    width: dateText.implicitWidth + 20
                    height: 22
                    radius: 4
                    color: hovered ? Theme.buttonHover : "transparent"
                    anchors.verticalCenter: parent.verticalCenter

                    Behavior on color { ColorAnimation { duration: 150 } }

                    Text {
                        id: dateText
                        anchors.centerIn: parent
                        text: shell.showFullDate
                            ? Qt.formatDateTime(clock.date, "dd/MM/yy h:mm AP")
                            : Qt.formatDateTime(clock.date, "h:mm AP")
                        color: Theme.text
                        font.pixelSize: 13
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        acceptedButtons: Qt.LeftButton | Qt.MiddleButton
                        cursorShape: Qt.PointingHandCursor
                        onEntered: parent.hovered = true
                        onExited: parent.hovered = false
                        onClicked: function(mouse) {
                            if (mouse.button === Qt.MiddleButton)
                                Theme.mode = Theme.isDark ? Theme.Light : Theme.Dark;
                            else
                                shell.showFullDate = !shell.showFullDate;
                        }
                    }
                }

                Rectangle {
                    id: weatherArea
                    property bool hovered: false

                    visible: shell.weatherCondition !== ""
                    width: weatherRow.implicitWidth + 16
                    height: 22
                    radius: 4
                    color: shell.activePopup === "weather" ? Theme.surfaceActive
                         : hovered ? Theme.buttonHover : "transparent"
                    anchors.verticalCenter: parent.verticalCenter

                    Behavior on color { ColorAnimation { duration: 150 } }

                    Row {
                        id: weatherRow
                        anchors.centerIn: parent
                        spacing: 6

                        WeatherIcon {
                            id: weatherCanvas
                            anchors.verticalCenter: parent.verticalCenter
                            iconSize: 14
                            iconType: {
                                var c = shell.weatherCondition;
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
                            animTime: shell.weatherAnimTime
                        }

                        Text {
                            text: shell.weatherTemp
                            color: Theme.text
                            font.pixelSize: 13
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        Text {
                            visible: shell.weatherEffectOverride !== ""
                            text: "(" + shell.weatherEffectOverride + ")"
                            color: Theme.textDim
                            font.pixelSize: 11
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        acceptedButtons: Qt.LeftButton | Qt.RightButton
                        cursorShape: Qt.PointingHandCursor
                        onEntered: parent.hovered = true
                        onExited: parent.hovered = false
                        onClicked: function(mouse) {
                            if (mouse.button === Qt.RightButton) {
                                shell.cycleWeatherEffect();
                            } else {
                                shell.togglePopup("weather", barWindow.modelData);
                            }
                        }
                    }
                }
            }
        }
    }

    // WiFi popup - one per screen
    WifiPopup { shell: shell }

    // Bluetooth popup - one per screen
    BluetoothPopup { shell: shell }

    // Volume popup - one per screen
    VolumePopup { shell: shell }

    // Brightness popup - one per screen
    BrightnessPopup { shell: shell }

    // Battery tooltip - one per screen
    BatteryTooltip { shell: shell }

    // Battery popup - one per screen
    BatteryPopup { shell: shell }

    // Tray overflow menu - one per screen
    TrayOverflowPopup { shell: shell }

    // System monitor popup - one per screen
    SystemMonitorPopup { shell: shell }

    // Notification center popup - one per screen
    NotificationCenter { shell: shell }

    // Weather forecast popup - one per screen
    WeatherPopup { shell: shell }

    // Media player popup - one per screen
    MediaPlayerPopup { shell: shell }

    // Toast notification popup - one per screen
    ToastNotification { shell: shell }

    // === Weather Effects Overlay ===
    WeatherOverlay { shell: shell }

    // App launcher - one per screen, surfaced via IPC from Hyprland
    AppLauncher { shell: shell }

    IpcHandler {
        target: "applauncher"

        function show(): void {
            var screen = null;
            var monitor = Hyprland.focusedWorkspace ? Hyprland.focusedWorkspace.monitor : null;
            if (monitor) {
                var screens = Quickshell.screens;
                for (var i = 0; i < screens.length; i++) {
                    if (screens[i].name === monitor.name) {
                        screen = screens[i];
                        break;
                    }
                }
            }
            if (!screen && Quickshell.screens.length > 0) screen = Quickshell.screens[0];
            shell.openPopup("applauncher", screen);
        }

        function hide(): void {
            if (shell.activePopup === "applauncher") shell.closePopup();
        }

        function toggle(): void {
            if (shell.activePopup === "applauncher") shell.closePopup();
            else show();
        }
    }
}
