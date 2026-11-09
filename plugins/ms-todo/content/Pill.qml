import QtQuick

// A capsule button. `primary` fills it with the accent.
Item {
    id: btn
    property var st
    property string label: ""
    property string icon: ""
    property real s: 1
    property bool primary: false
    signal clicked()

    implicitWidth: row.implicitWidth + 28 * s
    implicitHeight: 34 * s

    Rectangle {
        anchors.fill: parent
        radius: height / 2
        color: btn.primary
            ? (area.pressed ? Qt.darker(btn.st.accent, 1.15) : area.containsMouse ? Qt.lighter(btn.st.accent, 1.08) : btn.st.accent)
            : (area.containsMouse ? btn.st.fillHover : btn.st.fill)
        Behavior on color { ColorAnimation { duration: 120 } }
    }
    Row {
        id: row
        anchors.centerIn: parent
        spacing: 6 * btn.s
        Icon {
            visible: btn.icon !== ""
            anchors.verticalCenter: parent.verticalCenter
            text: btn.icon
            size: 16 * btn.s
            color: btn.primary ? btn.st.accentInk : btn.st.ink
        }
        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: btn.label
            color: btn.primary ? btn.st.accentInk : btn.st.ink
            font.family: btn.st.font
            font.pixelSize: 13 * btn.s
            font.weight: Font.DemiBold
        }
    }
    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: btn.clicked()
    }
}
