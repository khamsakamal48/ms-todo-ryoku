import QtQuick
import Ryoku.PluginKit.Singletons

// Design tokens for the task view: Apple-style "materials" in light and dark,
// a system-blue accent (or the Ryoku theme accent), and one font family.
// Views read colours from here, never from raw hex.
QtObject {
    id: st

    // inputs, from plugin settings
    property string appearance: "light"   // light | dark | theme
    property string accentKey: "blue"     // blue | theme | green | orange | purple | pink
    property string fontKey: "inter"      // inter | google | theme
    property real tintLevel: 52           // 0 = clear glass … 100 = solid (Translucency setting)
    property real blurLevel: 100          // 0 = sharp wallpaper … 100 = fully frosted

    readonly property bool themeDark: {
        const c = Theme.cardBot;
        return (0.2126 * c.r + 0.7152 * c.g + 0.0722 * c.b) < 0.5;
    }
    readonly property bool dark: appearance === "dark" || (appearance === "theme" && themeDark)

    // ---- material (the glass tint laid over the blurred wallpaper)
    readonly property real tintAlpha: Math.max(0, Math.min(1, tintLevel / 100))
    readonly property color tint: dark ? Qt.rgba(0.11, 0.11, 0.13, tintAlpha) : Qt.rgba(1, 1, 1, tintAlpha)
    readonly property color solid: dark ? "#1c1c1e" : "#f5f5f7"          // when no wallpaper
    readonly property color rim: dark ? Qt.rgba(1, 1, 1, 0.16) : Qt.rgba(1, 1, 1, 0.65)
    readonly property color rimOuter: dark ? Qt.rgba(0, 0, 0, 0.35) : Qt.rgba(0, 0, 0, 0.08)
    readonly property color shadow: Qt.rgba(0, 0, 0, dark ? 0.45 : 0.22)

    // ---- ink
    readonly property color ink: dark ? "#f5f5f7" : "#1d1d1f"
    readonly property color ink2: dark ? Qt.rgba(235/255, 235/255, 245/255, 0.68) : Qt.rgba(60/255, 60/255, 67/255, 0.78)
    readonly property color ink3: dark ? Qt.rgba(235/255, 235/255, 245/255, 0.42) : Qt.rgba(60/255, 60/255, 67/255, 0.50)
    readonly property color fill: dark ? Qt.rgba(1, 1, 1, 0.08) : Qt.rgba(0, 0, 0, 0.045)
    readonly property color fillHover: dark ? Qt.rgba(1, 1, 1, 0.13) : Qt.rgba(0, 0, 0, 0.075)
    readonly property color hairline: dark ? Qt.rgba(1, 1, 1, 0.09) : Qt.rgba(0, 0, 0, 0.07)
    readonly property color ring: dark ? Qt.rgba(235/255, 235/255, 245/255, 0.38) : Qt.rgba(60/255, 60/255, 67/255, 0.32)

    // ---- colour
    readonly property color accent: accentKey === "theme" ? Theme.accent
        : accentKey === "green" ? (dark ? "#30d158" : "#28a745")
        : accentKey === "orange" ? (dark ? "#ff9f0a" : "#f08c00")
        : accentKey === "purple" ? (dark ? "#bf5af2" : "#9b4dca")
        : accentKey === "pink" ? (dark ? "#ff375f" : "#e6375a")
        : (dark ? "#0a84ff" : "#007aff")
    readonly property color danger: dark ? "#ff453a" : "#e5372c"
    readonly property color accentInk: "#ffffff"
    // text-weight variants: brighter on dark glass so small coloured text keeps contrast
    readonly property color accentText: dark ? Qt.lighter(accent, 1.45) : accent
    readonly property color dangerText: dark ? Qt.lighter(danger, 1.3) : danger
    function soft(c, a) { return Qt.rgba(c.r, c.g, c.b, a); }

    // ---- type
    readonly property string font: fontKey === "google" ? "Google Sans Flex"
        : fontKey === "theme" ? Theme.font : "Inter"
    readonly property string display: fontKey === "google" ? "Google Sans Flex"
        : fontKey === "theme" ? Theme.display : "Inter Display"
    readonly property string icons: "Material Symbols Rounded"
    readonly property string mono: Theme.mono

    // ---- shape
    readonly property real radius: 24
    readonly property real rowRadius: 10
}
