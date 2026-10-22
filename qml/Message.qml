/**
 *  OSM
 *  Copyright (C) 2019  Pavel Smokotnin

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
import QtQuick 2.0
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.3
import QtQuick.Controls.Material 2.2

Popup {
    id: popup
    property string text : "";
    property color color: "transparent"
    property var undoCallback: null
    width: 300
    height: 100
    x: (parent ? (parent.width  - width) / 2 : 100)
    y: (parent ? (parent.height - height) / 2 : 100)

    modal: true
    Overlay.modal: Rectangle { color: applicationAppearance.darkMode ? "#99000000" : "#55000000" }
    focus: true
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

    topPadding: 0
    bottomPadding: 0
    leftPadding: 0
    rightPadding: 0
    background: null

    Rectangle {
        anchors.fill: parent
        color: applicationWindow.ui.panel
        border.width: 1
        radius: 6
        border.color: popup.color;
        anchors.margins: 8

        Text {
            id: update;
            anchors.fill: parent
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            wrapMode: Text.Wrap
            textFormat: Text.RichText
            text: popup.text
            color: applicationWindow.ui.text
        }
    }

    function showError(message) {
        color = Material.color(Material.Red);
        text = message;
        open();
    }

    function showUndoable(message, callback) {
        undoText.text = message;
        undoCallback = callback;
        undoToast.open();
        undoTimer.restart();
    }

    function undo() {
        var callback = undoCallback;
        undoCallback = null;
        undoTimer.stop();
        undoToast.close();
        return callback ? callback() : false;
    }

    Popup {
        id: undoToast
        parent: Overlay.overlay
        x: Math.max(16, (parent ? parent.width - width : width) / 2)
        y: parent ? parent.height - height - 24 : 0
        width: Math.min(380, parent ? parent.width - 32 : 380)
        height: 58
        padding: 0
        modal: false
        focus: false
        closePolicy: Popup.NoAutoClose
        background: Rectangle {
            color: applicationWindow.ui.panel
            border.color: applicationWindow.ui.separator
            border.width: 1
            radius: 7
        }
        Row {
            anchors.fill: parent
            anchors.leftMargin: 16
            anchors.rightMargin: 12
            spacing: 12
            Text {
                id: undoText
                anchors.verticalCenter: parent.verticalCenter
                width: Math.max(0, parent.width - undoButton.implicitWidth - parent.spacing)
                color: applicationWindow.ui.text
                elide: Text.ElideRight
            }
            Button {
                id: undoButton
                anchors.verticalCenter: parent.verticalCenter
                text: qsTr("Undo")
                onClicked: popup.undo()
            }
        }
    }

    Timer {
        id: undoTimer
        interval: 6000
        onTriggered: undoToast.close()
    }
}
