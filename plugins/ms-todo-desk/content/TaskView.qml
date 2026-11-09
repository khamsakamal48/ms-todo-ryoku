pragma ComponentBehavior: Bound

import QtQuick

// The one task view, shared by the bar panel and the desktop tile. It reads
// the service, calls its actions, and paints with the Style it is given.
Item {
    id: view

    property var service: null
    property var st                     // Style
    property real s: 1
    property real maxBodyHeight: 420 * s
    property real pad: 20 * s

    readonly property string phase: service ? service.phase : "loading"
    readonly property int open: service ? service.openCount : 0
    readonly property int due: service ? service.dueCount : 0

    implicitWidth: 340 * s
    implicitHeight: col.implicitHeight + 2 * pad

    function dueLabel(d) {
        if (!d || !service) return "";
        const today = service.today;
        if (d < today) return "Overdue";
        if (d === today) return "Today";
        const a = new Date(d + "T00:00:00"), b = new Date(today + "T00:00:00");
        const days = Math.round((a - b) / 86400000);
        if (days === 1) return "Tomorrow";
        if (days < 7) return Qt.formatDate(a, "dddd");
        return Qt.formatDate(a, "d MMM");
    }
    function agoLabel(iso) {
        if (!iso) return "";
        const mins = Math.round((Date.now() - new Date(iso).getTime()) / 60000);
        if (mins < 1) return "Updated just now";
        if (mins < 60) return "Updated " + mins + " min ago";
        return "Updated " + Math.round(mins / 60) + " h ago";
    }
    function summary() {
        if (view.open === 0) return "Nothing open";
        let t = view.open + (view.open === 1 ? " task" : " tasks");
        if (view.due > 0) t += " · " + view.due + " due";
        return t;
    }

    Column {
        id: col
        x: view.pad
        y: view.pad
        width: view.width - 2 * view.pad
        spacing: 14 * view.s

        // ------------------------------------------------ header
        Item {
            width: parent.width
            height: Math.max(head.implicitHeight, figure.implicitHeight)

            Column {
                id: head
                anchors.verticalCenter: parent.verticalCenter
                spacing: 3 * view.s
                Row {
                    spacing: 7 * view.s
                    Icon {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "checklist"
                        size: 20 * view.s
                        color: view.st.accentText
                    }
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "To Do"
                        color: view.st.ink
                        font.family: view.st.display
                        font.pixelSize: 17 * view.s
                        font.weight: Font.DemiBold
                    }
                }
                Text {
                    visible: view.phase === "ready"
                    text: view.summary()
                    color: view.st.ink2
                    font.family: view.st.font
                    font.pixelSize: 12.5 * view.s
                }
            }
            Text {
                id: figure
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                visible: view.phase === "ready"
                text: view.open
                color: view.st.accentText
                font.family: view.st.display
                font.pixelSize: 40 * view.s
                font.weight: Font.DemiBold
                font.letterSpacing: -1 * view.s
            }
        }

        // ------------------------------------------------ soft error / offline
        Rectangle {
            width: parent.width
            visible: view.phase === "ready" && view.service
                && (view.service.error.length > 0 || view.service.stale)
            height: warn.implicitHeight + 14 * view.s
            radius: 10 * view.s
            color: view.st.soft(view.st.danger, 0.12)
            Text {
                id: warn
                x: 12 * view.s
                width: parent.width - 24 * view.s
                anchors.verticalCenter: parent.verticalCenter
                text: view.service
                    ? (view.service.stale ? "Offline · showing your last synced tasks" : view.service.error)
                    : ""
                color: view.st.danger
                font.family: view.st.font
                font.pixelSize: 12 * view.s
                wrapMode: Text.WordWrap
                maximumLineCount: 3
                elide: Text.ElideRight
            }
        }

        // ------------------------------------------------ setup
        Column {
            width: parent.width
            spacing: 10 * view.s
            visible: view.phase === "setup"
            Text {
                width: parent.width
                text: view.service && view.service.error ? view.service.error : "Connect an app registration"
                color: view.st.ink
                font.family: view.st.font
                font.pixelSize: 14 * view.s
                font.weight: Font.Medium
                wrapMode: Text.WordWrap
            }
            Text {
                width: parent.width
                text: "Microsoft only lets registered apps sign in. Paste your Entra app's "
                    + "Application (client) ID and Directory (tenant) ID in Ryoku Settings › "
                    + "Add-ons › Microsoft To Do, then Try again. The README explains the "
                    + "two-minute registration."
                color: view.st.ink2
                font.family: view.st.font
                font.pixelSize: 12.5 * view.s
                wrapMode: Text.WordWrap
                lineHeight: 1.15
            }
            Rectangle {
                width: parent.width
                height: cmd.implicitHeight + 16 * view.s
                radius: 10 * view.s
                color: view.st.fill
                Text {
                    id: cmd
                    x: 12 * view.s
                    width: parent.width - 24 * view.s
                    anchors.verticalCenter: parent.verticalCenter
                    text: "or in a terminal:  mstodo setup --client-id <id> --tenant <id>"
                    color: view.st.ink2
                    font.family: view.st.mono
                    font.pixelSize: 11 * view.s
                    wrapMode: Text.WrapAnywhere
                }
            }
            Pill { st: view.st; s: view.s; label: "Try again"; icon: "refresh"; onClicked: view.service.refresh() }
        }

        // ------------------------------------------------ sign in
        Column {
            width: parent.width
            spacing: 12 * view.s
            visible: view.phase === "signin"

            Text {
                width: parent.width
                text: view.service && view.service.loginCode
                    ? "Enter this code on the Microsoft page"
                    : "Connect your Microsoft account to see your tasks here."
                color: view.st.ink
                font.family: view.st.font
                font.pixelSize: 14 * view.s
                font.weight: Font.Medium
                wrapMode: Text.WordWrap
            }
            Rectangle {
                visible: !!(view.service && view.service.loginCode)
                width: parent.width
                height: 54 * view.s
                radius: 14 * view.s
                color: view.st.fill
                Text {
                    anchors.centerIn: parent
                    text: view.service ? view.service.loginCode : ""
                    color: view.st.accent
                    font.family: view.st.mono
                    font.pixelSize: 24 * view.s
                    font.weight: Font.Bold
                    font.letterSpacing: 4 * view.s
                }
            }
            Text {
                width: parent.width
                visible: !!(view.service && view.service.error) && !(view.service && view.service.loginCode)
                text: view.service ? view.service.error : ""
                color: view.st.danger
                font.family: view.st.font
                font.pixelSize: 12 * view.s
                wrapMode: Text.WordWrap
            }
            Flow {
                width: parent.width
                spacing: 8 * view.s
                Pill {
                    st: view.st; s: view.s; primary: true
                    visible: !(view.service && view.service.loggingIn)
                    label: "Sign in"; icon: "login"
                    onClicked: view.service.signIn()
                }
                Pill {
                    st: view.st; s: view.s; primary: true
                    visible: !!(view.service && view.service.loginCode)
                    label: "Open page"; icon: "open_in_new"
                    onClicked: { view.service.copyCode(); view.service.openUrl(view.service.loginUrl); }
                }
                Pill {
                    st: view.st; s: view.s
                    visible: !!(view.service && view.service.loginCode)
                    label: "Copy code"; icon: "content_copy"
                    onClicked: view.service.copyCode()
                }
                Pill {
                    st: view.st; s: view.s
                    visible: !!(view.service && view.service.loggingIn)
                    label: "Cancel"
                    onClicked: view.service.cancelSignIn()
                }
            }
            Text {
                visible: !!(view.service && view.service.loggingIn && !view.service.loginCode)
                text: "Starting sign-in…"
                color: view.st.ink3
                font.family: view.st.font
                font.pixelSize: 12 * view.s
            }
        }

        // ------------------------------------------------ loading
        Text {
            visible: view.phase === "loading"
            text: "Loading…"
            color: view.st.ink3
            font.family: view.st.font
            font.pixelSize: 13 * view.s
        }

        // ------------------------------------------------ tasks
        Flickable {
            id: flick
            visible: view.phase === "ready"
            width: parent.width
            height: Math.min(lists.implicitHeight, view.maxBodyHeight)
            contentHeight: lists.implicitHeight
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            interactive: contentHeight > height

            Column {
                id: lists
                width: flick.width
                spacing: 16 * view.s

                // empty state
                Column {
                    visible: view.service && view.service.visibleLists.length === 0 && !view.service.refreshing
                    width: parent.width
                    spacing: 6 * view.s
                    topPadding: 8 * view.s
                    bottomPadding: 8 * view.s
                    Icon {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: "task_alt"
                        size: 34 * view.s
                        color: view.st.accentText
                    }
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: "All done"
                        color: view.st.ink2
                        font.family: view.st.font
                        font.pixelSize: 13 * view.s
                        font.weight: Font.Medium
                    }
                }

                Repeater {
                    model: view.service ? view.service.visibleLists : []

                    delegate: Column {
                        id: section
                        required property var modelData
                        required property int index
                        width: lists.width
                        spacing: 0

                        Rectangle {
                            visible: section.index > 0
                            width: parent.width
                            height: 1
                            color: view.st.hairline
                        }
                        Item {
                            width: parent.width
                            height: listName.implicitHeight + (section.index > 0 ? 14 : 2) * view.s
                            Text {
                                id: listName
                                anchors.bottom: parent.bottom
                                text: section.modelData.name
                                color: view.st.ink2
                                font.family: view.st.font
                                font.pixelSize: 12 * view.s
                                font.weight: Font.DemiBold
                            }
                            Text {
                                anchors.right: parent.right
                                anchors.baseline: listName.baseline
                                text: section.modelData.tasks.filter(t => !t.done).length
                                color: view.st.ink3
                                font.family: view.st.font
                                font.pixelSize: 12 * view.s
                                font.weight: Font.Medium
                            }
                        }
                        Item { width: 1; height: 4 * view.s }
                        Text {
                            visible: section.modelData.tasks.length === 0
                            text: "Nothing here"
                            color: view.st.ink3
                            font.family: view.st.font
                            font.pixelSize: 13 * view.s
                            topPadding: 4 * view.s
                        }
                        Repeater {
                            model: section.modelData.tasks
                            delegate: TaskRow {
                                required property var modelData
                                width: section.width
                                st: view.st
                                s: view.s
                                task: modelData
                                busy: !!(view.service && view.service.pending[modelData.id])
                                dueText: view.dueLabel(modelData.due)
                                overdue: !!modelData.due && !!view.service && modelData.due < view.service.today
                                dueToday: !!modelData.due && !!view.service && modelData.due === view.service.today
                                onToggled: view.service.toggle(section.modelData.id, modelData.id)
                            }
                        }
                    }
                }
            }
        }

        // ------------------------------------------------ footer
        Item {
            visible: view.phase === "ready"
            width: parent.width
            height: 30 * view.s

            Text {
                anchors.left: parent.left
                anchors.right: actionsRow.left
                anchors.rightMargin: 8 * view.s
                anchors.verticalCenter: parent.verticalCenter
                text: signOutBtn.armed ? "Click again to sign out"
                    : (view.service ? view.agoLabel(view.service.fetchedAt) : "")
                color: view.st.ink3
                font.family: view.st.font
                font.pixelSize: 11.5 * view.s
                elide: Text.ElideRight
            }
            Row {
                id: actionsRow
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                spacing: 8 * view.s
                RoundIcon {
                    st: view.st; s: view.s; icon: "refresh"
                    spinning: view.service ? view.service.refreshing : false
                    onClicked: view.service.refresh()
                }
                RoundIcon {
                    st: view.st; s: view.s; icon: "open_in_new"
                    onClicked: view.service.openWeb()
                }
                // two clicks within 3 s: the first arms it (tinted), the second signs out
                RoundIcon {
                    id: signOutBtn
                    property bool armed: false
                    st: view.st; s: view.s; icon: "logout"
                    tinted: armed
                    onClicked: {
                        if (armed) { armed = false; view.service.signOut(); }
                        else { armed = true; disarm.restart(); }
                    }
                    Timer { id: disarm; interval: 3000; onTriggered: signOutBtn.armed = false }
                }
            }
        }
    }
}
