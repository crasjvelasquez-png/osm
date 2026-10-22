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
import QtQuick 2.13
import QtQuick.Controls 2.13
import QtQuick.Layouts 1.3
import QtQuick.Dialogs 1.2
import QtQuick.Controls.Material 2.13

import OpenSoundMeter 1.0
import Measurement 1.0
import Audio 1.0
import "qrc:/elements"

Item {
    id: measurementProperties
    property var dataObject
    property var dataObjectData : dataObject.data
    readonly property int elementWidth: 150
    readonly property int spinboxWidth: 168
    readonly property bool isLocal : dataObjectData.objectName === "Measurement"

    ColumnLayout {
        spacing: 0
        anchors.fill: parent

        RowLayout {

            DropDown {
                title: qsTr("average type")
                id: averageType
                Layout.minimumWidth: 132
                Layout.preferredWidth: elementWidth
                model: ["off", "LPF", "FIFO"]
                displayLabels: [qsTr("Off"), qsTr("LPF (Low-Pass)"), qsTr("FIFO (Running Avg)")]
                currentIndex: dataObjectData.averageType
                ToolTip.visible: hovered || activeFocus
                ToolTip.text: qsTr("average type")
                onCurrentIndexChanged: dataObjectData.averageType = currentIndex;
            }

            SelectableSpinBox {
                title: qsTr("average count")
                Layout.minimumWidth: 150
                Layout.preferredWidth: elementWidth
                value: dataObjectData.average
                from: 1
                to: 100
                editable: true
                onValueChanged: dataObjectData.average = value

                ToolTip.visible: hovered || activeFocus
                ToolTip.text: qsTr("average count")

                visible: dataObjectData.averageType === Measurement.FIFO;
            }

            DropDown {
                title: qsTr("LPF frequency")
                Layout.minimumWidth: 132
                Layout.preferredWidth: elementWidth
                model: [ "0.25Hz", "0.5Hz", "1Hz" ]
                displayLabels: ["0.25 Hz", "0.5 Hz", "1 Hz"]
                currentIndex: dataObjectData.filtersFrequency
                onCurrentIndexChanged: dataObjectData.filtersFrequency = currentIndex;

                ToolTip.visible: hovered || activeFocus
                ToolTip.text: qsTr("LPF frequency")

                visible: dataObjectData.averageType === Measurement.LPF;
            }

            Rectangle {
                Layout.preferredWidth: elementWidth
                visible: dataObjectData.averageType === Measurement.OFF;
            }

            StudioButton {
                text: "+/–"
                checkable: true
                checked: dataObjectData.polarity
                onCheckedChanged: dataObjectData.polarity = checked
                Layout.preferredWidth: (elementWidth - 5) / 2
                Material.background: parent.Material.background

                ToolTip.visible: hovered || activeFocus
                ToolTip.text: qsTr("inverse polarity at measurement chanel")
            }

            StudioButton {
                font.family: "Osm"
                text: "\ue808"
                onClicked: dataObjectData.resetAverage()
                Layout.preferredWidth: (elementWidth - 5) / 2
                Material.background: parent.Material.background

                ToolTip.visible: hovered || activeFocus
                ToolTip.text: qsTr("Reset buffers")
                Accessible.name: qsTr("Reset measurement buffers")
                Accessible.role: Accessible.Button
            }

            Item {
                id: calibartionGroup
                Layout.preferredWidth: elementWidth
                Layout.fillHeight: true

                CheckBox {
                    id: calibrateOn
                    enabled: isLocal
                    text: qsTr("calibrate")
                    Layout.maximumWidth: elementWidth - 30
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.left: parent.left
                    checked: isLocal ? dataObjectData.calibration : false
                    onCheckStateChanged: {
                        if (checked) {
                            if (dataObjectData.calibrationLoaded) {
                                dataObjectData.calibration = checked;
                            } else {
                                openCalibrationFileDialog.open();
                            }
                        } else {
                            dataObjectData.calibration = false;
                        }
                    }

                    ToolTip.visible: hovered || activeFocus
                    ToolTip.text: qsTr("apply calibration")

                    contentItem: Text {
                        leftPadding: calibrateOn.indicator && !calibrateOn.mirrored ? calibrateOn.indicator.width + calibrateOn.spacing : 0
                        rightPadding: calibrateOn.indicator && calibrateOn.mirrored ? calibrateOn.indicator.width + calibrateOn.spacing : 0
                        text: calibrateOn.text
                        font: calibrateOn.font
                        color: calibrateOn.enabled ? calibrateOn.Material.foreground : calibrateOn.Material.hintTextColor
                        elide: Text.ElideNone
                        verticalAlignment: Text.AlignVCenter
                    }
                }
                StudioButton {
                    enabled: isLocal
                    implicitWidth: 30
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.left: calibrateOn.right
                    anchors.leftMargin: -10
                    flat: true
                    spacing: 0
                    text: "..."
                    onClicked: {openCalibrationFileDialog.open();}
                    ToolTip.visible: hovered || activeFocus
                    ToolTip.text: qsTr("open calibration file")
                }
                FileDialog {
                    id: openCalibrationFileDialog
                    selectExisting: true
                    title: qsTr("Please choose a file's name")
                    folder: (typeof shortcuts !== 'undefined' ? shortcuts.home : Filesystem.StandardFolder.Home)
                    onAccepted: function() {
                        if (dataObjectData.loadCalibrationFile(openCalibrationFileDialog.fileUrl)) {
                            dataObjectData.calibration = true;
                        } else {
                            dataObjectData.calibration = false;
                        }
                    }
                    onRejected: {
                        dataObjectData.calibration = false;
                        calibrateOn.checked = dataObjectData.calibration;
                    }
                }
            }

            ColorPicker {
                id: colorPicker
                Layout.preferredWidth: 25
                Layout.preferredHeight: 25
                Layout.margins: 0

                onColorChanged: {
                    dataObjectData.color = color
                }

                Component.onCompleted: {
                    color = dataObjectData.color
                }
                ToolTip.visible: hovered || activeFocus
                ToolTip.text: qsTr("series color")
            }

            NameField {
                id:titleField
                target: dataObject
                Layout.preferredWidth: elementWidth - 25
                Layout.minimumWidth: 100
                Layout.alignment: Qt.AlignVCenter
            }

            RowLayout {
                Layout.fillWidth: true
            }

            FloatSpinBox {
                id: offsetSpinBox
                Layout.minimumWidth: 156
                Layout.preferredWidth: spinboxWidth
                value: dataObjectData.offset
                from: -90
                to: 90
                decimals: 1
                units: "dB"
                indicators: false
                onValueChanged: dataObjectData.offset = value
                tooltiptext: qsTr("reference offset")
                implicitHeight: titleField.implicitHeight
                Layout.alignment: Qt.AlignVCenter
            }

            FloatSpinBox {
                id: gainSpinBox
                Layout.minimumWidth: 156
                Layout.preferredWidth: spinboxWidth
                value: dataObjectData.gain
                from: -90
                to: 90
                decimals: 1
                units: "dB"
                indicators: false
                onValueChanged: dataObjectData.gain = value
                tooltiptext: qsTr("gain")
                implicitHeight: titleField.implicitHeight
                Layout.alignment: Qt.AlignVCenter
            }

            StudioButton {
                text: qsTr("94 dB");
                onClicked: {
                    dataObjectData.applyAutoGain(94 - 140);
                    gainSpinBox.value = dataObjectData.gain;
                }
                font.capitalization: Font.MixedCase
                ToolTip.visible: hovered || activeFocus
                ToolTip.text: qsTr("apply estimated gain for 94 dB SPL")
            }

            SelectableSpinBox {
                title: qsTr("estimated delay delta: <b>%L1ms</b>")
                id: delaySpin
                Layout.alignment: Qt.AlignVCenter
                Layout.minimumWidth: 156
                Layout.preferredWidth: spinboxWidth
                value: dataObjectData.delay
                implicitHeight: titleField.implicitHeight
                from: -96000
                to: 96000
                editable: true
                spacing: 0
                down.indicator.width: 0
                up.indicator.width: 0
                onValueChanged: dataObjectData.delay = value

                textFromValue: function(value, locale) {
                    return Number(1000 * value / dataObjectData.sampleRate).toLocaleString(locale, 'f', 2) + "ms";
                }

                valueFromText: function(text, locale) {
                    return Number.fromLocaleString(locale, text.replace("ms", "")) * dataObjectData.sampleRate / 1000;
                }

                ToolTip.visible: hovered || activeFocus
                ToolTip.text: qsTr("estimated delay delta: <b>%L1ms</b>")
                    .arg(Number(1000 * dataObjectData.estimatedDelta / dataObjectData.sampleRate).toLocaleString(locale, 'f', 2));
            }

            StudioButton {
                text: qsTr("%L1 ms")
                    .arg(Number(1000 * dataObjectData.estimated / dataObjectData.sampleRate).toLocaleString(locale, 'f', 2));
                onClicked: {
                    delaySpin.value = dataObjectData.estimated;
                }
                implicitWidth: 75

                font.capitalization: Font.AllLowercase
                ToolTip.visible: hovered || activeFocus
                ToolTip.text: qsTr("apply estimated delay (%1)").arg(applicationWindow.shortcutRegistry.display("measurement.applyDelay"))
            }
        }

        RowLayout {
            Layout.fillWidth: true

            DropDown {
                title: qsTr("Transfrom mode")
                id: modeSelect
                model: dataObjectData.modes
                currentIndex: dataObjectData.mode
                displayText: (dataObjectData.mode === Measurement.LFT ? "LTW" : (modeSelect.width > 120 ? "Power:" : "") + currentText)
                ToolTip.visible: hovered || activeFocus
                ToolTip.text: qsTr("Transfrom mode")
                onCurrentIndexChanged: dataObjectData.mode = currentIndex;
                Layout.preferredWidth: elementWidth
            }

            DropDown {
                title: qsTr("window function")
                id: windowSelect
                model: dataObjectData.windows
                currentIndex: dataObjectData.window
                onCurrentIndexChanged: dataObjectData.window = currentIndex
                ToolTip.visible: hovered || activeFocus
                ToolTip.text: qsTr("window function")
                Layout.preferredWidth: elementWidth
            }

            DropDown {
                title: qsTr("apply filter on M input")
                id: inputFilterSelect
                model: dataObjectData.inputFilters
                currentIndex: dataObjectData.inputFilter
                onCurrentIndexChanged: dataObjectData.inputFilter = currentIndex
                ToolTip.visible: hovered || activeFocus
                ToolTip.text: qsTr("apply filter on M input")
                Layout.preferredWidth: elementWidth
            }

            DropDown {
                title: qsTr("measurement chanel number")
                id: measurementChannel
                enabled: isLocal
                currentIndex: dataObjectData.dataChanel
                onCurrentIndexChanged: dataObjectData.dataChanel = currentIndex
                displayText: "M: " + currentText
                ToolTip.visible: hovered || activeFocus
                ToolTip.text: qsTr("measurement chanel number")
                Layout.preferredWidth: elementWidth
            }

            DropDown {
                title: qsTr("reference chanel number")
                id: referenceChannel
                enabled: isLocal
                currentIndex: dataObjectData.referenceChanel
                onCurrentIndexChanged: dataObjectData.referenceChanel = currentIndex
                displayText: "R: " + currentText
                ToolTip.visible: hovered || activeFocus
                ToolTip.text: qsTr("reference chanel number")
                Layout.preferredWidth: elementWidth
            }

            DropDown {
                Layout.minimumWidth: 120
                title: qsTr("audio input device")
                id: deviceSelect
                enabled: isLocal
                Layout.fillWidth: true
                model: DeviceModel {
                    id: deviceModel
                    scope: DeviceModel.InputOnly
                }
                textRole: "name"
                valueRole: "id"
                currentIndex: { model.indexOf(dataObjectData.deviceId) }
                ToolTip.visible: hovered || activeFocus
                ToolTip.text: qsTr("audio input device")
                onCurrentIndexChanged: {
                    var measurementIndex = measurementChannel.currentIndex;
                    var referenceIndex = referenceChannel.currentIndex;
                    var channelNames = deviceModel.channelNames(deviceSelect.currentIndex);
                    channelNames.push("Loop");
                    dataObjectData.deviceId = model.deviceId(currentIndex);
                    measurementChannel.model = channelNames;
                    referenceChannel.model   = channelNames;

                    measurementChannel.currentIndex = measurementIndex < channelNames.length + 1 ? measurementIndex : -1;
                    referenceChannel.currentIndex = referenceIndex < channelNames.length + 1 ? referenceIndex : -1;
                }

                Connections {
                    target: deviceModel
                    function onModelReset() {
                        deviceSelect.currentIndex = deviceModel.indexOf(dataObjectData.deviceId);
                        var measurementIndex = measurementChannel.currentIndex;
                        var referenceIndex = referenceChannel.currentIndex;
                        var channelNames = deviceModel.channelNames(deviceSelect.currentIndex);
                        channelNames.push("Loop");

                        measurementChannel.model = channelNames;
                        referenceChannel.model   = channelNames;

                        measurementChannel.currentIndex = measurementIndex < channelNames.length + 1 ? measurementIndex : -1;
                        referenceChannel.currentIndex = referenceIndex < channelNames.length + 1 ? referenceIndex : -1;
                    }
                }
            }

            StudioButton {
                text: qsTr("Store");
                onClicked: measurementProperties.store()
                ToolTip.visible: hovered || activeFocus
                ToolTip.text: qsTr("store current measurement (%1)").arg(applicationWindow.shortcutRegistry.display("measurement.store"))
                implicitWidth: 75
            }

            Shortcut {
                sequence: applicationWindow.shortcutRegistry.sequence("measurement.store")
                enabled: !applicationWindow.textEntryFocused
                onActivated: measurementProperties.store()
            }

            Shortcut {
                sequence: applicationWindow.shortcutRegistry.sequence("measurement.applyDelay")
                enabled: !applicationWindow.textEntryFocused
                onActivated: {
                    delaySpin.value = dataObjectData.estimated;
                }
            }
        }
    }//ColumnLayout

    function store() {
        var stored = dataObjectData.store();
        if (stored) {
            stored.data.active = true;
            sourceList.appendItem(stored, true);
        }
    }
}
