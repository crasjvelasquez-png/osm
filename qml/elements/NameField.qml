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
import QtQuick 2.0
import QtQuick.Controls 2.13

TextField {
    id: control
    property var target //Shared::Source

    placeholderText: qsTr("title")
    text: target.data.name
    onTextEdited: target.data.name = text
    ToolTip.visible: hovered
    ToolTip.text: qsTr("title")

    selectByMouse: true
    implicitHeight: 36
    font.pixelSize: 14
    background: Rectangle {
        radius: 6
        color: control.hovered ? applicationWindow.ui.hover : applicationWindow.ui.control
        border.width: control.activeFocus ? 2 : 1
        border.color: control.activeFocus ? applicationWindow.accentColor : applicationWindow.ui.separator
    }
    onFocusChanged: {
        if (focus) {
            selectAll();
        }
    }
    onEditingFinished: {
        focus = false;
    }
    Keys.onEscapePressed: {
        focus = false;
    }
}
