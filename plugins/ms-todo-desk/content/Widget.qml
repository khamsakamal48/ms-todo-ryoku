pragma ComponentBehavior: Bound

import QtQuick

// The desktop tile: frosted glass over the wallpaper with the task view on
// top. Ryoku owns drag, scale and lock (right-click the tile); the manifest
// asks the host for no card of its own (bg "none") so the glass shows.
Item {
    id: root

    property var pluginApi
    property var screen
    property bool active: false
    property string density: "compact"
    property real s: 1
    property real widthBudget: 0

    readonly property var service: pluginApi ? pluginApi.mainInstance : null
    readonly property var cfg: pluginApi ? pluginApi.pluginSettings : null
    readonly property real tileW: (cfg && cfg.tileWidth ? cfg.tileWidth : 360) * root.s
    readonly property real bodyH: (cfg && cfg.tileHeight ? cfg.tileHeight : 380) * root.s

    // While the new-task card has a focused field, the desktop host gives this
    // tile the keyboard (Ryoku reads `editing` on the content root).
    readonly property bool editing: view.editing

    implicitWidth: tileW
    implicitHeight: view.implicitHeight

    Style {
        id: style
        appearance: root.cfg && root.cfg.appearance ? root.cfg.appearance : "light"
        accentKey: root.cfg && root.cfg.accent ? root.cfg.accent : "blue"
        fontKey: root.cfg && root.cfg.font ? root.cfg.font : "inter"
        tintLevel: root.cfg && root.cfg.translucency !== undefined ? 100 - Number(root.cfg.translucency) : 48
        blurLevel: root.cfg && root.cfg.blur !== undefined ? Number(root.cfg.blur) : 100
    }

    Glass {
        anchors.fill: parent
        st: style
        s: root.s
    }

    TaskView {
        id: view
        width: root.tileW
        service: root.service
        st: style
        s: root.s
        maxBodyHeight: root.bodyH
    }
}
