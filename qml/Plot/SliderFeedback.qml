import QtQuick 2.9

// Visual feedback only: the existing MouseArea owns the drag interaction.
Item {
    id: feedback
    anchors.fill: parent
    property var control
    property color tint
    property bool dragging: parent.pressed
    readonly property real fraction: control.to > control.from
        ? Math.max(0, Math.min(1, (control.value - control.from) / (control.to - control.from))) : 0

    Rectangle {
        anchors.fill: parent
        color: feedback.tint
        opacity: feedback.dragging ? 0.18 : 0
        border.color: feedback.tint
        border.width: 1
    }

    Rectangle {
        anchors.left: parent.left
        anchors.bottom: parent.bottom
        width: parent.width * feedback.fraction
        height: 3
        color: feedback.tint
        visible: feedback.dragging || feedback.parent.containsMouse
    }

    Rectangle {
        x: Math.max(0, Math.min(parent.width - width, parent.width * feedback.fraction - width / 2))
        anchors.bottom: parent.bottom
        width: 3
        height: 8
        radius: 1
        color: feedback.tint
        visible: feedback.dragging
    }

}
