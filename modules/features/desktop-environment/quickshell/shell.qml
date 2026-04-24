import Quickshell
import Quickshell.Hyprland
import Quickshell.Networking
import Quickshell.Services.Notifications
import Quickshell.Io
import QtQuick
import QtQuick.Layouts

ShellRoot {
    id: shell

    property bool showFullDate: true
    property bool wifiPopupOpen: false
    property var popupScreen: null
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
    property bool btPopupOpen: false
    property var btPopupScreen: null
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
    property bool batteryPopupOpen: false
    property var batteryPopupScreen: null

    property bool overflowPopupOpen: false
    property var overflowPopupScreen: null

    property bool hasBrightness: false
    property int brightnessPercent: 0
    property bool brightnessPopupOpen: false
    property var brightnessPopupScreen: null

    property int volumePercent: 0
    property bool volumeMuted: false
    property bool volumePopupOpen: false
    property var volumePopupScreen: null

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

    property bool notifPopupOpen: false
    property var notifPopupScreen: null
    property bool toastVisible: false
    property var toastNotification: null
    property var notifHistory: []
    property int notifCount: 0

    // System monitor
    property bool sysMonPopupOpen: false
    property var sysMonPopupScreen: null
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

    function setBrightness(pct) {
        brightnessSet.target = pct;
        brightnessSet.running = true;
    }

    function setVolume(pct) {
        volumeSet.target = pct;
        volumeSet.running = true;
    }

    function toggleVolumeMute() {
        volumeToggleMute.running = true;
    }

    function setMicGain(pct) {
        micGainSet.target = pct;
        micGainSet.running = true;
    }

    function toggleMicMute() {
        micToggleMute.running = true;
    }

    function setDefaultAudioDevice(id) {
        audioDeviceSet.target = id;
        audioDeviceSet.running = true;
    }

    onVolumePopupOpenChanged: {
        if (volumePopupOpen) audioDevicesCheck.running = true;
    }

    function setPowerProfile(profile) {
        powerProfileSet.profile = profile;
        powerProfileSet.running = true;
    }

    function openOverflowPopupFor(screen) {
        shell.wifiPopupOpen = false;
        shell.btPopupOpen = false;
        shell.volumePopupOpen = false;
        shell.brightnessPopupOpen = false;
        shell.batteryPopupOpen = false;
        shell.notifPopupOpen = false;
        shell.sysMonPopupOpen = false;
        shell.overflowPopupScreen = screen;
        shell.overflowPopupOpen = true;
    }

    function toggleBluetooth() {
        btToggle.turnOn = !shell.bluetoothPowered;
        btToggle.running = true;
    }

    function connectBluetoothDevice(mac) {
        btConnect.mac = mac;
        btConnect.running = true;
    }

    function disconnectBluetoothDevice(mac) {
        btDisconnect.mac = mac;
        btDisconnect.running = true;
    }

    function pairBluetoothDevice(mac) {
        btPair.mac = mac;
        btPair.running = true;
    }

    function refreshBluetooth() {
        btControllerCheck.running = true;
    }

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

    Process {
        id: volumeCheck
        command: ["wpctl", "get-volume", "@DEFAULT_AUDIO_SINK@"]
        running: true
        stdout: SplitParser {
            onRead: data => {
                var line = data.toString().trim();
                // Format: "Volume: 0.50" or "Volume: 0.50 [MUTED]"
                shell.volumeMuted = line.indexOf("[MUTED]") !== -1;
                var match = line.match(/Volume:\s+([\d.]+)/);
                if (match) {
                    shell.volumePercent = Math.round(parseFloat(match[1]) * 100);
                }
            }
        }
    }

    Process {
        id: volumeSet
        property int target: 0
        command: ["wpctl", "set-volume", "@DEFAULT_AUDIO_SINK@", target + "%"]
        onRunningChanged: {
            if (!running) volumeCheck.running = true;
        }
    }

    Process {
        id: volumeToggleMute
        command: ["wpctl", "set-mute", "@DEFAULT_AUDIO_SINK@", "toggle"]
        onRunningChanged: {
            if (!running) volumeCheck.running = true;
        }
    }

    Process {
        id: micCheck
        command: ["wpctl", "get-volume", "@DEFAULT_AUDIO_SOURCE@"]
        running: true
        stdout: SplitParser {
            onRead: data => {
                var line = data.toString().trim();
                shell.micMuted = line.indexOf("[MUTED]") !== -1;
                var match = line.match(/Volume:\s+([\d.]+)/);
                if (match) {
                    shell.micGainPercent = Math.round(parseFloat(match[1]) * 100);
                }
            }
        }
    }

    Process {
        id: micGainSet
        property int target: 0
        command: ["wpctl", "set-volume", "@DEFAULT_AUDIO_SOURCE@", target + "%"]
        onRunningChanged: {
            if (!running) micCheck.running = true;
        }
    }

    Process {
        id: micToggleMute
        command: ["wpctl", "set-mute", "@DEFAULT_AUDIO_SOURCE@", "toggle"]
        onRunningChanged: {
            if (!running) micCheck.running = true;
        }
    }

    // Parses `wpctl status` to extract audio sinks/sources and which is default.
    // Output lines from the awk script are `kind|isDefault|id|name`.
    Process {
        id: audioDevicesCheck
        command: ["sh", "-c",
            "wpctl status 2>/dev/null | awk '"
            + "/^Audio/{a=1;next} "
            + "/^Video/{a=0} "
            + "a&&/:$/{m=\"\"} "
            + "a&&/Sinks:$/{m=\"sink\";next} "
            + "a&&/Sources:$/{m=\"source\";next} "
            + "m&&match($0,/[0-9]+\\./){"
            + "d=($0~/\\*/)?\"1\":\"0\";"
            + "line=substr($0,RSTART);"
            + "id=substr(line,1,RLENGTH-1);"
            + "rest=substr(line,RLENGTH+1);"
            + "sub(/^[ \\t]+/,\"\",rest);"
            + "sub(/[ \\t]+\\[.*$/,\"\",rest);"
            + "print m\"|\"d\"|\"id\"|\"rest"
            + "}'"
        ]
        running: true
        property var pendingSinks: []
        property var pendingSources: []
        stdout: SplitParser {
            onRead: data => {
                var parts = data.toString().trim().split("|");
                if (parts.length < 4) return;
                var id = parseInt(parts[2]);
                if (isNaN(id)) return;
                var entry = { id: id, name: parts[3], isDefault: parts[1] === "1" };
                if (parts[0] === "sink") audioDevicesCheck.pendingSinks.push(entry);
                else if (parts[0] === "source") audioDevicesCheck.pendingSources.push(entry);
            }
        }
        onExited: {
            shell.audioSinks = pendingSinks;
            shell.audioSources = pendingSources;
            pendingSinks = [];
            pendingSources = [];
        }
    }

    Process {
        id: audioDeviceSet
        property int target: 0
        command: ["wpctl", "set-default", target.toString()]
        onRunningChanged: {
            if (!running) {
                audioDevicesCheck.running = true;
                volumeCheck.running = true;
                micCheck.running = true;
            }
        }
    }

    // Streams ~10 peak-amplitude samples per second from the default input
    // source. u8 mono @ 8 kHz keeps CPU and bandwidth trivial; the awk loop
    // emits the largest per-chunk distance from the 128 silence midpoint.
    Process {
        id: micMeter
        command: ["sh", "-c",
            "exec pw-cat -r --raw --rate=8000 --channels=1 --format=u8 - 2>/dev/null"
            + " | stdbuf -o0 od -An -v -tu1 -w800"
            + " | stdbuf -oL awk '{m=0;for(i=1;i<=NF;i++){v=$i-128;if(v<0)v=-v;if(v>m)m=v}print m;fflush()}'"
        ]
        running: shell.volumePopupOpen
        stdout: SplitParser {
            onRead: data => {
                var v = parseInt(data.toString().trim());
                if (isNaN(v)) return;
                var newLevel = Math.min(1, v / 128);
                // Fast attack, gentle decay so the meter feels analog.
                if (newLevel > shell.micLevel) {
                    shell.micLevel = newLevel;
                } else {
                    shell.micLevel = shell.micLevel * 0.7 + newLevel * 0.3;
                }
            }
        }
        onRunningChanged: {
            if (!running) shell.micLevel = 0;
        }
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
                shell.wifiPopupOpen = false;
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
            volumeCheck.running = true;
            micCheck.running = true;
            if (shell.volumePopupOpen) audioDevicesCheck.running = true;
            btControllerCheck.running = true;
            cpuCheck.running = true;
            ramCheck.running = true;
            tempCheck.running = true;
            netCheck.running = true;
            var ch = shell.cpuHistory.slice();
            ch.push(shell.cpuPercent);
            if (ch.length > 60) ch = ch.slice(ch.length - 60);
            shell.cpuHistory = ch;
            shell.cpuHistoryCount = ch.length;
            var rh = shell.ramHistory.slice();
            rh.push(shell.ramPercent);
            if (rh.length > 60) rh = rh.slice(rh.length - 60);
            shell.ramHistory = rh;
            shell.ramHistoryCount = rh.length;
            if (shell.hasBattery) {
                var h = shell.batteryHistory.slice();
                h.push(shell.batteryPercent);
                if (h.length > 720) h = h.slice(h.length - 720);
                shell.batteryHistory = h;
                shell.batteryHistoryCount = h.length;
            }
        }
    }

    Process {
        id: btControllerCheck
        command: ["bluetoothctl", "show"]
        running: true
        property string output: ""
        stdout: SplitParser {
            onRead: data => {
                btControllerCheck.output += data.toString() + "\n";
            }
        }
        onExited: (code, status) => {
            if (code === 0 && btControllerCheck.output.length > 0) {
                shell.hasBluetooth = true;
                shell.bluetoothPowered = btControllerCheck.output.indexOf("Powered: yes") !== -1;
            } else {
                shell.hasBluetooth = false;
            }
            btControllerCheck.output = "";
            if (shell.hasBluetooth) {
                btDeviceCheck.running = true;
            }
        }
    }

    Process {
        id: btDeviceCheck
        command: ["bluetoothctl", "devices", "Paired"]
        property var devices: []
        stdout: SplitParser {
            onRead: data => {
                var line = data.toString().trim();
                if (line.startsWith("Device ")) {
                    var parts = line.substring(7);
                    var mac = parts.substring(0, 17);
                    var name = parts.substring(18);
                    btDeviceCheck.devices.push({ mac: mac, name: name });
                }
            }
        }
        onExited: (code, status) => {
            shell.btPairedDevices = btDeviceCheck.devices;
            btDeviceCheck.devices = [];
            btConnectedCheck.connectedMacs = [];
            btConnectedCheck.running = true;
        }
    }

    Process {
        id: btConnectedCheck
        command: ["bluetoothctl", "devices", "Connected"]
        property var connectedMacs: []
        stdout: SplitParser {
            onRead: data => {
                var line = data.toString().trim();
                if (line.startsWith("Device ")) {
                    var mac = line.substring(7, 24);
                    btConnectedCheck.connectedMacs.push(mac);
                }
            }
        }
        onExited: (code, status) => {
            shell.btConnectedDevices = btConnectedCheck.connectedMacs;
            btConnectedCheck.connectedMacs = [];
        }
    }

    Process {
        id: btToggle
        property bool turnOn: true
        command: ["bluetoothctl", "power", turnOn ? "on" : "off"]
        onExited: btControllerCheck.running = true
    }

    Process {
        id: btConnect
        property string mac: ""
        command: ["bluetoothctl", "connect", mac]
        onExited: {
            btDeviceCheck.devices = [];
            btDeviceCheck.running = true;
        }
    }

    Process {
        id: btDisconnect
        property string mac: ""
        command: ["bluetoothctl", "disconnect", mac]
        onExited: {
            btDeviceCheck.devices = [];
            btDeviceCheck.running = true;
        }
    }

    // Scan while the bluetooth popup is open.
    // `bluetoothctl scan on` without --timeout does NOT actually start discovery
    // in non-interactive mode (it only sets the discovery filter). --timeout uses
    // a different code path that calls StartDiscovery. We restart it in onExited
    // while the popup is still open to keep scanning going.
    Process {
        id: btScan
        command: ["bluetoothctl", "--timeout", "30", "scan", "on"]
        running: shell.btPopupOpen && shell.bluetoothPowered
        onRunningChanged: shell.btScanning = running
        onExited: (code, status) => {
            if (shell.btPopupOpen && shell.bluetoothPowered) {
                btScan.running = true;
            }
        }
    }

    Process {
        id: btDiscoveredCheck
        command: ["bluetoothctl", "devices"]
        property var devices: []
        stdout: SplitParser {
            onRead: data => {
                var line = data.toString().trim();
                if (line.startsWith("Device ")) {
                    var parts = line.substring(7);
                    var mac = parts.substring(0, 17);
                    var name = parts.substring(18);
                    btDiscoveredCheck.devices.push({ mac: mac, name: name });
                }
            }
        }
        onExited: (code, status) => {
            var pairedMacs = shell.btPairedDevices.map(function(d) { return d.mac; });
            // Exclude devices that look like raw MAC addresses (unnamed devices are reported
            // with `-` as the separator, e.g. name "4A-D0-CF-29-58-81" for MAC 4A:D0:CF:29:58:81),
            // and filter out already-paired devices.
            shell.btDiscoveredDevices = btDiscoveredCheck.devices.filter(function(d) {
                if (pairedMacs.indexOf(d.mac) !== -1) return false;
                if (!d.name) return false;
                if (d.name === d.mac) return false;
                if (d.name === d.mac.replace(/:/g, "-")) return false;
                return true;
            });
            btDiscoveredCheck.devices = [];
        }
    }

    // Poll for newly discovered devices while the popup is open.
    Timer {
        interval: 2500
        repeat: true
        running: shell.btPopupOpen && shell.bluetoothPowered
        triggeredOnStart: true
        onTriggered: {
            btDiscoveredCheck.devices = [];
            btDiscoveredCheck.running = true;
        }
    }

    Process {
        id: btPair
        property string mac: ""
        command: ["bluetoothctl", "pair", mac]
        onExited: (code, status) => {
            // Refresh paired list and auto-connect on successful pair.
            btDeviceCheck.devices = [];
            btDeviceCheck.running = true;
            if (code === 0) {
                btConnect.mac = btPair.mac;
                btConnect.running = true;
            }
        }
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
                var rxH = shell.netRxHistory.slice();
                var txH = shell.netTxHistory.slice();
                rxH.push(rxR);
                txH.push(txR);
                if (rxH.length > 60) rxH = rxH.slice(rxH.length - 60);
                if (txH.length > 60) txH = txH.slice(txH.length - 60);
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
            color: Qt.rgba(1, 1, 1, 0.3)

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
                            color: isActive ? Qt.rgba(1, 1, 1, 0.5)
                                : hovered ? Qt.rgba(1, 1, 1, 0.3)
                                : "transparent"

                            Behavior on color { ColorAnimation { duration: 150 } }

                            Text {
                                id: wsLabel
                                anchors.centerIn: parent
                                text: parent.label
                                color: "#ffffff"
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
                    active: shell.overflowPopupOpen
                    onClicked: {
                        if (shell.overflowPopupOpen) {
                            shell.overflowPopupOpen = false;
                        } else {
                            shell.openOverflowPopupFor(barWindow.modelData);
                        }
                    }

                    Row {
                        anchors.centerIn: parent
                        spacing: 2

                        Repeater {
                            model: 3

                            Rectangle {
                                width: 3
                                height: 3
                                radius: 1.5
                                color: "#ffffff"
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
                    active: shell.batteryPopupOpen
                    onEntered: {
                        shell.batteryHovered = true;
                        shell.batteryHoveredScreen = barWindow.modelData;
                        var pos = batteryButton.mapToItem(null, 0, 0);
                        shell.batteryIconX = pos.x;
                        shell.batteryIconWidth = batteryButton.width;
                    }
                    onExited: shell.batteryHovered = false
                    onClicked: {
                        if (shell.batteryPopupOpen) {
                            shell.batteryPopupOpen = false;
                        } else {
                            shell.wifiPopupOpen = false;
                            shell.btPopupOpen = false;
                            shell.volumePopupOpen = false;
                            shell.brightnessPopupOpen = false;
                            shell.notifPopupOpen = false;
                            shell.sysMonPopupOpen = false;
                            shell.overflowPopupOpen = false;
                            shell.batteryPopupScreen = barWindow.modelData;
                            shell.batteryPopupOpen = true;
                        }
                    }

                    Canvas {
                        id: batteryCanvas
                        anchors.centerIn: parent
                        width: 24
                        height: 12

                        property int percent: shell.batteryPercent
                        property bool charging: shell.batteryCharging
                        onPercentChanged: requestPaint()
                        onChargingChanged: requestPaint()

                        onPaint: {
                            var ctx = getContext("2d");
                            ctx.clearRect(0, 0, width, height);

                            // Battery outline
                            ctx.strokeStyle = "#ffffff";
                            ctx.lineWidth = 1.4;
                            ctx.lineJoin = "round";
                            ctx.beginPath();
                            ctx.roundedRect(0.5, 0.5, 20, 11, 2, 2);
                            ctx.stroke();

                            // Terminal nub
                            ctx.fillStyle = "#ffffff";
                            ctx.beginPath();
                            ctx.roundedRect(21, 3, 2.5, 5, 1, 1);
                            ctx.fill();

                            // Fill colour based on level
                            var pct = percent / 100;
                            var fillColor;
                            if (charging) {
                                fillColor = Qt.rgba(0.4, 0.8, 0.4, 0.8);
                            } else if (percent <= 10) {
                                fillColor = Qt.rgba(0.9, 0.2, 0.2, 0.9);
                            } else if (percent <= 25) {
                                fillColor = Qt.rgba(0.95, 0.5, 0.15, 0.85);
                            } else if (percent <= 50) {
                                fillColor = Qt.rgba(0.95, 0.85, 0.2, 0.8);
                            } else {
                                fillColor = Qt.rgba(0.4, 0.8, 0.4, 0.8);
                            }

                            // Inner fill
                            var maxFillWidth = 17;
                            var fillWidth = maxFillWidth * pct;
                            if (fillWidth > 0.5) {
                                ctx.fillStyle = fillColor;
                                ctx.beginPath();
                                ctx.roundedRect(2, 2.5, fillWidth, 7, 1, 1);
                                ctx.fill();
                            }

                            // Charging bolt
                            if (charging) {
                                ctx.fillStyle = "#ffffff";
                                ctx.beginPath();
                                ctx.moveTo(12, 1);
                                ctx.lineTo(8, 6.5);
                                ctx.lineTo(11, 6.5);
                                ctx.lineTo(9, 11);
                                ctx.lineTo(13, 5.5);
                                ctx.lineTo(10, 5.5);
                                ctx.closePath();
                                ctx.fill();
                            }
                        }
                    }
                }

                // === System monitor icon ===
                BarButton {
                    id: sysMonButton
                    visible: !barWindow.trayOverflow
                    Layout.alignment: Qt.AlignRight
                    implicitWidth: 30
                    active: shell.sysMonPopupOpen
                    onClicked: {
                        if (shell.sysMonPopupOpen) {
                            shell.sysMonPopupOpen = false;
                        } else {
                            shell.wifiPopupOpen = false;
                            shell.btPopupOpen = false;
                            shell.volumePopupOpen = false;
                            shell.brightnessPopupOpen = false;
                            shell.batteryPopupOpen = false;
                            shell.notifPopupOpen = false;
                            shell.overflowPopupOpen = false;
                            shell.sysMonPopupScreen = barWindow.modelData;
                            shell.sysMonPopupOpen = true;
                        }
                    }

                    Canvas {
                        anchors.centerIn: parent
                        width: 14
                        height: 14

                        onPaint: {
                            var ctx = getContext("2d");
                            ctx.clearRect(0, 0, width, height);
                            ctx.strokeStyle = "#ffffff";
                            ctx.lineWidth = 1.4;
                            ctx.lineJoin = "round";
                            ctx.beginPath();
                            ctx.roundedRect(0.5, 0.5, 13, 10, 1.5, 1.5);
                            ctx.stroke();
                            ctx.beginPath();
                            ctx.moveTo(5, 11.5);
                            ctx.lineTo(9, 11.5);
                            ctx.stroke();
                            ctx.beginPath();
                            ctx.moveTo(7, 10.5);
                            ctx.lineTo(7, 11.5);
                            ctx.stroke();
                            ctx.lineWidth = 1.2;
                            ctx.lineCap = "round";
                            ctx.beginPath();
                            ctx.moveTo(2, 7);
                            ctx.lineTo(4, 7);
                            ctx.lineTo(5.5, 3);
                            ctx.lineTo(7, 8);
                            ctx.lineTo(8.5, 4);
                            ctx.lineTo(10, 7);
                            ctx.lineTo(12, 7);
                            ctx.stroke();
                        }
                    }
                }

                // === Brightness icon ===
                BarButton {
                    id: brightnessButton
                    visible: shell.hasBrightness && !barWindow.trayOverflow
                    Layout.alignment: Qt.AlignRight
                    implicitWidth: 30
                    active: shell.brightnessPopupOpen
                    onClicked: {
                        if (shell.brightnessPopupOpen) {
                            shell.brightnessPopupOpen = false;
                        } else {
                            shell.wifiPopupOpen = false;
                            shell.btPopupOpen = false;
                            shell.volumePopupOpen = false;
                            shell.batteryPopupOpen = false;
                            shell.notifPopupOpen = false;
                            shell.sysMonPopupOpen = false;
                            shell.overflowPopupOpen = false;
                            shell.brightnessPopupScreen = barWindow.modelData;
                            shell.brightnessPopupOpen = true;
                        }
                    }

                    Canvas {
                        anchors.centerIn: parent
                        width: 14
                        height: 14

                        property int pct: shell.brightnessPercent
                        onPctChanged: requestPaint()

                        onPaint: {
                            var ctx = getContext("2d");
                            ctx.clearRect(0, 0, width, height);

                            var cx = 7;
                            var cy = 7;
                            var r = 3;

                            // Sun rays
                            ctx.strokeStyle = "#ffffff";
                            ctx.lineWidth = 1.4;
                            ctx.lineCap = "round";
                            var rayLen = 2;
                            var rayDist = 5;
                            for (var i = 0; i < 8; i++) {
                                var angle = i * Math.PI / 4;
                                var x1 = cx + Math.cos(angle) * rayDist;
                                var y1 = cy + Math.sin(angle) * rayDist;
                                var x2 = cx + Math.cos(angle) * (rayDist + rayLen);
                                var y2 = cy + Math.sin(angle) * (rayDist + rayLen);
                                ctx.beginPath();
                                ctx.moveTo(x1, y1);
                                ctx.lineTo(x2, y2);
                                ctx.stroke();
                            }

                            // Sun circle
                            var opacity = 0.4 + (pct / 100) * 0.6;
                            ctx.fillStyle = Qt.rgba(1, 1, 1, opacity);
                            ctx.beginPath();
                            ctx.arc(cx, cy, r, 0, 2 * Math.PI);
                            ctx.fill();

                            ctx.strokeStyle = "#ffffff";
                            ctx.lineWidth = 1.4;
                            ctx.beginPath();
                            ctx.arc(cx, cy, r, 0, 2 * Math.PI);
                            ctx.stroke();
                        }
                    }
                }

                // === Volume icon ===
                BarButton {
                    id: volumeButton
                    Layout.alignment: Qt.AlignRight
                    implicitWidth: 30
                    active: shell.volumePopupOpen
                    onClicked: {
                        if (shell.volumePopupOpen) {
                            shell.volumePopupOpen = false;
                        } else {
                            shell.wifiPopupOpen = false;
                            shell.btPopupOpen = false;
                            shell.brightnessPopupOpen = false;
                            shell.batteryPopupOpen = false;
                            shell.notifPopupOpen = false;
                            shell.sysMonPopupOpen = false;
                            shell.overflowPopupOpen = false;
                            shell.volumePopupScreen = barWindow.modelData;
                            shell.volumePopupOpen = true;
                        }
                    }

                    Canvas {
                        anchors.centerIn: parent
                        width: 14
                        height: 14

                        property int vol: shell.volumePercent
                        property bool muted: shell.volumeMuted
                        onVolChanged: requestPaint()
                        onMutedChanged: requestPaint()

                        onPaint: {
                            var ctx = getContext("2d");
                            ctx.clearRect(0, 0, width, height);

                            ctx.strokeStyle = muted ? Qt.rgba(1, 1, 1, 0.4) : "#ffffff";
                            ctx.fillStyle = muted ? Qt.rgba(1, 1, 1, 0.4) : "#ffffff";
                            ctx.lineWidth = 1.4;
                            ctx.lineJoin = "round";
                            ctx.lineCap = "round";

                            // Speaker body
                            ctx.beginPath();
                            ctx.moveTo(1, 5);
                            ctx.lineTo(3.5, 5);
                            ctx.lineTo(6.5, 2);
                            ctx.lineTo(6.5, 12);
                            ctx.lineTo(3.5, 9);
                            ctx.lineTo(1, 9);
                            ctx.closePath();
                            ctx.fill();

                            if (muted) {
                                // X mark
                                ctx.strokeStyle = Qt.rgba(1, 1, 1, 0.6);
                                ctx.lineWidth = 1.6;
                                ctx.beginPath();
                                ctx.moveTo(9, 4.5);
                                ctx.lineTo(13, 9.5);
                                ctx.stroke();
                                ctx.beginPath();
                                ctx.moveTo(13, 4.5);
                                ctx.lineTo(9, 9.5);
                                ctx.stroke();
                            } else {
                                // Sound waves
                                ctx.strokeStyle = "#ffffff";
                                ctx.lineWidth = 1.3;
                                if (vol > 0) {
                                    ctx.beginPath();
                                    ctx.arc(7, 7, 3, -Math.PI / 4, Math.PI / 4);
                                    ctx.stroke();
                                }
                                if (vol > 33) {
                                    ctx.beginPath();
                                    ctx.arc(7, 7, 5, -Math.PI / 4, Math.PI / 4);
                                    ctx.stroke();
                                }
                                if (vol > 66) {
                                    ctx.beginPath();
                                    ctx.arc(7, 7, 7, -Math.PI / 4, Math.PI / 4);
                                    ctx.stroke();
                                }
                            }
                        }
                    }
                }

                // === Bluetooth icon ===
                BarButton {
                    id: btButton
                    visible: shell.hasBluetooth
                    Layout.alignment: Qt.AlignRight
                    implicitWidth: 30
                    active: shell.btPopupOpen
                    onClicked: {
                        shell.btPopupOpen = !shell.btPopupOpen;
                        shell.btPopupScreen = barWindow.modelData;
                        if (shell.btPopupOpen) {
                            shell.brightnessPopupOpen = false;
                            shell.volumePopupOpen = false;
                            shell.batteryPopupOpen = false;
                            shell.notifPopupOpen = false;
                            shell.sysMonPopupOpen = false;
                            shell.overflowPopupOpen = false;
                            btControllerCheck.running = true;
                        }
                    }

                    Canvas {
                        anchors.centerIn: parent
                        width: 12
                        height: 16

                        property bool powered: shell.bluetoothPowered
                        onPoweredChanged: requestPaint()

                        onPaint: {
                            var ctx = getContext("2d");
                            ctx.clearRect(0, 0, width, height);
                            ctx.strokeStyle = shell.bluetoothPowered ? "#ffffff" : Qt.rgba(1, 1, 1, 0.4);
                            ctx.lineWidth = 1.6;
                            ctx.lineCap = "round";
                            ctx.lineJoin = "round";

                            var cx = width / 2;

                            // Bluetooth rune shape
                            ctx.beginPath();
                            ctx.moveTo(2, 4);
                            ctx.lineTo(9, 11);
                            ctx.lineTo(cx, 15);
                            ctx.lineTo(cx, 1);
                            ctx.lineTo(9, 5);
                            ctx.lineTo(2, 12);
                            ctx.stroke();
                        }
                    }
                }

                // === Right: WiFi icon ===
                BarButton {
                    id: wifiButton
                    Layout.alignment: Qt.AlignRight
                    implicitWidth: 30
                    active: shell.wifiPopupOpen
                    onClicked: {
                        shell.wifiPopupOpen = !shell.wifiPopupOpen;
                        shell.popupScreen = barWindow.modelData;
                        if (shell.wifiPopupOpen) {
                            shell.brightnessPopupOpen = false;
                            shell.volumePopupOpen = false;
                            shell.batteryPopupOpen = false;
                            shell.notifPopupOpen = false;
                            shell.sysMonPopupOpen = false;
                            shell.overflowPopupOpen = false;
                            if (shell.wifiDev) shell.wifiDev.scannerEnabled = true;
                        }
                        shell.selectedNetworkName = "";
                        shell.passwordInput = "";
                    }

                    // WiFi icon
                    Canvas {
                        anchors.centerIn: parent
                        width: 18
                        height: 14
                        visible: !shell.ethernetConnected

                        property bool wifiOn: Networking.wifiEnabled
                        onWifiOnChanged: requestPaint()

                        onPaint: {
                            var ctx = getContext("2d");
                            ctx.clearRect(0, 0, width, height);
                            var col = wifiOn ? "#ffffff" : Qt.rgba(1, 1, 1, 0.4);
                            ctx.strokeStyle = col;
                            ctx.lineWidth = 1.6;
                            ctx.lineCap = "round";

                            var cx = width / 2;
                            var by = height;

                            ctx.beginPath();
                            ctx.arc(cx, by, 13, -Math.PI * 0.75, -Math.PI * 0.25);
                            ctx.stroke();

                            ctx.beginPath();
                            ctx.arc(cx, by, 9, -Math.PI * 0.75, -Math.PI * 0.25);
                            ctx.stroke();

                            ctx.beginPath();
                            ctx.arc(cx, by, 5, -Math.PI * 0.75, -Math.PI * 0.25);
                            ctx.stroke();

                            ctx.fillStyle = col;
                            ctx.beginPath();
                            ctx.arc(cx, by - 1, 1.8, 0, Math.PI * 2);
                            ctx.fill();

                            // Diagonal strike-through when disabled
                            if (!wifiOn) {
                                ctx.strokeStyle = Qt.rgba(1, 1, 1, 0.6);
                                ctx.lineWidth = 1.8;
                                ctx.beginPath();
                                ctx.moveTo(1, 1);
                                ctx.lineTo(width - 1, height - 1);
                                ctx.stroke();
                            }
                        }
                    }

                    // Ethernet icon
                    Canvas {
                        anchors.centerIn: parent
                        width: 14
                        height: 14
                        visible: shell.ethernetConnected

                        property bool wifiOn: Networking.wifiEnabled
                        onWifiOnChanged: requestPaint()

                        onPaint: {
                            var ctx = getContext("2d");
                            ctx.clearRect(0, 0, width, height);
                            ctx.strokeStyle = wifiOn ? "#ffffff" : Qt.rgba(1, 1, 1, 0.4);
                            ctx.lineWidth = 1.4;
                            ctx.lineCap = "round";
                            ctx.lineJoin = "round";

                            var cx = width / 2;

                            // Vertical line
                            ctx.beginPath();
                            ctx.moveTo(cx, 1);
                            ctx.lineTo(cx, 13);
                            ctx.stroke();

                            // Top horizontal
                            ctx.beginPath();
                            ctx.moveTo(3, 4);
                            ctx.lineTo(width - 3, 4);
                            ctx.stroke();

                            // Left branch down
                            ctx.beginPath();
                            ctx.moveTo(3, 4);
                            ctx.lineTo(3, 7);
                            ctx.stroke();

                            // Right branch down
                            ctx.beginPath();
                            ctx.moveTo(width - 3, 4);
                            ctx.lineTo(width - 3, 7);
                            ctx.stroke();
                        }
                    }
                }

                // === Notification bell icon ===
                BarButton {
                    id: notifButton
                    Layout.alignment: Qt.AlignRight
                    implicitWidth: 30
                    active: shell.notifPopupOpen
                    onClicked: {
                        if (shell.notifPopupOpen) {
                            shell.notifPopupOpen = false;
                        } else {
                            shell.wifiPopupOpen = false;
                            shell.btPopupOpen = false;
                            shell.volumePopupOpen = false;
                            shell.brightnessPopupOpen = false;
                            shell.batteryPopupOpen = false;
                            shell.sysMonPopupOpen = false;
                            shell.overflowPopupOpen = false;
                            shell.notifPopupScreen = barWindow.modelData;
                            shell.notifPopupOpen = true;
                        }
                    }

                    Canvas {
                        anchors.centerIn: parent
                        width: 14
                        height: 16

                        property int count: shell.notifCount
                        onCountChanged: requestPaint()

                        onPaint: {
                            var ctx = getContext("2d");
                            ctx.clearRect(0, 0, width, height);

                            ctx.strokeStyle = "#ffffff";
                            ctx.fillStyle = "#ffffff";
                            ctx.lineWidth = 1.4;
                            ctx.lineCap = "round";
                            ctx.lineJoin = "round";

                            // Bell body
                            ctx.beginPath();
                            ctx.moveTo(2, 10);
                            ctx.quadraticCurveTo(2, 5, 4, 3);
                            ctx.quadraticCurveTo(5.5, 0.5, 7, 0.5);
                            ctx.quadraticCurveTo(8.5, 0.5, 10, 3);
                            ctx.quadraticCurveTo(12, 5, 12, 10);
                            ctx.lineTo(13, 11.5);
                            ctx.lineTo(1, 11.5);
                            ctx.closePath();
                            ctx.stroke();
                            ctx.fill();

                            // Clapper
                            ctx.beginPath();
                            ctx.arc(7, 14, 1.5, 0, Math.PI * 2);
                            ctx.fill();
                        }
                    }

                    // Unread badge
                    Rectangle {
                        visible: shell.notifCount > 0
                        x: parent.width - 10
                        y: 1
                        width: Math.max(12, badgeText.implicitWidth + 4)
                        height: 12
                        radius: 6
                        color: "#e04040"

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

            // === Centre: Date / Time + Weather (anchored to true centre) ===
            Rectangle {
                id: dateArea
                property bool hovered: false

                anchors.centerIn: parent
                width: centreRow.implicitWidth + 20
                height: 22
                radius: 4
                color: hovered ? Qt.rgba(1, 1, 1, 0.3) : "transparent"

                Behavior on color { ColorAnimation { duration: 150 } }

                Row {
                    id: centreRow
                    anchors.centerIn: parent
                    spacing: 8

                    Text {
                        id: dateText
                        text: shell.showFullDate
                            ? Qt.formatDateTime(clock.date, "dd/MM/yy h:mm AP")
                            : Qt.formatDateTime(clock.date, "h:mm AP")
                        color: "#ffffff"
                        font.pixelSize: 13
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Rectangle {
                        visible: shell.weatherCondition !== ""
                        width: 1
                        height: 12
                        color: Qt.rgba(1, 1, 1, 0.4)
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Canvas {
                        id: weatherCanvas
                        visible: shell.weatherCondition !== ""
                        width: 14
                        height: 14
                        anchors.verticalCenter: parent.verticalCenter

                        property string cond: shell.weatherCondition
                        onCondChanged: requestPaint()

                        function weatherType() {
                            var c = cond;
                            if (c.indexOf("thunder") !== -1) return "thunder";
                            if (c.indexOf("snow") !== -1 || c.indexOf("sleet") !== -1 || c.indexOf("blizzard") !== -1 || c.indexOf("ice") !== -1) return "snow";
                            if (c.indexOf("rain") !== -1 || c.indexOf("drizzle") !== -1 || c.indexOf("shower") !== -1) return "rain";
                            if (c.indexOf("mist") !== -1 || c.indexOf("fog") !== -1 || c.indexOf("haze") !== -1) return "fog";
                            if (c.indexOf("partly") !== -1 || c.indexOf("patchy") !== -1) return "partlycloudy";
                            if (c.indexOf("cloud") !== -1 || c.indexOf("overcast") !== -1) return "cloudy";
                            if (c.indexOf("sunny") !== -1 || c.indexOf("clear") !== -1) return "sunny";
                            return "cloudy";
                        }

                        onPaint: {
                            var ctx = getContext("2d");
                            ctx.clearRect(0, 0, width, height);
                            var type = weatherType();

                            ctx.strokeStyle = "#ffffff";
                            ctx.fillStyle = "#ffffff";
                            ctx.lineWidth = 1.3;
                            ctx.lineCap = "round";

                            if (type === "sunny") {
                                // Sun circle
                                ctx.beginPath();
                                ctx.arc(7, 7, 3, 0, 2 * Math.PI);
                                ctx.fill();
                                // Rays
                                for (var i = 0; i < 8; i++) {
                                    var a = i * Math.PI / 4;
                                    ctx.beginPath();
                                    ctx.moveTo(7 + Math.cos(a) * 4.5, 7 + Math.sin(a) * 4.5);
                                    ctx.lineTo(7 + Math.cos(a) * 6.5, 7 + Math.sin(a) * 6.5);
                                    ctx.stroke();
                                }
                            } else if (type === "partlycloudy") {
                                // Small sun behind cloud
                                ctx.beginPath();
                                ctx.arc(10, 4, 2.5, 0, 2 * Math.PI);
                                ctx.fill();
                                for (var j = 0; j < 6; j++) {
                                    var a2 = j * Math.PI / 3 - Math.PI / 6;
                                    ctx.beginPath();
                                    ctx.moveTo(10 + Math.cos(a2) * 3.5, 4 + Math.sin(a2) * 3.5);
                                    ctx.lineTo(10 + Math.cos(a2) * 5, 4 + Math.sin(a2) * 5);
                                    ctx.stroke();
                                }
                                // Cloud
                                ctx.beginPath();
                                ctx.arc(4, 9, 3, Math.PI, 1.5 * Math.PI);
                                ctx.arc(7, 6.5, 3, 1.2 * Math.PI, 1.9 * Math.PI);
                                ctx.arc(10.5, 9, 2.5, 1.5 * Math.PI, 0);
                                ctx.lineTo(13, 11);
                                ctx.lineTo(1, 11);
                                ctx.closePath();
                                ctx.fill();
                            } else {
                                // Cloud base for cloudy/rain/snow/thunder/fog
                                ctx.beginPath();
                                ctx.arc(4, 8, 3, Math.PI, 1.5 * Math.PI);
                                ctx.arc(7, 5.5, 3, 1.2 * Math.PI, 1.9 * Math.PI);
                                ctx.arc(10.5, 8, 2.5, 1.5 * Math.PI, 0);
                                ctx.lineTo(13, 10);
                                ctx.lineTo(1, 10);
                                ctx.closePath();
                                ctx.fill();

                                if (type === "rain" || type === "thunder") {
                                    ctx.lineWidth = 1.2;
                                    ctx.beginPath(); ctx.moveTo(4, 11.5); ctx.lineTo(3, 13.5); ctx.stroke();
                                    ctx.beginPath(); ctx.moveTo(7, 11.5); ctx.lineTo(6, 13.5); ctx.stroke();
                                    ctx.beginPath(); ctx.moveTo(10, 11.5); ctx.lineTo(9, 13.5); ctx.stroke();
                                }
                                if (type === "thunder") {
                                    ctx.lineWidth = 1.4;
                                    ctx.beginPath();
                                    ctx.moveTo(8, 10); ctx.lineTo(6.5, 12); ctx.lineTo(8, 12); ctx.lineTo(6.5, 14);
                                    ctx.stroke();
                                }
                                if (type === "snow") {
                                    ctx.font = "8px sans-serif";
                                    ctx.fillText("*", 3, 13.5);
                                    ctx.fillText("*", 7, 13.5);
                                    ctx.fillText("*", 11, 13.5);
                                }
                                if (type === "fog") {
                                    ctx.lineWidth = 1;
                                    ctx.beginPath(); ctx.moveTo(2, 11.5); ctx.lineTo(12, 11.5); ctx.stroke();
                                    ctx.beginPath(); ctx.moveTo(3, 13); ctx.lineTo(11, 13); ctx.stroke();
                                }
                            }
                        }
                    }

                    Text {
                        visible: shell.weatherCondition !== ""
                        text: shell.weatherTemp
                        color: "#ffffff"
                        font.pixelSize: 13
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Text {
                        visible: shell.weatherEffectOverride !== ""
                        text: "(" + shell.weatherEffectOverride + ")"
                        color: Qt.rgba(1, 1, 1, 0.5)
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
                        if (mouse.button === Qt.RightButton)
                            shell.cycleWeatherEffect();
                        else
                            shell.showFullDate = !shell.showFullDate;
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

    // Toast notification popup - one per screen
    ToastNotification { shell: shell }

    // === Weather Effects Overlay ===
    WeatherOverlay { shell: shell }
}
