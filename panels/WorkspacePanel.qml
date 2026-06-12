import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Io

PanelWindow {
    id: wsPanel
    required property var root

    property var wsList: []
    property int wsFocusedId: 1

    color: "transparent"
    anchors { top: true; bottom: true; left: true; right: true }
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "omaniri-workspace"

    readonly property int barBottom: 35
    readonly property int gap: 8

    property real reveal: root.workspaceVisible ? 1 : 0
    Behavior on reveal {
        NumberAnimation {
            duration: root.workspaceVisible ? 160 : 120
            easing.type: root.workspaceVisible ? Easing.OutCubic : Easing.InCubic
        }
    }
    visible: reveal > 0.001
    WlrLayershell.keyboardFocus: root.workspaceVisible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    function parseNiriWorkspaces(text) {
        var lines = text.trim().split("\n")
        var ids = []
        var focused = 1
        var wsMap = {}
        for (var i = 0; i < lines.length; i++) {
            var line = lines[i].trim()
            if (line.indexOf("Output") === 0) continue
            if (line.indexOf("---") === 0) continue
            var isFocused = line.indexOf("* ") === 0
            var rest = (isFocused ? line.substr(2) : line).trim()
            var parts = rest.split(" ")
            var id = parseInt(parts[0])
            if (!isNaN(id)) {
                if (!wsMap[id]) {
                    wsMap[id] = { id: id, name: parts.length > 1 ? parts.slice(1).join(" ").replace(/"/g, "") : String(id) }
                    ids.push(id)
                }
                if (isFocused) focused = id
            }
        }
        ids.sort(function(a, b) { return a - b })
        var list = ids.map(function(id) { return wsMap[id] })
        wsList = list
        wsFocusedId = focused
    }

    Process {
        id: wsProc
        command: ["niri", "msg", "workspaces"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: { wsPanel.parseNiriWorkspaces(this.text) }
        }
    }

    Timer {
        interval: 1000; running: true; repeat: true; triggeredOnStart: false
        onTriggered: { wsProc.running = false; wsProc.running = true }
    }

    MouseArea { anchors.fill: parent; onClicked: root.workspaceVisible = false }

    Rectangle {
        id: card
        width: 240
        height: col.implicitHeight + 24
        radius: 6
        color: root.bg
        border.color: root.sep
        border.width: 1

        x: Math.round(Math.max(6, Math.min(root.workspaceBarX - width / 2, parent.width - width - 6)))
        y: barBottom + gap
        opacity: wsPanel.reveal
        focus: root.workspaceVisible

        Keys.onPressed: function(event) {
            if (event.key === Qt.Key_Escape) { root.workspaceVisible = false; event.accepted = true }
        }

        MouseArea { anchors.fill: parent; onClicked: {} }

        Column {
            id: col
            anchors.fill: parent
            anchors.margins: 12
            spacing: 8

            Item {
                width: parent.width
                height: 24
                Text {
                    anchors.left: parent.left; anchors.verticalCenter: parent.verticalCenter
                    text: "Workspaces"
                    color: root.ink; font.family: root.mono; font.pixelSize: 13
                    font.letterSpacing: 2; font.weight: Font.Medium
                }
                Text {
                    anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter
                    text: "\u2715"; color: closeMa.containsMouse ? root.seal : root.sumi; font.pixelSize: 12
                    Behavior on color { ColorAnimation { duration: 120 } }
                    MouseArea { id: closeMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.workspaceVisible = false }
                }
            }

            Rectangle { width: parent.width; height: 1; color: root.sep }

            Column {
                width: parent.width
                spacing: 4
                Repeater {
                    model: wsPanel.wsList

                    delegate: Rectangle {
                        required property var modelData
                        readonly property bool isActive: wsPanel.wsFocusedId === modelData.id
                        width: col.width
                        height: 30; radius: 4
                        color: ma.containsMouse ? Qt.rgba(root.seal.r, root.seal.g, root.seal.b, 0.18)
                                : isActive ? Qt.rgba(root.seal.r, root.seal.g, root.seal.b, 0.15)
                                : "transparent"
                        border.color: (ma.containsMouse || isActive) ? root.seal : "transparent"
                        border.width: (ma.containsMouse || isActive) ? 1 : 0
                        Behavior on color { ColorAnimation { duration: 120 } }

                        Text {
                            anchors.left: parent.left; anchors.leftMargin: 10
                            anchors.verticalCenter: parent.verticalCenter
                            text: "Workspace " + modelData.id
                            color: (ma.containsMouse || isActive) ? root.seal : root.ink
                            font.family: root.mono; font.pixelSize: 12
                            font.weight: isActive ? Font.Medium : Font.Normal
                        }

                        MouseArea {
                            id: ma
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                root.gotoWorkspace(modelData.id)
                                root.workspaceVisible = false
                            }
                        }
                    }
                }
            }
        }
    }

}
