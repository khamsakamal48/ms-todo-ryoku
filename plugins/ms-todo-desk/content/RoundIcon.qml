import QtQuick

// A circular icon button on a quiet fill, like the + on Apple widgets.
Item {
    id: btn
    property var st
    property string icon: ""
    property real s: 1
    property bool spinning: false
    property bool tinted: false
    signal clicked()

    implicitWidth: 30 * s
    implicitHeight: 30 * s

    Rectangle {
        anchors.fill: parent
        radius: width / 2
        color: btn.tinted ? btn.st.soft(btn.st.accent, area.containsMouse ? 0.22 : 0.14)
                          : (area.containsMouse ? btn.st.fillHover : btn.st.fill)
        Behavior on color { ColorAnimation { duration: 120 } }
    }
    Icon {
        id: g
        anchors.centerIn: parent
        text: btn.icon
        size: 17 * btn.s
        color: btn.tinted || area.containsMouse ? btn.st.accent : btn.st.ink2
        Behavior on color { ColorAnimation { duration: 120 } }
        RotationAnimation on rotation {
            running: btn.spinning
            loops: Animation.Infinite
            from: 0; to: 360; duration: 900
            onStopped: g.rotation = 0
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
