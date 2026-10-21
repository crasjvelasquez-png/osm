/**
 *  OSM
 *  Copyright (C) 2021  Pavel Smokotnin

 *  This program is free software: you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation, either version 3 of the License, or
 *  (at your option) any later version.

 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.

 *  You should have received a copy of the GNU General Public License
 *  along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */
import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import "elements"

Dialog {
    id: dialog
    property string acceptText: qsTr("OK")
    property string rejectText: qsTr("Cancel")
    property string detail: ""
    property bool acceptOnReturn: true
    implicitHeight: header.implicitHeight + footer.implicitHeight + (detail.length ? contentItem.implicitHeight + 24 : 20)
    height: implicitHeight
    TextMetrics { id: titleMetrics; text: dialog.title; font.family: dialog.font.family; font.pixelSize: 15; font.weight: Font.DemiBold }
    modal: true
    focus: true
    width: Math.min(Math.max(300, titleMetrics.width + 40), 380, parent ? parent.width - 32 : 380)
    padding: 20
    topPadding: 0
    bottomPadding: 0
    spacing: 0
    font.family: applicationWindow.ui.fontFamily
    font.pixelSize: 13
    closePolicy: Popup.CloseOnEscape
    x: parent ? Math.round((parent.width - width) / 2) : 100
    y: parent ? Math.round((parent.height - height) / 2) : 100
    Overlay.modal: Rectangle { color: applicationAppearance.darkMode ? "#66000000" : "#33000000" }
    background: Rectangle {
        radius: 14
        color: applicationWindow.ui.panel
        border.color: applicationWindow.ui.separator
    }
    header: Text {
        text: dialog.title
        visible: text.length > 0
        padding: 20
        bottomPadding: 0
        font.family: dialog.font.family
        font.pixelSize: 15
        font.weight: Font.DemiBold
        color: applicationWindow.ui.text
        wrapMode: Text.Wrap
        textFormat: Text.PlainText
        horizontalAlignment: Text.AlignHCenter
    }
    contentItem: Text {
        Keys.onReturnPressed: { if (dialog.acceptOnReturn) dialog.accept() }
        Keys.onEnterPressed: { if (dialog.acceptOnReturn) dialog.accept() }
        text: dialog.detail
        visible: text.length > 0
        font: dialog.font
        color: applicationWindow.ui.text
        wrapMode: Text.Wrap
        horizontalAlignment: Text.AlignHCenter
        textFormat: Text.PlainText
    }
    footer: DialogButtonBox {
        padding: 20
        topPadding: 0
        implicitHeight: 52
        spacing: 8
        alignment: Qt.AlignRight
        background: Item {}
        StudioButton {
            text: dialog.rejectText
            implicitWidth: Math.max(80, implicitContentWidth + 24)
            implicitHeight: 32
            DialogButtonBox.buttonRole: DialogButtonBox.RejectRole
        }
        StudioButton {
            text: dialog.acceptText
            implicitWidth: Math.max(80, implicitContentWidth + 24)
            implicitHeight: 32
            highlighted: true
            DialogButtonBox.buttonRole: DialogButtonBox.AcceptRole
        }
        onAccepted: dialog.accept()
        onRejected: dialog.reject()
    }
    onOpened: contentItem.forceActiveFocus()
}
