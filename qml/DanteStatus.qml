/**
 *  OSM
 *  Copyright (C) 2026  Pavel Smokotnin
 *
 *  This program is free software: you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation, either version 3 of the License, or
 *  (at your option) any later version.
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */
import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

Control {
    id: control
    property bool compact: false
    signal clicked()

    implicitWidth: mainRow.implicitWidth + leftPadding + rightPadding
    implicitHeight: 38
    leftPadding: 8
    rightPadding: 8
    topPadding: 4
    bottomPadding: 4

    hoverEnabled: true
    activeFocusOnTab: true

    Accessible.role: Accessible.Button
    Accessible.name: qsTr("Dante Monitoring Status: %1").arg(danteMonitor ? danteMonitor.overallStatusText : qsTr("Unavailable"))
    Accessible.description: qsTr("Click or press Enter to open Dante Monitoring window")

    function stateColor(state) {
        switch (state) {
        case "Up":
            return "#2ECC71";
        case "Down":
            return "#E74C3C";
        case "Degraded":
            return "#F39C12";
        case "Unknown":
        case "Stale":
            return "#E67E22";
        case "Not configured":
        case "Off":
        default:
            return applicationWindow ? applicationWindow.ui.secondaryText : "#7F8C8D";
        }
    }

    background: Rectangle {
        radius: applicationWindow ? applicationWindow.ui.controlRadius : 6
        color: control.hovered || control.visualFocus ?
               (applicationWindow ? applicationWindow.ui.hover : "#3B4048") : "transparent"
        border.width: control.visualFocus ? 2 : 0
        border.color: applicationWindow ? applicationWindow.ui.focus : "#AEBBF5"
    }

    contentItem: RowLayout {
        id: mainRow
        spacing: 8

        // Dante Title + optional [FIXTURE] tag
        RowLayout {
            spacing: 4
            Text {
                text: qsTr("Dante")
                color: applicationWindow ? applicationWindow.ui.text : "#F0F2F5"
                font.family: applicationWindow ? applicationWindow.ui.fontFamily : ""
                font.pixelSize: 12
                font.bold: true
                Layout.alignment: Qt.AlignVCenter
            }
            Text {
                visible: danteMonitor && danteMonitor.fixtureMode
                text: qsTr("[FIXTURE]")
                color: "#E67E22"
                font.family: applicationWindow ? applicationWindow.ui.fontFamily : ""
                font.pixelSize: 10
                font.bold: true
                Layout.alignment: Qt.AlignVCenter
            }
        }

        // Vertical divider
        Rectangle {
            width: 1
            height: 18
            color: applicationWindow ? applicationWindow.ui.separator : "#41464F"
            Layout.alignment: Qt.AlignVCenter
        }

        // When monitoring is disabled (Off)
        RowLayout {
            visible: !danteMonitor || (!danteMonitor.enabled && !danteMonitor.fixtureMode)
            spacing: 6
            Layout.alignment: Qt.AlignVCenter

            Rectangle {
                width: 7; height: 7; radius: 4
                color: control.stateColor("Off")
                Layout.alignment: Qt.AlignVCenter
            }
            Text {
                text: qsTr("Off")
                color: applicationWindow ? applicationWindow.ui.secondaryText : "#B7BEC8"
                font.family: applicationWindow ? applicationWindow.ui.fontFamily : ""
                font.pixelSize: 11
                Layout.alignment: Qt.AlignVCenter
            }
        }

        // When monitoring is enabled or fixture active: Primary & Secondary status
        RowLayout {
            visible: danteMonitor && (danteMonitor.enabled || danteMonitor.fixtureMode)
            spacing: 10
            Layout.alignment: Qt.AlignVCenter

            // Primary Link
            RowLayout {
                spacing: 5
                Layout.alignment: Qt.AlignVCenter

                Rectangle {
                    width: 7; height: 7; radius: 4
                    color: control.stateColor(danteMonitor ? danteMonitor.primaryRoleState : "Off")
                    Layout.alignment: Qt.AlignVCenter
                }
                Text {
                    text: control.compact ?
                          qsTr("P · %1").arg(danteMonitor ? danteMonitor.primaryRoleState : "") :
                          qsTr("Primary · %1").arg(danteMonitor ? danteMonitor.primaryRoleState : "")
                    color: applicationWindow ? applicationWindow.ui.text : "#F0F2F5"
                    font.family: applicationWindow ? applicationWindow.ui.fontFamily : ""
                    font.pixelSize: 11
                    Layout.alignment: Qt.AlignVCenter
                }
            }

            // Secondary Link
            RowLayout {
                spacing: 5
                Layout.alignment: Qt.AlignVCenter

                Rectangle {
                    width: 7; height: 7; radius: 4
                    color: control.stateColor(danteMonitor ? danteMonitor.secondaryRoleState : "Off")
                    Layout.alignment: Qt.AlignVCenter
                }
                Text {
                    text: control.compact ?
                          qsTr("S · %1").arg(danteMonitor ? danteMonitor.secondaryRoleState : "") :
                          qsTr("Secondary · %1").arg(danteMonitor ? danteMonitor.secondaryRoleState : "")
                    color: applicationWindow ? applicationWindow.ui.text : "#F0F2F5"
                    font.family: applicationWindow ? applicationWindow.ui.fontFamily : ""
                    font.pixelSize: 11
                    Layout.alignment: Qt.AlignVCenter
                }
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: control.clicked()
    }

    Keys.onReturnPressed: control.clicked()
    Keys.onSpacePressed: control.clicked()

    ToolTip.visible: control.hovered
    ToolTip.delay: 500
    ToolTip.text: danteMonitor ?
                  qsTr("%1\nClick to configure Dante Monitoring").arg(danteMonitor.overallStatusText) :
                  qsTr("Dante Monitoring Unavailable")
}
