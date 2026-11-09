pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

// service/Main.qml: the plugin's logic, no UI. Every view reads this one
// instance through pluginApi.mainInstance.
//
// All Microsoft traffic goes through the `mstodo` command (see README), run
// with fixed argv arrays (R9). It owns the sign-in and the token; this file
// never sees a credential. State machine (`phase`):
//   loading -> setup   (mstodo missing or not configured)
//           -> signin  (configured, no token; signIn() runs the device flow)
//           -> ready   (lists loaded; `error` may still carry a soft failure)
Item {
    id: svc

    property var pluginApi
    readonly property var settings: pluginApi ? pluginApi.pluginSettings : null

    // ---------------------------------------------------------- settings
    readonly property string listFilter: settings && settings.lists !== undefined ? String(settings.lists) : ""
    readonly property int refreshMinutes: settings && settings.refreshMinutes ? settings.refreshMinutes : 5
    readonly property string badgeMode: settings && settings.badge ? settings.badge : "open"
    readonly property bool showCompleted: settings && settings.showCompleted !== undefined ? !!settings.showCompleted : false
    readonly property bool hideEmpty: settings && settings.hideEmptyLists !== undefined ? !!settings.hideEmptyLists : true
    // Entra app registration. Set in the plugin settings (Ryoku Settings >
    // Add-ons), they reach mstodo as environment overrides; blank falls back
    // to mstodo's own config file (`mstodo setup`).
    readonly property string clientId: settings && settings.clientId ? String(settings.clientId).trim() : ""
    readonly property string tenant: settings && settings.tenant ? String(settings.tenant).trim() : ""
    readonly property var mstodoEnv: {
        const e = {};
        if (clientId) e.MSTODO_CLIENT_ID = clientId;
        if (tenant) e.MSTODO_TENANT = tenant;
        return e;
    }
    readonly property string mstodo: {
        const p = settings && settings.mstodoPath ? String(settings.mstodoPath).trim() : "";
        return p.length > 0 ? p : (Quickshell.env("HOME") + "/.local/bin/mstodo");
    }

    // ---------------------------------------------------------- state
    property string phase: "loading"
    property string error: ""
    property string account: ""
    property var lists: []          // [{id, name, default, tasks:[{id,title,due,importance,done}]}]
    property string fetchedAt: ""
    property bool stale: false
    property bool refreshing: false
    property var pending: ({})      // taskId -> true while a tick is in flight
    property string lastListId: ""  // the list the composer used last (this session)
    property int _tmp: 0

    // device-code sign-in
    property string loginCode: ""
    property string loginUrl: ""
    property bool loggingIn: false

    readonly property string today: Qt.formatDate(clock.date, "yyyy-MM-dd")
    readonly property var visibleLists: svc.lists.filter(l => !svc.hideEmpty || l.tasks.length > 0)
    readonly property int openCount: svc.count(t => !t.done)
    readonly property int dueCount: svc.count(t => !t.done && t.due && t.due <= svc.today)
    readonly property int highCount: svc.count(t => !t.done && t.importance === "high")
    readonly property int badge: svc.badgeMode === "due" ? svc.dueCount
        : svc.badgeMode === "high" ? svc.highCount
        : svc.badgeMode === "none" ? -1 : svc.openCount

    function count(pred) {
        let n = 0;
        for (const l of svc.lists)
            for (const t of l.tasks)
                if (pred(t)) n++;
        return n;
    }

    // ---------------------------------------------------------- actions
    function refresh() {
        if (svc.loggingIn) return;
        if (svc.phase !== "ready") {
            statusProc.running = false;
            statusProc.running = true;
            return;
        }
        svc.fetchTasks();
    }

    function fetchTasks() {
        const cmd = [svc.mstodo, "tasks"];
        if (svc.listFilter.trim().length > 0) cmd.push("--lists", svc.listFilter);
        if (svc.showCompleted) cmd.push("--completed");
        tasksProc.command = cmd;
        svc.refreshing = true;
        tasksProc.running = false;
        tasksProc.running = true;
    }

    function signIn() {
        svc.error = "";
        svc.loginCode = "";
        svc.loginUrl = "";
        svc.loggingIn = true;
        loginProc.running = false;
        loginProc.running = true;
    }

    function cancelSignIn() {
        loginProc.running = false;
        svc.loggingIn = false;
        svc.loginCode = "";
    }

    function signOut() {
        actions.enqueue([svc.mstodo, "logout"], "");
    }

    function openUrl(url) { Quickshell.execDetached(["xdg-open", url]); }
    function openWeb() { svc.openUrl("https://to-do.office.com/tasks/"); }
    function copyCode() { if (svc.loginCode) Quickshell.execDetached(["wl-copy", svc.loginCode]); }

    // Tick (or un-tick) a task. Optimistic: flip it locally, then confirm.
    function toggle(listId, taskId) {
        if (svc.pending[taskId]) return;
        let wasDone = false;
        svc.lists = svc.lists.map(l => l.id !== listId ? l : Object.assign({}, l, {
            tasks: l.tasks.map(t => {
                if (t.id !== taskId) return t;
                wasDone = t.done;
                return Object.assign({}, t, { done: !t.done });
            })
        }));
        const p = Object.assign({}, svc.pending); p[taskId] = true; svc.pending = p;
        const cmd = [svc.mstodo, "done", listId, taskId];
        if (wasDone) cmd.push("--undo");
        actions.enqueue(cmd, taskId);
    }

    // Add a task (optionally due on a day, with a reminder "yyyy-MM-ddTHH:mm",
    // marked important). Shows it at once as pending, then syncs.
    function addTask(listId, title, due, remind, high) {
        svc.lastListId = listId;
        const tmpId = "pending-" + (++svc._tmp);
        const row = { id: tmpId, title: title, due: due || "", reminder: remind || "",
                      importance: high ? "high" : "normal", done: false };
        svc.lists = svc.lists.map(l => l.id !== listId ? l
            : Object.assign({}, l, { tasks: [row].concat(l.tasks) }));
        const p = Object.assign({}, svc.pending); p[tmpId] = true; svc.pending = p;
        const cmd = [svc.mstodo, "add", listId, title];
        if (due) cmd.push("--due", due);
        if (remind) cmd.push("--remind", remind);
        if (high) cmd.push("--high");
        actions.enqueue(cmd, tmpId);
    }

    // ---------------------------------------------------------- processes
    Process {
        id: statusProc
        environment: svc.mstodoEnv
        command: [svc.mstodo, "status"]
        stdout: StdioCollector {
            id: statusOut
            onStreamFinished: {
                let s = null;
                try { s = JSON.parse(statusOut.text); } catch (e) { }
                if (!s) {
                    svc.phase = "setup";
                    svc.error = "The mstodo command was not found at " + svc.mstodo;
                    return;
                }
                svc.account = s.account || "";
                svc.error = "";
                if (!s.configured) svc.phase = "setup";
                else if (!s.signedIn) svc.phase = "signin";
                else { svc.phase = "ready"; svc.fetchTasks(); }
            }
        }
    }

    Process {
        id: tasksProc
        environment: svc.mstodoEnv
        stdout: StdioCollector {
            id: tasksOut
            onStreamFinished: {
                svc.refreshing = false;
                let d = null;
                try { d = JSON.parse(tasksOut.text); } catch (e) { }
                if (!d) { svc.error = "Could not read the task list"; return; }
                if (d.error) {
                    svc.error = d.error;
                    if (d.kind === "auth") svc.phase = "signin";
                    if (d.kind === "config") svc.phase = "setup";
                    return;
                }
                svc.error = "";
                svc.lists = d.lists || [];
                svc.fetchedAt = d.fetchedAt || "";
                svc.stale = !!d.stale;
                if (d.account) svc.account = d.account;
                svc.phase = "ready";
            }
        }
    }

    Process {
        id: loginProc
        environment: svc.mstodoEnv
        command: [svc.mstodo, "login"]
        stdout: SplitParser {
            onRead: line => {
                let d = null;
                try { d = JSON.parse(line); } catch (e) { return; }
                if (d.code) {
                    svc.loginCode = d.code;
                    svc.loginUrl = d.url;
                } else if (d.ok) {
                    svc.loggingIn = false;
                    svc.loginCode = "";
                    svc.account = d.account || "";
                    svc.phase = "ready";
                    svc.fetchTasks();
                } else if (d.error) {
                    svc.loggingIn = false;
                    svc.loginCode = "";
                    svc.error = d.error;
                }
            }
        }
        onExited: (code, status) => {
            if (svc.loggingIn) { svc.loggingIn = false; svc.loginCode = ""; }
        }
    }

    // One action at a time (done / undo / logout), then a quiet refresh.
    QtObject {
        id: actions
        property var queue: []
        property var current: null
        function enqueue(cmd, taskId) {
            actions.queue = actions.queue.concat([{ cmd: cmd, taskId: taskId }]);
            actions.next();
        }
        function next() {
            if (actions.current || actions.queue.length === 0) return;
            actions.current = actions.queue[0];
            actions.queue = actions.queue.slice(1);
            actionProc.command = actions.current.cmd;
            actionProc.running = true;
        }
    }

    Process {
        id: actionProc
        environment: svc.mstodoEnv
        stdout: StdioCollector {
            id: actionOut
            onStreamFinished: {
                const job = actions.current;
                let d = null;
                try { d = JSON.parse(actionOut.text); } catch (e) { }
                if (job && job.taskId) {
                    const p = Object.assign({}, svc.pending); delete p[job.taskId]; svc.pending = p;
                }
                actions.current = null;
                if (!d || d.error) {
                    svc.error = d && d.error ? d.error : "The change did not go through";
                    if (d && d.kind === "auth") svc.phase = "signin";
                    else svc.fetchTasks();   // re-sync: drops the optimistic flip
                } else if (job && job.cmd[1] === "logout") {
                    svc.lists = []; svc.account = ""; svc.error = ""; svc.phase = "signin";
                } else if (job && job.cmd[1] === "add") {
                    svc.fetchTasks();   // swap the pending row for the real one
                } else if (actions.queue.length === 0) {
                    settle.restart();
                }
                Qt.callLater(actions.next);
            }
        }
    }

    // Wait a moment after the last tick so a burst of ticks costs one refresh,
    // and a ticked task stays visible (struck through) long enough to undo.
    Timer { id: settle; interval: 4000; onTriggered: if (svc.phase === "ready") svc.fetchTasks() }

    Timer {
        interval: Math.max(1, svc.refreshMinutes) * 60000
        running: true
        repeat: true
        onTriggered: if (svc.phase === "ready" && !svc.refreshing && !actions.current && !settle.running) svc.fetchTasks()
    }

    SystemClock { id: clock; precision: SystemClock.Minutes }

    // React to settings that change what we fetch.
    onListFilterChanged: if (phase === "ready") fetchTasks()
    onShowCompletedChanged: if (phase === "ready") fetchTasks()
    onMstodoChanged: { phase = "loading"; refresh(); }
    onClientIdChanged: { phase = "loading"; refresh(); }
    onTenantChanged: { phase = "loading"; refresh(); }

    Component.onCompleted: refresh()
}
