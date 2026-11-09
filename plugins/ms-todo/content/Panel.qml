import QtQuick

// The bar panel: the full task view under the glyph. The bar host draws the
// card, so this paints only the content, in the chosen appearance.
Item {
    id: root

    property var pluginApi
    property string density: "full"
    property real s: 1
    property real widthBudget: 360
    property bool active: false

    readonly property var service: pluginApi ? pluginApi.mainInstance : null
    readonly property var cfg: pluginApi ? pluginApi.pluginSettings : null

    implicitWidth: root.widthBudget
    implicitHeight: view.implicitHeight

    Style {
        id: style
        appearance: root.cfg && root.cfg.appearance ? root.cfg.appearance : "theme"
        accentKey: root.cfg && root.cfg.accent ? root.cfg.accent : "blue"
        fontKey: root.cfg && root.cfg.font ? root.cfg.font : "inter"
    }

    // Re-check on open, so the panel is fresh without waiting for the timer.
    onActiveChanged: if (active && service && !service.refreshing) service.refresh()

    TaskView {
        id: view
        width: root.width
        service: root.service
        st: style
        s: root.s
        pad: 16 * root.s
        maxBodyHeight: 460 * root.s
    }
}
