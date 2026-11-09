pragma ComponentBehavior: Bound

import QtQuick

// New task: a title, the list, an optional due day, an optional reminder
// (presets or a day + time of your own), and an Important star.
// Enter adds, Escape cancels. `editing` tells the desktop host to give us
// the keyboard while a field has focus.
Item {
    id: c

    property var st
    property var service
    property real s: 1
    signal closed()

    readonly property bool editing: title.activeFocus || timeField.activeFocus

    // ---- choices
    property string listId: ""
    property string dueKey: "none"         // none | today | tomorrow | week
    property string remindKey: "none"      // none | later | evening | morning | custom
    property string customDay: "today"     // today | tomorrow | due
    property bool high: false
    property string error: ""

    readonly property var lists: service ? service.lists : []
    readonly property date now: new Date()

    function ymd(d) { return Qt.formatDate(d, "yyyy-MM-dd"); }
    function plusDays(n) { const d = new Date(); d.setHours(0, 0, 0, 0); d.setDate(d.getDate() + n); return d; }
    function dueDate() {
        return dueKey === "today" ? ymd(plusDays(0)) : dueKey === "tomorrow" ? ymd(plusDays(1))
             : dueKey === "week" ? ymd(plusDays(7)) : "";
    }
    // later today = now + 3h, rounded up to the hour
    function laterToday() { const d = new Date(); d.setMinutes(0, 0, 0); d.setHours(d.getHours() + 3); return d; }
    readonly property bool laterFits: { const d = laterToday(); return d.getDate() === new Date().getDate(); }
    readonly property bool eveningFits: new Date().getHours() < 17
    function remindAt() {
        if (remindKey === "later") return Qt.formatDateTime(laterToday(), "yyyy-MM-ddTHH:mm");
        if (remindKey === "evening") return ymd(plusDays(0)) + "T18:00";
        if (remindKey === "morning") return ymd(plusDays(1)) + "T09:00";
        if (remindKey === "custom") {
            const t = timeField.text.trim();
            if (!/^([01]?\d|2[0-3]):[0-5]\d$/.test(t)) return "invalid";
            const hm = t.length === 4 ? "0" + t : t;
            const day = customDay === "tomorrow" ? ymd(plusDays(1))
                      : customDay === "due" && dueDate() ? dueDate() : ymd(plusDays(0));
            return day + "T" + hm;
        }
        return "";
    }

    function open() {
        if (!listId || !lists.some(l => l.id === listId)) {
            const remembered = service && service.lastListId;
            const pick = lists.find(l => l.id === remembered) || (service && service.visibleLists[0]) || lists[0];
            listId = pick ? pick.id : "";
        }
        title.text = ""; dueKey = "none"; remindKey = "none"; customDay = "today";
        timeField.text = "09:00"; high = false; error = "";
        title.forceActiveFocus();
    }
    function submit() {
        const t = title.text.trim();
        if (!t) { error = "Give the task a title"; title.forceActiveFocus(); return; }
        if (!listId) { error = "Pick a list"; return; }
        const r = remindAt();
        if (r === "invalid") { error = "Reminder time must look like 14:30"; timeField.forceActiveFocus(); return; }
        if (r && new Date(r) < new Date()) { error = "That reminder time has already passed"; return; }
        service.addTask(listId, t, dueDate(), r, high);
        c.closed();
    }

    implicitHeight: col.implicitHeight + 28 * s

    Rectangle {
        anchors.fill: parent
        radius: 16 * c.s
        color: c.st.fill
        border.width: 1
        border.color: c.st.hairline
    }

    Column {
        id: col
        x: 14 * c.s
        y: 14 * c.s
        width: parent.width - 28 * c.s
        spacing: 12 * c.s

        // title + star
        Item {
            width: parent.width
            height: 36 * c.s
            Rectangle {
                anchors.fill: parent
                radius: 10 * c.s
                color: c.st.dark ? Qt.rgba(1, 1, 1, 0.07) : Qt.rgba(1, 1, 1, 0.65)
                border.width: 1
                border.color: title.activeFocus ? c.st.soft(c.st.accent, 0.6) : c.st.hairline
            }
            TextInput {
                id: title
                anchors.left: parent.left
                anchors.leftMargin: 12 * c.s
                anchors.right: star.left
                anchors.rightMargin: 6 * c.s
                anchors.verticalCenter: parent.verticalCenter
                color: c.st.ink
                selectionColor: c.st.accent
                selectedTextColor: c.st.accentInk
                font.family: c.st.font
                font.pixelSize: 14 * c.s
                clip: true
                Keys.onReturnPressed: c.submit()
                Keys.onEnterPressed: c.submit()
                Keys.onEscapePressed: c.closed()
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    visible: title.text.length === 0
                    text: "New task"
                    color: c.st.ink3
                    font: title.font
                }
            }
            Item {
                id: star
                anchors.right: parent.right
                anchors.rightMargin: 6 * c.s
                anchors.verticalCenter: parent.verticalCenter
                width: 26 * c.s; height: width
                Icon {
                    anchors.centerIn: parent
                    text: "star"
                    filled: c.high
                    size: 18 * c.s
                    color: c.high ? c.st.dangerText : c.st.ink3
                }
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: c.high = !c.high
                }
            }
        }

        // list
        Column {
            width: parent.width
            spacing: 6 * c.s
            visible: c.lists.length > 1
            Text { text: "List"; color: c.st.ink2; font.family: c.st.font; font.pixelSize: 11.5 * c.s; font.weight: Font.DemiBold }
            Flow {
                width: parent.width
                spacing: 6 * c.s
                Repeater {
                    model: c.lists
                    delegate: Chip {
                        required property var modelData
                        st: c.st; s: c.s
                        label: modelData.name
                        selected: c.listId === modelData.id
                        onClicked: c.listId = modelData.id
                    }
                }
            }
        }

        // due
        Column {
            width: parent.width
            spacing: 6 * c.s
            Text { text: "Due"; color: c.st.ink2; font.family: c.st.font; font.pixelSize: 11.5 * c.s; font.weight: Font.DemiBold }
            Flow {
                width: parent.width
                spacing: 6 * c.s
                Chip { st: c.st; s: c.s; label: "None"; selected: c.dueKey === "none"; onClicked: c.dueKey = "none" }
                Chip { st: c.st; s: c.s; label: "Today"; icon: "today"; selected: c.dueKey === "today"; onClicked: c.dueKey = "today" }
                Chip { st: c.st; s: c.s; label: "Tomorrow"; selected: c.dueKey === "tomorrow"; onClicked: c.dueKey = "tomorrow" }
                Chip { st: c.st; s: c.s; label: "Next week"; selected: c.dueKey === "week"; onClicked: c.dueKey = "week" }
            }
        }

        // reminder
        Column {
            width: parent.width
            spacing: 6 * c.s
            Text { text: "Remind me"; color: c.st.ink2; font.family: c.st.font; font.pixelSize: 11.5 * c.s; font.weight: Font.DemiBold }
            Flow {
                width: parent.width
                spacing: 6 * c.s
                Chip { st: c.st; s: c.s; label: "No"; selected: c.remindKey === "none"; onClicked: c.remindKey = "none" }
                Chip {
                    st: c.st; s: c.s; visible: c.laterFits
                    label: "Later · " + Qt.formatTime(c.laterToday(), "HH:mm")
                    icon: "schedule"
                    selected: c.remindKey === "later"; onClicked: c.remindKey = "later"
                }
                Chip {
                    st: c.st; s: c.s; visible: c.eveningFits
                    label: "This evening"; selected: c.remindKey === "evening"; onClicked: c.remindKey = "evening"
                }
                Chip { st: c.st; s: c.s; label: "Tomorrow 9:00"; selected: c.remindKey === "morning"; onClicked: c.remindKey = "morning" }
                Chip {
                    st: c.st; s: c.s; label: "Pick…"; icon: "edit_calendar"
                    selected: c.remindKey === "custom"
                    onClicked: { c.remindKey = "custom"; timeField.forceActiveFocus(); timeField.selectAll(); }
                }
            }
            // custom day + time
            Row {
                visible: c.remindKey === "custom"
                spacing: 6 * c.s
                Chip { st: c.st; s: c.s; label: "Today"; selected: c.customDay === "today"; onClicked: c.customDay = "today" }
                Chip { st: c.st; s: c.s; label: "Tomorrow"; selected: c.customDay === "tomorrow"; onClicked: c.customDay = "tomorrow" }
                Chip {
                    st: c.st; s: c.s; visible: c.dueKey === "week"
                    label: "Due day"; selected: c.customDay === "due"; onClicked: c.customDay = "due"
                }
                Item {
                    width: 70 * c.s; height: 28 * c.s
                    Rectangle {
                        anchors.fill: parent
                        radius: height / 2
                        color: c.st.dark ? Qt.rgba(1, 1, 1, 0.07) : Qt.rgba(1, 1, 1, 0.65)
                        border.width: 1
                        border.color: timeField.activeFocus ? c.st.soft(c.st.accent, 0.6) : c.st.hairline
                    }
                    Icon {
                        x: 8 * c.s
                        anchors.verticalCenter: parent.verticalCenter
                        text: "alarm"
                        size: 13 * c.s
                        color: c.st.ink3
                    }
                    TextInput {
                        id: timeField
                        anchors.right: parent.right
                        anchors.rightMargin: 10 * c.s
                        anchors.verticalCenter: parent.verticalCenter
                        text: "09:00"
                        maximumLength: 5
                        color: c.st.ink
                        selectionColor: c.st.accent
                        selectedTextColor: c.st.accentInk
                        font.family: c.st.font
                        font.pixelSize: 12.5 * c.s
                        font.weight: Font.DemiBold
                        inputMethodHints: Qt.ImhTime
                        Keys.onReturnPressed: c.submit()
                        Keys.onEnterPressed: c.submit()
                        Keys.onEscapePressed: c.closed()
                    }
                }
            }
        }

        Text {
            visible: c.error.length > 0
            width: parent.width
            text: c.error
            color: c.st.dangerText
            font.family: c.st.font
            font.pixelSize: 12 * c.s
            wrapMode: Text.WordWrap
        }

        Row {
            anchors.right: parent.right
            spacing: 8 * c.s
            Pill { st: c.st; s: c.s; label: "Cancel"; onClicked: c.closed() }
            Pill { st: c.st; s: c.s; primary: true; label: "Add"; icon: "add"; onClicked: c.submit() }
        }
    }
}
