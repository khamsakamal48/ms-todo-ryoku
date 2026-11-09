pragma ComponentBehavior: Bound

import QtQuick
import Ryoku.PluginKit.Singletons

// The bar glyph: a check-box mark and the badge count (open / due / high,
// per the "Badge counts" setting). Click opens the panel; it never changes a task.
Item {
    id: root

    property var pluginApi
    property var screen
    property bool active: false
    property string density: "glyph"
    property real s: 1
    property real widthBudget: 0

    readonly property var service: pluginApi ? pluginApi.mainInstance : null
    readonly property int badge: service ? service.badge : -1
    readonly property bool ready: service ? service.phase === "ready" : false
    readonly property bool hot: service ? service.dueCount > 0 : false

    readonly property real sidePad: 3 * root.s
    implicitWidth: row.implicitWidth + 2 * root.sidePad
    implicitHeight: Math.max(row.implicitHeight, 18 * root.s)

    Row {
        id: row
        x: root.sidePad
        anchors.verticalCenter: parent.verticalCenter
        spacing: 5 * root.s

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: root.ready ? "" : ""   // checked / empty square
            color: Theme.accent
            opacity: root.ready ? 1 : 0.5
            font.family: Theme.mono
            font.pixelSize: 14 * root.s
        }
        Text {
            visible: root.ready && root.badge >= 0
            anchors.verticalCenter: parent.verticalCenter
            text: root.badge
            color: root.hot && root.service.badgeMode !== "high" ? Theme.sun : Theme.accent
            font.family: Theme.font
            font.pixelSize: 12 * root.s
        }
    }

    MouseArea {
        anchors.fill: parent
        onClicked: if (root.pluginApi) root.pluginApi.togglePanel()
    }
}
