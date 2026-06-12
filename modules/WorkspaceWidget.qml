import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: wsWidget
    required property var root

    property var niriWorkspaces: []
    property int niriFocusedId: 1

    function parseNiriWorkspaces(text) {
        var lines = text.trim().split("\n")
        var ids = []
        var focused = 1
        for (var i = 0; i < lines.length; i++) {
            var line = lines[i].trim()
            if (line.indexOf("Output") === 0) continue
            if (line.indexOf("---") === 0) continue
            var isFocused = line.indexOf("* ") === 0
            var idStr = (isFocused ? line.substr(2) : line).trim().split(" ")[0]
            var id = parseInt(idStr)
            if (!isNaN(id)) {
                if (ids.indexOf(id) < 0) ids.push(id)
                if (isFocused) focused = id
            }
        }
        ids.sort(function(a, b) { return a - b })
        niriWorkspaces = ids
        niriFocusedId = focused
    }

    readonly property var workspaceList: {
        if (root.workspaceMode === "active")
            return niriWorkspaces.length > 0 ? niriWorkspaces : [1]
        var n = root.workspaceMode === "5" ? 5 : 10
        var list = []; for (var j = 1; j <= n; j++) list.push(j)
        return list
    }

    Process {
        id: wsProc
        command: ["niri", "msg", "workspaces"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: { wsWidget.parseNiriWorkspaces(this.text) }
        }
    }

    Timer {
        interval: 1000; running: true; repeat: true; triggeredOnStart: false
        onTriggered: { wsProc.running = false; wsProc.running = true }
    }

    Rectangle {
        x: -4; anchors.verticalCenter: parent.verticalCenter
        width: Math.round(wsRow.width) + 8
        height: 24
        radius: 12
        color: root.pill
        border.color: root.sep
        border.width: 1
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.RightButton
        cursorShape: Qt.PointingHandCursor
        onClicked: root.workspaceVisible = !root.workspaceVisible
    }

    Row {
        id: wsRow
        anchors.centerIn: parent
        spacing: 5

        Repeater {
            model: wsWidget.workspaceList

            delegate: Item {
                required property int modelData
                readonly property int wsId: modelData

                readonly property bool isFocused: wsWidget.niriFocusedId === wsId

                readonly property bool isOccupied: wsWidget.niriWorkspaces.indexOf(wsId) >= 0
                    && wsWidget.niriFocusedId !== wsId

                readonly property bool isEmpty: !isFocused && !isOccupied

                implicitWidth: isFocused ? 32 : 16
                implicitHeight: 28

                Behavior on implicitWidth {
                    NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
                }

                Rectangle {
                    anchors.centerIn: parent
                    width:  isFocused ? 34 : 16
                    height: isFocused ? 16 : 16
                    radius: isFocused ?  8 :  8
                    color: isFocused
                        ? Qt.rgba(root.seal.r, root.seal.g, root.seal.b, 0.20)
                        : isOccupied
                        ? Qt.rgba(root.seal.r, root.seal.g, root.seal.b, 0.18)
                        : Qt.rgba(root.seal.r, root.seal.g, root.seal.b, 0.06)

                    Behavior on width { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
                    Behavior on color { ColorAnimation { duration: 200 } }
                }

                Rectangle {
                    id: dot
                    anchors.centerIn: parent
                    width:  isFocused  ? 26 : 8
                    height: 8
                    radius: 4
                    color:  isFocused
                        ? root.seal
                        : isOccupied
                        ? root.seal
                        : Qt.rgba(root.seal.r, root.seal.g, root.seal.b, 0.25)

                    Behavior on width { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
                    Behavior on color { ColorAnimation { duration: 200 } }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    hoverEnabled: true
                    onClicked: root.gotoWorkspace(wsId)
                    onEntered: dot.scale = 1.2
                    onExited:  dot.scale = 1.0
                }
            }
        }
    }

}
