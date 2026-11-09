import QtQuick
import QtQuick.Window
import QtQuick.Effects
import "../../plugins/ms-todo-desk/content"

// Renders the real TaskView over an abstract wallpaper with dummy tasks, then
// saves PNGs and quits. Run through scripts/preview/render.sh.
Window {
    id: win
    width: 440
    height: tile.height + 96
    visible: true
    color: "transparent"

    readonly property string out: Qt.application.arguments[Qt.application.arguments.length - 1]
    property string mode: "light"

    // ---------------- dummy service (same surface as service/Main.qml)
    QtObject {
        id: fake
        function iso(off) { const d = new Date(2026, 2, 12 + off); return Qt.formatDate(d, "yyyy-MM-dd"); }
        property string phase: "ready"
        property string today: iso(0)
        property bool refreshing: false
        property bool stale: false
        property string error: ""
        property string account: "you@example.com"
        property string fetchedAt: new Date().toISOString()
        property string loginCode: ""
        property string loginUrl: ""
        property bool loggingIn: false
        property var pending: ({})
        property string lastListId: ""
        function addTask() {}
        property var lists: [
            { id: "a", name: "My Actions", tasks: [
                { id: "1", title: "Draft the Q2 budget review", due: iso(0), importance: "high", done: false },
                { id: "2", title: "Book flights for the team offsite", due: iso(-1), importance: "normal", done: false },
                { id: "3", title: "Send onboarding pack to the new hire", due: iso(1), reminder: iso(1) + "T09:30", importance: "normal", done: false },
                { id: "4", title: "Review pull request #128", due: "", importance: "normal", done: false },
                { id: "5", title: "Renew the domain certificates", due: iso(9), importance: "normal", done: false },
                { id: "6", title: "Call the plumber", due: "", importance: "normal", done: true } ] },
            { id: "b", name: "Waiting On", tasks: [
                { id: "7", title: "Contract sign-off from Legal", due: iso(3), importance: "normal", done: false },
                { id: "8", title: "Venue quote for the offsite", due: "", importance: "normal", done: false } ] }
        ]
        readonly property var visibleLists: lists
        readonly property int openCount: 7
        readonly property int dueCount: 2
        function refresh() {}
        function openWeb() {}
        function signOut() {}
        function toggle() {}
    }

    // ---------------- abstract wallpaper
    Item {
        id: wallpaper
        anchors.fill: parent
        Rectangle {
            anchors.fill: parent
            gradient: Gradient {
                orientation: Gradient.Vertical
                GradientStop { position: 0.0; color: "#5aa9f0" }
                GradientStop { position: 0.55; color: "#7fd0e6" }
                GradientStop { position: 1.0; color: "#1f8fb3" }
            }
        }
    }

    Style {
        id: style
        appearance: win.mode
        accentKey: "blue"
        fontKey: "inter"
        tintLevel: win.mode === "dark" ? 60 : 46
        blurLevel: 100
    }

    // ---------------- the tile: glass + the real TaskView
    Item {
        id: tile
        x: 40; y: 48
        width: 360
        height: view.implicitHeight
        readonly property real r: style.radius

        RectangularShadow {
            anchors.fill: parent; radius: tile.r
            offset.y: 12; blur: 40; spread: -4; color: style.shadow
        }
        ShaderEffectSource {
            id: under
            sourceItem: wallpaper
            sourceRect: Qt.rect(tile.x, tile.y, tile.width, tile.height)
            anchors.fill: parent
            visible: false
        }
        Rectangle { id: mask; anchors.fill: parent; radius: tile.r; visible: false; layer.enabled: true }
        MultiEffect {
            anchors.fill: parent
            source: under
            autoPaddingEnabled: false
            blurEnabled: true; blur: 1; blurMax: 64; blurMultiplier: 0.6
            saturation: 0.35
            brightness: style.dark ? -0.06 : 0.04
            maskEnabled: true; maskSource: mask
        }
        Rectangle { anchors.fill: parent; radius: tile.r; color: style.tint }
        Rectangle {
            anchors.fill: parent; radius: tile.r
            gradient: Gradient {
                GradientStop { position: 0.0; color: Qt.rgba(1, 1, 1, style.dark ? 0.07 : 0.22) }
                GradientStop { position: 0.35; color: Qt.rgba(1, 1, 1, 0) }
            }
        }
        Rectangle { anchors.fill: parent; anchors.margins: -1; radius: tile.r + 1; color: "transparent"; border.width: 1; border.color: style.rimOuter }
        Rectangle { anchors.fill: parent; radius: tile.r; color: "transparent"; border.width: 1; border.color: style.rim }

        TaskView { id: view; width: tile.width; service: fake; st: style; s: 1 }
    }

    // ---------------- capture both appearances, then quit
    Timer {
        id: shoot
        interval: 700; running: true
        onTriggered: { win.contentItem.grabToImage(r => {
            r.saveToFile(win.out + "/preview-widget" + (view.composing ? "-add" : win.mode === "dark" ? "-dark" : "") + ".png");
            if (win.mode === "light") { win.mode = "dark"; shoot.restart(); }
            else if (!view.composing) { win.mode = "light"; view.compose(); shoot.restart(); }
            else Qt.quit();
        }) }
    }
}
