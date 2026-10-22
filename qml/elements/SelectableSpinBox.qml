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
    font.family: applicationWindow.ui.fontFamily
    font.pixelSize: applicationWindow.ui.controlFontSize
    leftPadding: down.indicator.width
    rightPadding: up.indicator.width
    bottomPadding: 0
    property string title: ""
    // Our outlined controls need a symmetric content area, unlike Material's underline style.
    topPadding: bottomPadding
    contentItem: TextInput {
        text: (control.title && !control.activeFocus ? control.title + ": " : "") + control.displayText
        font: control.font
        color: control.uiTextColor
        selectionColor: applicationWindow.accentColor
        selectedTextColor: control.palette.highlightedText
        horizontalAlignment: TextInput.AlignHCenter
        verticalAlignment: TextInput.AlignVCenter
        selectByMouse: true
        readOnly: !control.editable
        validator: control.validator
        inputMethodHints: control.inputMethodHints
    }
    background: Rectangle {
        radius: applicationWindow.ui.controlRadius
        color: control.hovered ? applicationWindow.ui.hover : applicationWindow.ui.control
        border.width: control.activeFocus ? 2 : 1
        border.color: control.activeFocus ? applicationWindow.ui.primary : applicationWindow.ui.separator
    }
    down.indicator: Rectangle {
        x: 0; y: 1; width: 28; height: control.height - 2
        color: "transparent"
        Rectangle { anchors.right: parent.right; width: 1; height: parent.height; visible: parent.width > 0; color: applicationWindow.ui.separator }
        Text { anchors.centerIn: parent; text: "−"; font.pixelSize: 16; visible: parent.width > 0; color: control.uiTextColor }
    }
    up.indicator: Rectangle {
        x: control.width - width; y: 1; width: 28; height: control.height - 2
        color: "transparent"
        Rectangle { anchors.left: parent.left; width: 1; height: parent.height; visible: parent.width > 0; color: applicationWindow.ui.separator }
        Text { anchors.centerIn: parent; text: "+"; font.pixelSize: 16; visible: parent.width > 0; color: control.uiTextColor }
    }
    readonly property color uiTextColor: enabled ? applicationWindow.ui.text : applicationWindow.ui.secondaryText
    MouseArea {
        id: horizontalScrub
        x: control.down.indicator.width
        width: Math.max(0, control.width - control.down.indicator.width - control.up.indicator.width)
        height: control.height
        z: 2
        enabled: control.enabled
        hoverEnabled: true
        preventStealing: true
        cursorShape: pressed ? Qt.SizeHorCursor : Qt.IBeamCursor

        property real pressX: 0
        property int pressValue: 0
        property int pressRange: 0

        function updateFromPosition(position) {
            var delta = Math.round((position - pressX) / Math.max(1, width) * pressRange);
            var nextValue = Math.max(control.from, Math.min(control.to, pressValue + delta));
            if (control.value !== nextValue) {
                control.value = nextValue;
                control.valueModified();
            }
        }

        onPressed: function(mouse) {
            pressX = mouse.x;
            pressValue = control.value;
            pressRange = control.to - control.from;
            control.forceActiveFocus();
            control.contentItem.selectAll();
        }
        onPositionChanged: function(mouse) {
            if (pressed) updateFromPosition(mouse.x);
        }
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
