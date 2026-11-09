import QtQuick

// A small selectable capsule (list, due, reminder presets).
Item {
    id: chip
    property var st
    property real s: 1
    property string label: ""
    property string icon: ""
    property bool selected: false
    signal clicked()

    implicitWidth: row.implicitWidth + 20 * s
    implicitHeight: 28 * s

    Rectangle {
        anchors.fill: parent
        radius: height / 2
        color: chip.selected ? chip.st.soft(chip.st.accent, chip.st.dark ? 0.30 : 0.16)
             : (area.containsMouse ? chip.st.fillHover : chip.st.fill)
        border.width: chip.selected ? 1 : 0
        border.color: chip.st.soft(chip.st.accent, 0.45)
        Behavior on color { ColorAnimation { duration: 120 } }
    }
    Row {
        id: row
        anchors.centerIn: parent
        spacing: 4 * chip.s
        Icon {
            visible: chip.icon !== ""
            anchors.verticalCenter: parent.verticalCenter
            text: chip.icon
            size: 14 * chip.s
            color: chip.selected ? chip.st.accentText : chip.st.ink2
        }
        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: chip.label
            color: chip.selected ? chip.st.accentText : chip.st.ink
            font.family: chip.st.font
            font.pixelSize: 12 * chip.s
            font.weight: chip.selected ? Font.DemiBold : Font.Medium
        }
    }
    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: chip.clicked()
    }
}
