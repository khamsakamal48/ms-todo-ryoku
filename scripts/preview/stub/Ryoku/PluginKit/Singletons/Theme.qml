pragma Singleton
import QtQuick
// Stand-in for Ryoku.PluginKit's Theme so the preview renders outside the shell.
QtObject {
    readonly property color accent: "#007aff"
    readonly property color cardBot: "#f2f2f7"
    readonly property string font: "Inter"
    readonly property string display: "Inter Display"
    readonly property string mono: "JetBrainsMono Nerd Font"
}
