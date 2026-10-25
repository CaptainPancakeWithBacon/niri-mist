// Mist strip: slim top bar. Clock, workspace dots, focused window | cpu, mem, wifi, battery.
// The middle ~300px stays empty for the Coucou pill, which draws itself.
import Quickshell
import Quickshell.Io
import Quickshell.Services.UPower
import QtQuick

ShellRoot {
    id: root

    property bool night: false
    property var palette: night
        ? {ink: "#E4EAEF", slate: "#9AA8B5", mute: "#6B7886", bg: "#141A20"}
        : {ink: "#101418", slate: "#4A5764", mute: "#7C8A97", bg: "#DDE2E6"}
    property var workspaces: []
    property string focusedTitle: ""
    property int cpu: 0
    property int mem: 0
    property bool wifi: false
    property var now: new Date()
    property alias quickOpen: quick.open

    // One poller for everything shell-shaped; each parses a single line of stdout.
    component Poll: Item {
        id: poll
        property var command: []
        property int every: 2000
        signal line(string text)
        Process {
            id: proc
            command: poll.command
            stdout: StdioCollector { onStreamFinished: poll.line(text.trim()) }
        }
        Timer { interval: poll.every; running: true; repeat: true; triggeredOnStart: true; onTriggered: proc.running = true }
    }

    Process { id: power; command: ["mist-power"] }

    Timer { interval: 1000; running: true; repeat: true; onTriggered: root.now = new Date() }

    Poll {
        command: ["niri", "msg", "--json", "workspaces"]; every: 700
        onLine: text => { try { root.workspaces = JSON.parse(text).sort((a, b) => a.idx - b.idx) } catch (e) {} }
    }
    Poll {
        command: ["niri", "msg", "--json", "focused-window"]; every: 700
        onLine: text => { try { const w = JSON.parse(text); root.focusedTitle = w ? (w.app_id || "").split(".").pop() : "" } catch (e) { root.focusedTitle = "" } }
    }
    Poll {
        command: ["sh", "-c", "a=$(awk '/^cpu /{print $2+$3+$4, $2+$3+$4+$5+$6+$7+$8}' /proc/stat); sleep 0.5; b=$(awk '/^cpu /{print $2+$3+$4, $2+$3+$4+$5+$6+$7+$8}' /proc/stat); m=$(awk '/MemTotal/{t=$2}/MemAvailable/{a=$2}END{printf \"%d\", (t-a)*100/t}' /proc/meminfo); echo $a $b $m"]
        every: 3000
        onLine: text => {
            const p = text.split(" ").map(Number)
            if (p.length === 5 && p[3] > p[1]) { root.cpu = Math.round(100 * (p[2] - p[0]) / (p[3] - p[1])); root.mem = p[4] }
        }
    }
    Poll {
        command: ["sh", "-c", "nmcli -t -f TYPE,STATE dev | grep -q '^wifi:connected' && echo 1 || echo 0"]; every: 5000
        onLine: text => root.wifi = text === "1"
    }
    QuickSettings { id: quick; palette: root.palette }

    PanelWindow {
        id: strip
        anchors { top: true; left: true; right: true }
        implicitHeight: 38
        color: "transparent"

        Item {
            anchors { fill: parent; leftMargin: 22; rightMargin: 22 }

            Row {
                anchors.verticalCenter: parent.verticalCenter
                spacing: 18
                Text {
                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: power.running = true }
                    text: Qt.formatTime(root.now, "HH:mm")
                    font { family: "Hanken Grotesk"; pixelSize: 22; weight: Font.Light; letterSpacing: -0.4 }
                    color: root.palette.ink
                }
                Row {
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 6
                    Repeater {
                        model: root.workspaces
                        Rectangle {
                            width: modelData.is_focused ? 20 : 6; height: 6; radius: modelData.is_focused ? 4 : 3
                            color: modelData.is_focused ? root.palette.ink : root.palette.mute
                            opacity: modelData.is_focused ? 1 : 0.55
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }
                }
                Text {
                    text: root.focusedTitle
                    font { family: "Hanken Grotesk"; pixelSize: 15; weight: Font.Medium }
                    color: root.palette.slate
                    anchors.verticalCenter: parent.verticalCenter
                }
            }

            MouseArea {
                z: 2; anchors.fill: statusRow; cursorShape: Qt.PointingHandCursor
                onClicked: root.quickOpen = !root.quickOpen
            }
            Row {
                id: statusRow
                anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                spacing: 18
                component Label: Text {
                    font { family: "Hanken Grotesk"; pixelSize: 15; weight: Font.Medium }
                    color: root.palette.slate
                    anchors.verticalCenter: parent.verticalCenter
                }
                Label { text: root.cpu + "%" }
                Label { text: root.mem + "%" }
                Label { text: root.wifi ? "wifi" : "offline"; opacity: root.wifi ? 1 : 0.55 }
                Label {
                    visible: UPower.displayDevice.isPresent
                    text: Math.round(UPower.displayDevice.percentage * 100) + (UPower.displayDevice.state === UPowerDeviceState.Charging ? "+" : "")
                }
            }
        }
    }
}
