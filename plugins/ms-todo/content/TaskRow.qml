import QtQuick

// One task: a round checkbox, the title, and a due-date capsule. Clicking the
// row ticks the task off in Microsoft To Do; clicking a ticked one reopens it.
Item {
    id: row

    property var st
    property var task: ({})
    property real s: 1
    property bool busy: false
    property string dueText: ""
    property bool overdue: false
    property bool dueToday: false
    signal toggled()

    readonly property bool done: !!task.done
    readonly property bool high: task.importance === "high"
    implicitHeight: Math.max(22 * s, label.implicitHeight) + 14 * s

    // hover wash
    Rectangle {
        anchors.fill: parent
        anchors.leftMargin: -8 * row.s
        anchors.rightMargin: -8 * row.s
        radius: row.st.rowRadius * row.s
        color: hit.containsMouse ? row.st.fill : "transparent"
        Behavior on color { ColorAnimation { duration: 120 } }
    }

    // round checkbox
    Item {
        id: box
        anchors.verticalCenter: parent.verticalCenter
        width: 20 * row.s
        height: width
        opacity: row.busy ? 0.55 : 1

        Rectangle {
            anchors.fill: parent
            radius: width / 2
            color: row.done ? row.st.accent : "transparent"
            border.width: row.done ? 0 : Math.max(1.5, 1.7 * row.s)
            border.color: hit.containsMouse ? row.st.accent : (row.high ? row.st.danger : row.st.ring)
            Behavior on color { ColorAnimation { duration: 160 } }
            Behavior on border.color { ColorAnimation { duration: 120 } }
        }
        Icon {
            anchors.centerIn: parent
            text: "check"
            size: 15 * row.s
            color: row.st.accentInk
            scale: row.done ? 1 : 0.4
            opacity: row.done ? 1 : 0
            Behavior on scale { NumberAnimation { duration: 220; easing.type: Easing.OutBack } }
            Behavior on opacity { NumberAnimation { duration: 120 } }
        }
    }

    Text {
        id: label
        anchors.left: box.right
        anchors.leftMargin: 12 * row.s
        anchors.right: chip.visible ? chip.left : parent.right
        anchors.rightMargin: chip.visible ? 10 * row.s : 0
        anchors.verticalCenter: parent.verticalCenter
        text: row.task.title || ""
        color: row.done ? row.st.ink3 : row.st.ink
        font.family: row.st.font
        font.pixelSize: 14 * row.s
        font.strikeout: row.done
        wrapMode: Text.WordWrap
        maximumLineCount: 2
        elide: Text.ElideRight
        lineHeight: 1.08
        Behavior on color { ColorAnimation { duration: 160 } }
    }

    // due capsule
    Rectangle {
        id: chip
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        visible: row.dueText.length > 0 && !row.done
        height: 20 * row.s
        width: chipText.implicitWidth + 16 * row.s
        radius: height / 2
        color: row.overdue ? row.st.soft(row.st.danger, 0.14)
             : row.dueToday ? row.st.soft(row.st.accent, 0.14) : row.st.fill
        Text {
            id: chipText
            anchors.centerIn: parent
            text: row.dueText
            color: row.overdue ? row.st.danger : row.dueToday ? row.st.accent : row.st.ink2
            font.family: row.st.font
            font.pixelSize: 11 * row.s
            font.weight: Font.DemiBold
        }
    }

    MouseArea {
        id: hit
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        enabled: !row.busy
        onClicked: row.toggled()
    }
}
