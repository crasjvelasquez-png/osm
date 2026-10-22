import QtQuick 2.15
import QtQuick.Controls 2.15

Button {
    id: control
    implicitWidth: Math.max(36, implicitContentWidth + leftPadding + rightPadding)
    implicitHeight: applicationWindow.ui.controlHeight
    font.family: applicationWindow.ui.fontFamily
    font.pixelSize: applicationWindow.ui.controlFontSize
    font.capitalization: Font.MixedCase
    leftPadding: 12
    rightPadding: 12
    topPadding: 0
    bottomPadding: 0
    topInset: 0
    bottomInset: 0
    hoverEnabled: true
    contentItem: Text {
        text: control.text
        font: control.font
        color: !control.enabled ? applicationWindow.ui.secondaryText :
            control.highlighted ? "#FFFFFF" : applicationWindow.ui.text
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        elide: Text.ElideRight
    }
    background: Rectangle {
        radius: applicationWindow.ui.controlRadius
        color: !control.enabled ? applicationWindow.ui.panel : control.highlighted ?
            (control.down ? applicationWindow.ui.primaryPressed : control.hovered ? applicationWindow.ui.primaryHover : applicationWindow.ui.primary) :
            control.down || control.checked ? applicationWindow.ui.selection : control.hovered ? applicationWindow.ui.hover :
            control.flat ? "transparent" : applicationWindow.ui.control
        border.width: control.activeFocus ? 2 : control.flat || control.highlighted ? 0 : 1
        border.color: control.activeFocus ? applicationWindow.ui.primary : applicationWindow.ui.separator
    }
}
