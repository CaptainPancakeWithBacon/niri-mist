// Quick settings card, opened from the right side of the strip.
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.UPower
import QtQuick

PanelWindow {
    id: win
    required property var palette
    property bool open: false

    visible: open
    anchors { top: true; left: true; right: true; bottom: true }
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

    property bool wifiOn: false
    property string ssid: ""
    property bool btOn: false
    property bool dnd: false
    property real vol: 0
    property real bright: 0
    property int brightMax: 1
    property bool dragging: false

    readonly property color ink: "#101418"
    readonly property color paper: "#F6F8F9"
    readonly property color tile: "#EAEFF2"
    readonly property color line: "#DCE2E6"
    readonly property color slate: "#4A5764"

    function run(cmd) { Quickshell.execDetached(cmd); refresh.start() }
    function setVolume(v) { vol = v; Quickshell.execDetached(["wpctl", "set-volume", "@DEFAULT_AUDIO_SINK@", v.toFixed(2)]) }
    function setBrightness(v) {
        bright = v
        const raw = Math.max(Math.round(brightMax * 0.05), Math.round(v * brightMax))
        Quickshell.execDetached(["busctl", "call", "org.freedesktop.login1", "/org/freedesktop/login1/session/auto",
            "org.freedesktop.login1.Session", "SetBrightness", "ssu", "backlight", "amdgpu_bl0", String(raw)])
    }

    Process {
        id: status
        command: ["sh", "-c",
            "w=$(nmcli radio wifi); s=$(nmcli -t -f ACTIVE,SSID dev wifi | grep '^yes' | head -1 | cut -d: -f2);" +
            "b=$(bluetoothctl show 2>/dev/null | awk '/Powered:/{print $2}'); d=$(makoctl mode 2>/dev/null | grep -c do-not-disturb);" +
            "v=$(wpctl get-volume @DEFAULT_AUDIO_SINK@ | awk '{print $2}'); l=$(cat /sys/class/backlight/*/brightness | head -1); m=$(cat /sys/class/backlight/*/max_brightness | head -1);" +
            "echo \"$w|$s|$b|$d|$v|$l|$m\""]
        stdout: StdioCollector {
            onStreamFinished: {
                const p = text.trim().split("|")
                if (p.length < 7 || win.dragging) return
                win.wifiOn = p[0] === "enabled"; win.ssid = p[1]; win.btOn = p[2] === "yes"; win.dnd = p[3] === "1"
                win.vol = Math.min(1, Number(p[4]) || 0); win.brightMax = Number(p[6]) || 1; win.bright = (Number(p[5]) || 0) / win.brightMax
            }
        }
    }
    Timer { id: poll; interval: 3000; running: win.open; repeat: true; triggeredOnStart: true; onTriggered: status.running = true }
    Timer { id: refresh; interval: 400; onTriggered: status.running = true }

    MouseArea { anchors.fill: parent; onClicked: win.open = false }
    Item { focus: true; Keys.onEscapePressed: win.open = false }

    Rectangle {
        id: card
        anchors { top: parent.top; right: parent.right; topMargin: 46; rightMargin: 14 }
        width: 420; height: col.implicitHeight + 48
        radius: 28; color: win.paper; border { width: 1; color: win.line }
        MouseArea { anchors.fill: parent }  // clicks on the card must not close it

        Column {
            id: col
            anchors { left: parent.left; right: parent.right; top: parent.top; margins: 24 }
            spacing: 18

            Row {
                spacing: 14
                Text {
                    text: UPower.displayDevice.isPresent ? Math.round(UPower.displayDevice.percentage * 100) + "%" : "AC"
                    font { family: "Hanken Grotesk"; pixelSize: 64; weight: Font.Thin; letterSpacing: -2 }
                    color: win.ink
                }
                Text {
                    anchors.bottom: parent.bottom; anchors.bottomMargin: 12
                    visible: UPower.displayDevice.isPresent
                    text: UPower.displayDevice.state === UPowerDeviceState.Charging ? "Charging"
                        : UPower.displayDevice.timeToEmpty > 0 ? Math.floor(UPower.displayDevice.timeToEmpty / 3600) + " h " + Math.round(UPower.displayDevice.timeToEmpty % 3600 / 60) + " min left" : ""
                    font { family: "Hanken Grotesk"; pixelSize: 14 }
                    color: win.slate
                }
            }

            Grid {
                columns: 2; spacing: 10
                component Tile: Rectangle {
                    id: tile
                    property string title
                    property string sub
                    property bool on: false
                    signal clicked
                    width: (col.width - 10) / 2; height: 62; radius: 20
                    color: on ? win.ink : win.tile
                    Column {
                        anchors { left: parent.left; leftMargin: 18; verticalCenter: parent.verticalCenter }
                        Text { text: tile.title; font { family: "Hanken Grotesk"; pixelSize: 15; weight: Font.DemiBold }
                        color: tile.on ? win.paper : win.ink }
                        Text { text: tile.sub; font { family: "Hanken Grotesk"; pixelSize: 12 }
                        color: tile.on ? "#B8C2CB" : win.slate }
                    }
                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: tile.clicked() }
                }
                Tile { title: "Wi-Fi"; sub: win.wifiOn ? (win.ssid || "On") : "Off"; on: win.wifiOn
                    onClicked: win.run(["nmcli", "radio", "wifi", win.wifiOn ? "off" : "on"]) }
                Tile { title: "Bluetooth"; sub: win.btOn ? "On" : "Off"; on: win.btOn
                    onClicked: win.run(["bluetoothctl", "power", win.btOn ? "off" : "on"]) }
                Tile { title: "Do not disturb"; sub: win.dnd ? "On" : "Off"; on: win.dnd
                    onClicked: win.run(["makoctl", "mode", "-t", "do-not-disturb"]) }
                Tile { title: "Airplane"; sub: (!win.wifiOn && !win.btOn) ? "On" : "Off"; on: !win.wifiOn && !win.btOn
                    onClicked: { const off = !win.wifiOn && !win.btOn; win.run(["sh", "-c", off ? "nmcli radio wifi on; bluetoothctl power on" : "nmcli radio wifi off; bluetoothctl power off"]) } }
            }

            component Slide: Item {
                id: slide
                property string label
                property real value: 0
                signal moved(real v)
                width: col.width; height: 28
                Text { id: lab; text: slide.label; width: 70; anchors.verticalCenter: parent.verticalCenter
                    font { family: "Hanken Grotesk"; pixelSize: 14 }
                        color: win.slate }
                Rectangle {
                    id: track
                    anchors { left: lab.right; right: pct.left; rightMargin: 12; verticalCenter: parent.verticalCenter }
                    height: 6; radius: 3; color: win.line
                    Rectangle { width: parent.width * slide.value; height: parent.height; radius: 3; color: win.ink }
                    Rectangle { x: Math.max(0, Math.min(parent.width - 18, parent.width * slide.value - 9)); anchors.verticalCenter: parent.verticalCenter
                        width: 18; height: 18; radius: 9; color: win.ink }
                }
                Text { id: pct; text: Math.round(slide.value * 100); width: 30; horizontalAlignment: Text.AlignRight
                    anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                    font { family: "Hanken Grotesk"; pixelSize: 13 }
                        color: win.slate }
                MouseArea {
                    anchors { left: track.left; right: track.right; verticalCenter: parent.verticalCenter }
                    height: 28; cursorShape: Qt.PointingHandCursor
                    function pick(x) { slide.moved(Math.max(0, Math.min(1, x / width))) }
                    onPressed: mouse => { win.dragging = true; pick(mouse.x) }
                    onPositionChanged: mouse => { if (pressed) pick(mouse.x) }
                    onReleased: { win.dragging = false }
                }
            }
            Slide { label: "Volume"; value: win.vol; onMoved: v => win.setVolume(v) }
            Slide { label: "Brightness"; value: win.bright; onMoved: v => win.setBrightness(v) }

            Rectangle { width: parent.width; height: 1; color: win.line }

            Row {
                spacing: 10
                component Act: Rectangle {
                    id: act
                    property string title
                    signal clicked
                    width: (col.width - 20) / 3; height: 44; radius: 16; color: win.tile
                    Text { anchors.centerIn: parent; text: act.title; font { family: "Hanken Grotesk"; pixelSize: 14; weight: Font.Medium }
                        color: win.ink }
                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: act.clicked() }
                }
                Act { title: "Screenshot"; onClicked: { win.open = false; win.run(["niri", "msg", "action", "screenshot"]) } }
                Act { title: "Lock"; onClicked: { win.open = false; win.run(["swaylock", "-f"]) } }
                Act { title: "Power"; onClicked: { win.open = false; win.run(["mist-power"]) } }
            }
        }
    }
}
