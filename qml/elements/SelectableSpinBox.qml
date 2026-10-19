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
import QtQuick.Controls 2.2

SpinBox {
    id: control
    implicitWidth: 160
    implicitHeight: 36
    font.pixelSize: 14
    leftPadding: down.indicator.width
    rightPadding: up.indicator.width
    background: Rectangle {
        radius: 6
        color: control.hovered ? applicationWindow.ui.hover : applicationWindow.ui.control
        border.width: control.activeFocus ? 2 : 1
        border.color: control.activeFocus ? applicationWindow.accentColor : applicationWindow.ui.separator
    }
    down.indicator: Rectangle {
        x: 0; y: 1; width: 28; height: control.height - 2
        color: "transparent"
        Rectangle { anchors.right: parent.right; width: 1; height: parent.height; visible: parent.width > 0; color: applicationWindow.ui.separator }
        Text { anchors.centerIn: parent; text: "−"; font.pixelSize: 16; visible: parent.width > 0; color: control.uiTextColor }
    }
    up.indicator: Rectangle {
        x: control.width - 28; y: 1; width: 28; height: control.height - 2
        color: "transparent"
        Rectangle { anchors.left: parent.left; width: 1; height: parent.height; visible: parent.width > 0; color: applicationWindow.ui.separator }
        Text { anchors.centerIn: parent; text: "+"; font.pixelSize: 16; visible: parent.width > 0; color: control.uiTextColor }
    }
    readonly property color uiTextColor: enabled ? applicationWindow.ui.text : applicationWindow.ui.secondaryText
    Component.onCompleted: {
        contentItem.selectByMouse = true;
        contentItem.horizontalAlignment = Text.AlignHCenter;
    }

    onFocusChanged: {
        if (focus) {
            contentItem.selectAll();
        }
    }

    Connections {
        target: contentItem
        function onEditingFinished() {
            focus = false;
        }
    }
    Keys.onEscapePressed: {
        focus = false;
    }
    Keys.onReturnPressed: {
        focus = false;
    }
}
