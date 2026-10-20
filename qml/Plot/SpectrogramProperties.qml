/**
 *  OSM
 *  Copyright (C) 2018  Pavel Smokotnin

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
import QtQuick 2.9
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.3
import QtQuick.Dialogs 1.3

import "../" as Root
import "../elements"
import SourceModel 1.0
import OpenSoundMeter 1.0

Item {
    id: chartProperties
    property var dataObject

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

    RowLayout {
        spacing: 0

        SelectableSpinBox {
            value: dataObject.xmin
            onValueChanged: dataObject.xmin = value
            from: dataObject.xLowLimit
            to: dataObject.xHighLimit
            editable: true
            implicitWidth: 170
            Layout.fillWidth: true

            ToolTip.visible: hovered
            ToolTip.text: qsTr("x from")

            textFromValue: function(value, locale) {
                return Number(value) + "Hz"
            }

            valueFromText: function(text, locale) {
                return parseInt(text)
            }
        }

        SelectableSpinBox {
            value: dataObject.xmax
            onValueChanged: dataObject.xmax = value
            from: dataObject.xLowLimit
            to: dataObject.xHighLimit
            editable: true
            implicitWidth: 170
            Layout.fillWidth: true

            ToolTip.visible: hovered
            ToolTip.text: qsTr("x to")

            textFromValue: function(value, locale) {
                return Number(value) + "Hz"
            }

            valueFromText: function(text, locale) {
                return parseInt(text)
            }
        }

        SelectableSpinBox {
            value: dataObject.ymin
            onValueChanged: dataObject.ymin = value
            from: dataObject.yLowLimit
            to: dataObject.yHighLimit
            editable: true
            implicitWidth: 170
            Layout.fillWidth: true

            ToolTip.visible: hovered
            ToolTip.text: qsTr("y from")

            textFromValue: function(value, locale) {
                return Number(value) + "s"
            }

            valueFromText: function(text, locale) {
                return parseInt(text)
            }
        }

        SelectableSpinBox {
            value: dataObject.ymax
            onValueChanged: dataObject.ymax = value
            from: dataObject.yLowLimit
            to: dataObject.yHighLimit
            editable: true
            implicitWidth: 170
            Layout.fillWidth: true

            ToolTip.visible: hovered
            ToolTip.text: qsTr("y to")

            textFromValue: function(value, locale) {
                return Number(value) + "s"
            }

            valueFromText: function(text, locale) {
                return parseInt(text)
            }
        }

        Button {
            font.family: "Osm"
            text: "\ue809"
            implicitWidth: 60
            checkable: true
            checked: !dataObject.active
            onCheckedChanged: {
                dataObject.active = !checked
            }
            ToolTip.visible: hovered
            ToolTip.text: qsTr("pause")
        }

        Item {
            width: 5
        }

        Button {
            font.family: "Osm"
            text: "\ue804"
            implicitWidth: 60
            onClicked: fileDialog.open();
            ToolTip.visible: hovered
            ToolTip.text: qsTr("save chart as an image")
        }
    }
    RowLayout {
        TitledCombo {
            title: qsTr("ppo")
            tooltip: qsTr("points per octave")
            Layout.preferredWidth: 110
            model: [1, 3, 6, 12, 24, 48]
            Component.onCompleted: {
                currentIndex = model.indexOf(dataObject.pointsPerOctave);
            }
            currentIndex: model.indexOf(dataObject.pointsPerOctave);
            onCurrentIndexChanged: dataObject.pointsPerOctave = model[currentIndex];
        }

        Item {
            implicitWidth: 170
            implicitHeight: 36
            Layout.fillWidth: true
            SelectableSpinBox {
                id: minDbControl
                anchors.fill: parent
                value: dataObject.min
                onValueChanged: dataObject.min = value
                from: -140
                to: dataObject.mid - 1
                editable: true

                ToolTip.visible: hovered
                ToolTip.text: qsTr("min dB point")

                textFromValue: function(value, locale) {
                    return Number(value) + "dB"
                }

                valueFromText: function(text, locale) {
                    return parseInt(text)
                }
                Rectangle {
                    color: "#2196F3"
                    anchors.fill: parent
                    opacity: 0.15
                }
            }
            MouseArea {
                x: 28
                width: Math.max(0, parent.width - 56)
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                z: 1
                preventStealing: true
                hoverEnabled: true
                cursorShape: Qt.SizeHorCursor
                ToolTip.visible: containsMouse || pressed
                ToolTip.delay: 0
                ToolTip.timeout: -1
                ToolTip.text: qsTr("Minimum: %1 dB\nMin: %2 dB    Max: %3 dB")
                    .arg(minDbControl.value).arg(minDbControl.from).arg(minDbControl.to)
                function updateFromPosition(position) {
                    var fraction = Math.max(0, Math.min(1, position / width));
                    minDbControl.value = minDbControl.from + Math.round(fraction * (minDbControl.to - minDbControl.from));
                }
                SliderFeedback {
                    control: minDbControl
                    tint: "#2196F3"
                }
                onPressed: function(mouse) { updateFromPosition(mouse.x); }
                onPositionChanged: function(mouse) { if (pressed) updateFromPosition(mouse.x); }
            }
        }

        Item {
            implicitWidth: 170
            implicitHeight: 36
            Layout.fillWidth: true
            SelectableSpinBox {
                id: midDbControl
                anchors.fill: parent
                value: dataObject.mid
                onValueChanged: dataObject.mid = value
                from: dataObject.min
                to: dataObject.max
                editable: true

                ToolTip.visible: hovered
                ToolTip.text: qsTr("mid dB point")

                textFromValue: function(value, locale) {
                    return Number(value) + "dB"
                }

                valueFromText: function(text, locale) {
                    return parseInt(text)
                }

                Rectangle {
                    color: "#8BC34A"
                    anchors.fill: parent
                    opacity: 0.15
                }
            }
            MouseArea {
                x: 28
                width: Math.max(0, parent.width - 56)
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                z: 1
                preventStealing: true
                hoverEnabled: true
                cursorShape: Qt.SizeHorCursor
                ToolTip.visible: containsMouse || pressed
                ToolTip.delay: 0
                ToolTip.timeout: -1
                ToolTip.text: qsTr("Midpoint: %1 dB\nMin: %2 dB    Max: %3 dB")
                    .arg(midDbControl.value).arg(midDbControl.from).arg(midDbControl.to)
                function updateFromPosition(position) {
                    var fraction = Math.max(0, Math.min(1, position / width));
                    midDbControl.value = midDbControl.from + Math.round(fraction * (midDbControl.to - midDbControl.from));
                }
                SliderFeedback {
                    control: midDbControl
                    tint: "#8BC34A"
                }
                onPressed: function(mouse) { updateFromPosition(mouse.x); }
                onPositionChanged: function(mouse) { if (pressed) updateFromPosition(mouse.x); }
            }
        }

        Item {
            implicitWidth: 170
            implicitHeight: 36
            Layout.fillWidth: true
            SelectableSpinBox {
                id: maxDbControl
                anchors.fill: parent
                value: dataObject.max
                onValueChanged: dataObject.max = value
                from: dataObject.mid + 1
                to: 20
                editable: true

                ToolTip.visible: hovered
                ToolTip.text: qsTr("max dB point")

                textFromValue: function(value, locale) {
                    return Number(value) + "dB"
                }

                valueFromText: function(text, locale) {
                    return parseInt(text)
                }

                Rectangle {
                    color: "#F44336"
                    anchors.fill: parent
                    opacity: 0.15
                }
            }
            MouseArea {
                x: 28
                width: Math.max(0, parent.width - 56)
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                z: 1
                preventStealing: true
                hoverEnabled: true
                cursorShape: Qt.SizeHorCursor
                ToolTip.visible: containsMouse || pressed
                ToolTip.delay: 0
                ToolTip.timeout: -1
                ToolTip.text: qsTr("Maximum: %1 dB\nMin: %2 dB    Max: %3 dB")
                    .arg(maxDbControl.value).arg(maxDbControl.from).arg(maxDbControl.to)
                function updateFromPosition(position) {
                    var fraction = Math.max(0, Math.min(1, position / width));
                    maxDbControl.value = maxDbControl.from + Math.round(fraction * (maxDbControl.to - maxDbControl.from));
                }
                SliderFeedback {
                    control: maxDbControl
                    tint: "#F44336"
                }
                onPressed: function(mouse) { updateFromPosition(mouse.x); }
                onPositionChanged: function(mouse) { if (pressed) updateFromPosition(mouse.x); }
            }
        }

        RowLayout {
            Layout.fillWidth: true
        }

        TitledCombo {
            tooltip: qsTr("show only this source")
            model: SourceModel {
                unrollGroups: true
                list: sourceList
            }
            Layout.preferredWidth: 160
            currentIndex: { dataObject.selected ? model.indexOf(dataObject.selected[0]) : -1 }
            textRole: "title"
            valueRole: "source"
            onCurrentIndexChanged: {
                dataObject.selected = [model.get(currentIndex)];
            }
        }

        FileDialog {
            id: fileDialog
            selectExisting: false
            title: "Please choose a file's name"
            folder: (typeof shortcuts !== 'undefined' ? shortcuts.home : Filesystem.StandardFolder.Home)
            defaultSuffix: "png"
            onAccepted: {
                dataObject.parent.grabToImage(function(result) {
                    result.saveToFile(dataObject.parent.urlForGrab(fileDialog.fileUrl));
                });
            }
        }
    }
  }
}
