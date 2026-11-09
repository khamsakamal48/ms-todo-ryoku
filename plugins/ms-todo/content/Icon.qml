import QtQuick

// A Material Symbols Rounded glyph by ligature name ("check", "refresh", ...).
Text {
    property real size: 18
    property bool filled: false
    font.family: "Material Symbols Rounded"
    font.pixelSize: size
    font.variableAxes: ({ "FILL": filled ? 1 : 0, "wght": 500, "opsz": 24 })
    verticalAlignment: Text.AlignVCenter
    horizontalAlignment: Text.AlignHCenter
    renderType: Text.QtRendering
}
