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
import QtQuick 2.7
import QtQuick.Controls 2.1
import QtQuick.Layouts 1.3
import "qrc:/"

Item {
    id: measurement

    property var dataModel;
    property var dataModelData : dataModel.data
    property bool chartable : true;
    property bool highlight : false;
    property string propertiesQml: "qrc:/source/MeasurementProperties.qml"
    height: 50
    width: (parent ? parent.width : 0)

    RowLayout {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.rightMargin: 10
        spacing: 4

        MulticolorCheckBox {
            id: checkbox
            Layout.alignment: Qt.AlignVCenter
            checked: (dataModelData ? dataModelData.active : false)
            checkedColor: (dataModelData ? dataModelData.color : "none")
            Accessible.name: qsTr("Enable %1").arg(dataModelData ? dataModelData.name : qsTr("measurement"))
            Accessible.role: Accessible.CheckBox

            onCheckStateChanged: {
                if (dataModel && dataModelData)
                    dataModelData.active = checked
            }
            error: !!dataModelData && (dataModelData.error || !dataModelData.inputAvailable)
            errorText: dataModelData && dataModelData.error ?
                qsTr("Can't start the %1. Device is not supported or busy.").arg(dataModelData.name) :
                qsTr("No audio input is available for %1.").arg(dataModelData ? dataModelData.name : qsTr("this source"))
        }

        ColumnLayout {
            Layout.fillWidth: true

            RowLayout {
                Layout.fillWidth: true
                spacing: 4

                Label {
                    Layout.fillWidth: true
                    Layout.rightMargin: dataModelData && dataModelData.cloneable ? 62 : 28
                    elide: Text.ElideRight
                    font.pixelSize: applicationWindow.ui.controlFontSize
                    font.bold: highlight
                    text:  (dataModelData ? dataModelData.name : "")
                }

                Label {
                    id: inputWarning
                    visible: !!dataModelData && (dataModelData.error || !dataModelData.inputAvailable)
                    text: dataModelData && dataModelData.error ? qsTr("ERR") : qsTr("NO INPUT")
                    color: applicationWindow.ui.text
                    font.pixelSize: 10
                    font.bold: true
                    leftPadding: 5
                    rightPadding: 5
                    Accessible.role: Accessible.StaticText
                    Accessible.name: dataModelData && dataModelData.error ? qsTr("Audio device error") : qsTr("No audio input")
                    Accessible.description: checkbox.errorText
                    activeFocusOnTab: true
                    ToolTip.visible: visible && (hovered || activeFocus)
                    ToolTip.text: checkbox.errorText
                    background: Rectangle {
                        radius: 3
                        color: applicationWindow.ui.control
                        border.width: 1
                        border.color: applicationWindow.ui.primary
                    }
                }
            }

            Meter {
                dBV: (dataModelData ? dataModelData.level : 0)
                peak:(dataModelData ? dataModelData.measurementPeak : 0)
                width: parent.width
            }

            Meter {
                dBV: (dataModelData ? dataModelData.referenceLevel : 0)
                peak:(dataModelData ? dataModelData.referencePeak : 0)
                width: parent.width
            }
        }

        Connections {
            target: dataModelData
            function onColorChanged() {
                checkbox.checkedColor = dataModelData.color;
            }
        }

        Component.onCompleted: {
            if (!dataModel || !dataModelData) {
                return;
            }
            if (!dataModelData.isColorValid()) {
                dataModelData.color = sourceList.nextColor();
            }
            dataModelData.errorChanged.connect(function(error) {
                if (error) {
                    applicationWindow.message.showError(qsTr("Can't start the %1.<br/>Device is not supported or busy.").arg(dataModelData.name));
                }
            });
        }
    }
}
