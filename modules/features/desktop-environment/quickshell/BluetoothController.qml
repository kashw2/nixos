import Quickshell.Io
import QtQuick
import "."

Item {
    id: root
    required property var shell

    function refresh() {
        controllerCheck.running = true;
    }

    function toggle() {
        toggleProc.turnOn = !shell.bluetoothPowered;
        toggleProc.running = true;
    }

    function connectDevice(mac) {
        connectProc.mac = mac;
        connectProc.running = true;
    }

    function disconnectDevice(mac) {
        disconnectProc.mac = mac;
        disconnectProc.running = true;
    }

    function pairDevice(mac) {
        pairProc.mac = mac;
        pairProc.running = true;
    }

    Process {
        id: controllerCheck
        command: ["bluetoothctl", "show"]
        running: true
        property string output: ""
        stdout: SplitParser {
            onRead: data => {
                controllerCheck.output += data.toString() + "\n";
            }
        }
        onExited: (code, status) => {
            if (code === 0 && controllerCheck.output.length > 0) {
                root.shell.hasBluetooth = true;
                root.shell.bluetoothPowered = controllerCheck.output.indexOf("Powered: yes") !== -1;
            } else {
                root.shell.hasBluetooth = false;
            }
            controllerCheck.output = "";
            if (root.shell.hasBluetooth) {
                deviceCheck.running = true;
            }
        }
    }

    Process {
        id: deviceCheck
        command: ["bluetoothctl", "devices", "Paired"]
        property var devices: []
        stdout: SplitParser {
            onRead: data => {
                var line = data.toString().trim();
                if (line.startsWith("Device ")) {
                    var parts = line.substring(7);
                    var mac = parts.substring(0, 17);
                    var name = parts.substring(18);
                    deviceCheck.devices.push({ mac: mac, name: name });
                }
            }
        }
        onExited: (code, status) => {
            root.shell.btPairedDevices = deviceCheck.devices;
            deviceCheck.devices = [];
            connectedCheck.connectedMacs = [];
            connectedCheck.running = true;
        }
    }

    Process {
        id: connectedCheck
        command: ["bluetoothctl", "devices", "Connected"]
        property var connectedMacs: []
        stdout: SplitParser {
            onRead: data => {
                var line = data.toString().trim();
                if (line.startsWith("Device ")) {
                    var mac = line.substring(7, 24);
                    connectedCheck.connectedMacs.push(mac);
                }
            }
        }
        onExited: (code, status) => {
            root.shell.btConnectedDevices = connectedCheck.connectedMacs;
            connectedCheck.connectedMacs = [];
        }
    }

    Process {
        id: toggleProc
        property bool turnOn: true
        command: ["bluetoothctl", "power", turnOn ? "on" : "off"]
        onExited: controllerCheck.running = true
    }

    Process {
        id: connectProc
        property string mac: ""
        command: ["bluetoothctl", "connect", mac]
        onExited: {
            deviceCheck.devices = [];
            deviceCheck.running = true;
        }
    }

    Process {
        id: disconnectProc
        property string mac: ""
        command: ["bluetoothctl", "disconnect", mac]
        onExited: {
            deviceCheck.devices = [];
            deviceCheck.running = true;
        }
    }

    // Scan while the bluetooth popup is open.
    // `bluetoothctl scan on` without --timeout does NOT actually start discovery
    // in non-interactive mode (it only sets the discovery filter). --timeout uses
    // a different code path that calls StartDiscovery. We restart it in onExited
    // while the popup is still open to keep scanning going.
    Process {
        id: scanProc
        command: ["bluetoothctl", "--timeout", "30", "scan", "on"]
        running: root.shell.activePopup === "bt" && root.shell.bluetoothPowered
        onRunningChanged: root.shell.btScanning = running
        onExited: (code, status) => {
            if (root.shell.activePopup === "bt" && root.shell.bluetoothPowered) {
                scanProc.running = true;
            }
        }
    }

    Process {
        id: discoveredCheck
        command: ["bluetoothctl", "devices"]
        property var devices: []
        stdout: SplitParser {
            onRead: data => {
                var line = data.toString().trim();
                if (line.startsWith("Device ")) {
                    var parts = line.substring(7);
                    var mac = parts.substring(0, 17);
                    var name = parts.substring(18);
                    discoveredCheck.devices.push({ mac: mac, name: name });
                }
            }
        }
        onExited: (code, status) => {
            var pairedMacs = root.shell.btPairedDevices.map(function(d) { return d.mac; });
            // Exclude devices that look like raw MAC addresses (unnamed devices are reported
            // with `-` as the separator, e.g. name "4A-D0-CF-29-58-81" for MAC 4A:D0:CF:29:58:81),
            // and filter out already-paired devices.
            root.shell.btDiscoveredDevices = discoveredCheck.devices.filter(function(d) {
                if (pairedMacs.indexOf(d.mac) !== -1) return false;
                if (!d.name) return false;
                if (d.name === d.mac) return false;
                if (d.name === d.mac.replace(/:/g, "-")) return false;
                return true;
            });
            discoveredCheck.devices = [];
        }
    }

    // Poll for newly discovered devices while the popup is open.
    Timer {
        interval: 2500
        repeat: true
        running: root.shell.activePopup === "bt" && root.shell.bluetoothPowered
        triggeredOnStart: true
        onTriggered: {
            discoveredCheck.devices = [];
            discoveredCheck.running = true;
        }
    }

    Process {
        id: pairProc
        property string mac: ""
        command: ["bluetoothctl", "pair", mac]
        onExited: (code, status) => {
            // Refresh paired list and auto-connect on successful pair.
            deviceCheck.devices = [];
            deviceCheck.running = true;
            if (code === 0) {
                connectProc.mac = pairProc.mac;
                connectProc.running = true;
            }
        }
    }
}
