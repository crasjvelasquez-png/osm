import QtQuick 2.15
import QtQuick.Controls 2.15

TextField {
    id: control
    implicitHeight: applicationWindow.ui.controlHeight
    font.family: applicationWindow.ui.fontFamily
    font.pixelSize: applicationWindow.ui.controlFontSize
    color: enabled ? applicationWindow.ui.text : applicationWindow.ui.secondaryText
    placeholderTextColor: applicationWindow.ui.secondaryText
    selectionColor: applicationWindow.ui.primary
    selectedTextColor: "#FFFFFF"
    leftPadding: 10
    rightPadding: 10
    background: Rectangle {
        radius: applicationWindow.ui.controlRadius
        color: control.hovered ? applicationWindow.ui.hover : applicationWindow.ui.control
        border.width: control.activeFocus ? 2 : 1
        border.color: control.activeFocus ? applicationWindow.ui.focus : applicationWindow.ui.separator
    }
}
