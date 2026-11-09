import QtQuick
import QtQuick.Effects
import QtQuick.Window
import Quickshell
import Quickshell.Io

// Frosted glass: a blurred, slightly saturated copy of the wallpaper lined up
// with where this tile sits on screen, a material tint on top, a lit rim and a
// soft shadow. Reads (never writes) the wallpaper path Ryoku keeps in
// $XDG_STATE_HOME/ryoku-wallpaper; a video wallpaper uses its still frame.
Item {
    id: glass

    property var st                  // Style
    property real s: 1
    property bool live: true         // false: tint only (e.g. while hidden)
    readonly property real r: st.radius * s
    readonly property real m: 40 * s // over-scan so the blur never samples past the edge

    readonly property string stateDir: Quickshell.env("XDG_STATE_HOME") || (Quickshell.env("HOME") + "/.local/state")
    property string wallPath: ""
    readonly property bool video: /\.(mp4|webm|mkv|mov)$/i.test(wallPath)
    readonly property string wallUrl: wallPath === "" ? ""
        : "file://" + (video ? stateDir + "/ryoku-live-frame.png" : wallPath)

    FileView {
        path: glass.stateDir + "/ryoku-wallpaper"
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onLoaded: glass.wallPath = (text() || "").trim()
    }

    // Where the full-screen wallpaper lands in this item's coordinates. Not a
    // binding (mapFromItem isn't reactive), so re-measure on a short tick; it
    // follows drags, scale and parallax at no visible cost.
    property rect wallRect: Qt.rect(0, 0, 0, 0)
    function measure() {
        const w = glass.Window.width, h = glass.Window.height;
        if (!w || !h) return;
        const a = glass.mapFromItem(null, 0, 0), b = glass.mapFromItem(null, w, h);
        const next = Qt.rect(a.x, a.y, b.x - a.x, b.y - a.y);
        if (Math.abs(next.x - wallRect.x) > 0.5 || Math.abs(next.y - wallRect.y) > 0.5
            || Math.abs(next.width - wallRect.width) > 0.5)
            wallRect = next;
    }
    Timer { interval: 120; running: glass.visible && glass.live; repeat: true; triggeredOnStart: true; onTriggered: glass.measure() }

    // soft drop shadow
    RectangularShadow {
        anchors.fill: parent
        radius: glass.r
        offset.y: 10 * glass.s
        blur: 36 * glass.s
        spread: -4 * glass.s
        color: glass.st.shadow
    }

    // opaque fallback (no wallpaper yet / image failed)
    Rectangle {
        anchors.fill: parent
        radius: glass.r
        color: glass.st.solid
        visible: wall.status !== Image.Ready
    }

    // wallpaper slice, over-scanned by m on every side
    Item {
        id: slice
        x: -glass.m; y: -glass.m
        width: glass.width + 2 * glass.m
        height: glass.height + 2 * glass.m
        visible: false
        layer.enabled: true
        Image {
            id: wall
            source: glass.live ? glass.wallUrl : ""
            x: glass.wallRect.x + glass.m
            y: glass.wallRect.y + glass.m
            width: glass.wallRect.width
            height: glass.wallRect.height
            fillMode: Image.PreserveAspectCrop
            sourceSize.width: 1280      // it is blurred anyway; keep memory low
            asynchronous: true
            cache: true
            smooth: true
        }
    }

    // rounded cut-out, same over-scanned frame as the slice
    Item {
        id: mask
        x: slice.x; y: slice.y
        width: slice.width; height: slice.height
        visible: false
        layer.enabled: true
        Rectangle {
            x: glass.m; y: glass.m
            width: glass.width; height: glass.height
            radius: glass.r
            color: "white"
        }
    }

    // Clip to the tile: MultiEffect's output (and any padding) must never
    // spill past it; the mask then rounds the corners inside this box.
    Item {
        anchors.fill: parent
        clip: true
        visible: wall.status === Image.Ready
    MultiEffect {
        x: slice.x; y: slice.y
        width: slice.width; height: slice.height
        source: slice
        autoPaddingEnabled: false
        blurEnabled: glass.st.blurLevel > 0
        blur: Math.max(0, Math.min(1, glass.st.blurLevel / 100))
        blurMax: 64
        blurMultiplier: 0.6
        saturation: 0.35
        brightness: glass.st.dark ? -0.06 : 0.04
        maskEnabled: true
        maskSource: mask
        maskThresholdMin: 0.5
        maskSpreadAtMin: 1.0
    }
    }

    // material tint
    Rectangle {
        anchors.fill: parent
        radius: glass.r
        color: glass.st.tint
    }
    // top sheen: light catching the upper edge
    Rectangle {
        anchors.fill: parent
        radius: glass.r
        gradient: Gradient {
            GradientStop { position: 0.0; color: Qt.rgba(1, 1, 1, glass.st.dark ? 0.07 : 0.22) }
            GradientStop { position: 0.35; color: Qt.rgba(1, 1, 1, 0) }
        }
    }
    // outer hairline + inner lit rim
    Rectangle {
        anchors.fill: parent
        anchors.margins: -1
        radius: glass.r + 1
        color: "transparent"
        border.width: 1
        border.color: glass.st.rimOuter
    }
    Rectangle {
        anchors.fill: parent
        radius: glass.r
        color: "transparent"
        border.width: 1
        border.color: glass.st.rim
    }
}
