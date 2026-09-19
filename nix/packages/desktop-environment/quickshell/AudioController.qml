import Quickshell.Io
import QtQuick
import "."

Item {
    id: root
    required property var shell

    function refresh() {
        volumeCheck.running = true;
        micCheck.running = true;
    }

    function refreshDevices() {
        audioDevicesCheck.running = true;
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

    function setDefaultDevice(id) {
        audioDeviceSet.target = id;
        audioDeviceSet.running = true;
    }

    Process {
        id: volumeCheck
        command: ["wpctl", "get-volume", "@DEFAULT_AUDIO_SINK@"]
        running: true
        stdout: SplitParser {
            onRead: data => {
                var line = data.toString().trim();
                // Format: "Volume: 0.50" or "Volume: 0.50 [MUTED]"
                root.shell.volumeMuted = line.indexOf("[MUTED]") !== -1;
                var match = line.match(/Volume:\s+([\d.]+)/);
                if (match) {
                    root.shell.volumePercent = Math.round(parseFloat(match[1]) * 100);
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
                root.shell.micMuted = line.indexOf("[MUTED]") !== -1;
                var match = line.match(/Volume:\s+([\d.]+)/);
                if (match) {
                    root.shell.micGainPercent = Math.round(parseFloat(match[1]) * 100);
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
            root.shell.audioSinks = pendingSinks;
            root.shell.audioSources = pendingSources;
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
        running: root.shell.activePopup === "volume"
        stdout: SplitParser {
            onRead: data => {
                var v = parseInt(data.toString().trim());
                if (isNaN(v)) return;
                var newLevel = Math.min(1, v / 128);
                // Fast attack, gentle decay so the meter feels analog.
                if (newLevel > root.shell.micLevel) {
                    root.shell.micLevel = newLevel;
                } else {
                    root.shell.micLevel = root.shell.micLevel * 0.7 + newLevel * 0.3;
                }
            }
        }
        onRunningChanged: {
            if (!running) root.shell.micLevel = 0;
        }
    }
}
