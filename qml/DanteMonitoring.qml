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
import QtQuick.Controls.Material 2.15
import QtQuick.Layouts 1.15
import QtQuick.Window 2.15
import "elements"

ApplicationWindow {
    id: window
    title: danteMonitor && danteMonitor.fixtureMode ?
           qsTr("Dante Monitoring [FIXTURE]") :
           qsTr("Dante Monitoring")
    width: 600
    height: 580
    minimumWidth: 500
    minimumHeight: 460
    visible: false
    flags: Qt.Window

    color: applicationWindow ? applicationWindow.ui.shell : "#202226"
    font.family: applicationWindow ? applicationWindow.ui.fontFamily : ""
    font.pixelSize: applicationWindow ? applicationWindow.ui.controlFontSize : 13
    Material.theme: applicationAppearance && applicationAppearance.darkMode ? Material.Dark : Material.Light
    Material.accent: applicationWindow ? applicationWindow.ui.primary : "#505D9B"

    function open() {
        show();
        raise();
        requestActivate();
    }

    Shortcut {
        sequence: "Esc"
        onActivated: window.close()
    }

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

    // Helper to build list of adapter names for ComboBox
    function buildAdapterModel() {
        var items = [{ "id": "", "text": qsTr("None / Unassigned") }];
        if (danteMonitor) {
            var list = danteMonitor.availableAdapters;
            for (var i = 0; i < list.length; ++i) {
                var it = list[i];
                var statusStr = it.active ? qsTr("active") : qsTr("no carrier");
                items.push({
                    "id": it.id,
                    "text": qsTr("%1 — %2").arg(it.name).arg(statusStr),
                    "mac": it.mac,
                    "active": it.active
                });
            }
        }
        return items;
    }

    property var adapterModel: buildAdapterModel()

    Connections {
        target: danteMonitor
        function onAdaptersChanged() {
            window.adapterModel = window.buildAdapterModel();
        }
    }

    ScrollView {
        anchors.fill: parent
        anchors.margins: 20
        contentWidth: mainCol.width
        clip: true

        ColumnLayout {
            id: mainCol
            width: window.width - 40
            spacing: 16

            // Header Row
            RowLayout {
                Layout.fillWidth: true
                spacing: 12

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2
                    Text {
                        text: qsTr("Dante Network Monitoring")
                        font.pixelSize: 18
                        font.bold: true
                        color: applicationWindow ? applicationWindow.ui.text : "#F0F2F5"
                    }
                    Text {
                        text: qsTr("Scope: %1").arg(danteMonitor ? danteMonitor.scope : "")
                        font.pixelSize: 12
                        color: applicationWindow ? applicationWindow.ui.secondaryText : "#B7BEC8"
                    }
                }

                // Enable Switch
                RowLayout {
                    spacing: 8
                    Text {
                        text: danteMonitor && danteMonitor.enabled ? qsTr("Enabled") : qsTr("Disabled")
                        font.pixelSize: 13
                        font.bold: true
                        color: danteMonitor && danteMonitor.enabled ? "#2ECC71" :
                               (applicationWindow ? applicationWindow.ui.secondaryText : "#B7BEC8")
                    }
                    Switch {
                        id: enableSwitch
                        checked: danteMonitor ? danteMonitor.enabled : false
                        onToggled: {
                            if (danteMonitor)
                                danteMonitor.enabled = checked;
                        }
                    }
                }
            }

            // Degraded Warning Banner (if any)
            Rectangle {
                visible: danteMonitor && danteMonitor.degradedReason !== "" && danteMonitor.enabled
                Layout.fillWidth: true
                implicitHeight: warningText.implicitHeight + 16
                radius: applicationWindow ? applicationWindow.ui.controlRadius : 6
                color: applicationAppearance && applicationAppearance.darkMode ? "#3D2B1F" : "#FDF2E9"
                border.width: 1
                border.color: "#E67E22"

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 8
                    spacing: 10
                    Rectangle {
                        width: 8; height: 8; radius: 4
                        color: "#E67E22"
                        Layout.alignment: Qt.AlignVCenter
                    }
                    Text {
                        id: warningText
                        Layout.fillWidth: true
                        text: danteMonitor ? danteMonitor.degradedReason : ""
                        wrapMode: Text.WordWrap
                        font.pixelSize: 12
                        color: applicationAppearance && applicationAppearance.darkMode ? "#FAD7A0" : "#784212"
                    }
                }
            }

            // PRIMARY NETWORK CARD
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: primaryCol.implicitHeight + 24
                radius: applicationWindow ? applicationWindow.ui.controlRadius : 6
                color: applicationWindow ? applicationWindow.ui.panel : "#292C31"
                border.width: 1
                border.color: applicationWindow ? applicationWindow.ui.separator : "#41464F"

                ColumnLayout {
                    id: primaryCol
                    anchors.fill: parent
                    anchors.margins: 14
                    spacing: 10

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8
                        Rectangle {
                            width: 10; height: 10; radius: 5
                            color: window.stateColor(danteMonitor ? danteMonitor.primaryRoleState : "Off")
                            Layout.alignment: Qt.AlignVCenter
                        }
                        Text {
                            text: qsTr("Primary Network")
                            font.pixelSize: 14
                            font.bold: true
                            color: applicationWindow ? applicationWindow.ui.text : "#F0F2F5"
                            Layout.fillWidth: true
                        }
                        Text {
                            text: danteMonitor ? danteMonitor.primaryRoleState : ""
                            font.pixelSize: 13
                            font.bold: true
                            color: window.stateColor(danteMonitor ? danteMonitor.primaryRoleState : "Off")
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 12
                        Text {
                            text: qsTr("Interface:")
                            font.pixelSize: 12
                            color: applicationWindow ? applicationWindow.ui.secondaryText : "#B7BEC8"
                            Layout.preferredWidth: 80
                        }
                        ComboBox {
                            id: primaryCombo
                            Layout.fillWidth: true
                            model: window.adapterModel
                            textRole: "text"
                            valueRole: "id"

                            Component.onCompleted: syncIndex()
                            Connections {
                                target: danteMonitor
                                function onConfigChanged() { primaryCombo.syncIndex(); }
                            }
                            function syncIndex() {
                                if (!danteMonitor) return;
                                for (var i = 0; i < count; ++i) {
                                    if (model[i].id === danteMonitor.primaryAdapter) {
                                        currentIndex = i;
                                        return;
                                    }
                                }
                                currentIndex = 0;
                            }
                            onActivated: {
                                if (danteMonitor && currentIndex >= 0) {
                                    danteMonitor.primaryAdapter = model[currentIndex].id;
                                }
                            }
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 12
                        Text {
                            text: qsTr("Status:")
                            font.pixelSize: 12
                            color: applicationWindow ? applicationWindow.ui.secondaryText : "#B7BEC8"
                            Layout.preferredWidth: 80
                        }
                        Text {
                            text: danteMonitor ? danteMonitor.primaryReason : ""
                            font.pixelSize: 12
                            color: applicationWindow ? applicationWindow.ui.text : "#F0F2F5"
                            Layout.fillWidth: true
                        }
                    }
                }
            }

            // SECONDARY NETWORK CARD
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: secondaryCol.implicitHeight + 24
                radius: applicationWindow ? applicationWindow.ui.controlRadius : 6
                color: applicationWindow ? applicationWindow.ui.panel : "#292C31"
                border.width: 1
                border.color: applicationWindow ? applicationWindow.ui.separator : "#41464F"

                ColumnLayout {
                    id: secondaryCol
                    anchors.fill: parent
                    anchors.margins: 14
                    spacing: 10

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8
                        Rectangle {
                            width: 10; height: 10; radius: 5
                            color: window.stateColor(danteMonitor ? danteMonitor.secondaryRoleState : "Off")
                            Layout.alignment: Qt.AlignVCenter
                        }
                        Text {
                            text: qsTr("Secondary Network (Redundancy)")
                            font.pixelSize: 14
                            font.bold: true
                            color: applicationWindow ? applicationWindow.ui.text : "#F0F2F5"
                            Layout.fillWidth: true
                        }
                        Text {
                            text: danteMonitor ? danteMonitor.secondaryRoleState : ""
                            font.pixelSize: 13
                            font.bold: true
                            color: window.stateColor(danteMonitor ? danteMonitor.secondaryRoleState : "Off")
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 12
                        Text {
                            text: qsTr("Interface:")
                            font.pixelSize: 12
                            color: applicationWindow ? applicationWindow.ui.secondaryText : "#B7BEC8"
                            Layout.preferredWidth: 80
                        }
                        ComboBox {
                            id: secondaryCombo
                            Layout.fillWidth: true
                            model: window.adapterModel
                            textRole: "text"
                            valueRole: "id"

                            Component.onCompleted: syncIndex()
                            Connections {
                                target: danteMonitor
                                function onConfigChanged() { secondaryCombo.syncIndex(); }
                            }
                            function syncIndex() {
                                if (!danteMonitor) return;
                                for (var i = 0; i < count; ++i) {
                                    if (model[i].id === danteMonitor.secondaryAdapter) {
                                        currentIndex = i;
                                        return;
                                    }
                                }
                                currentIndex = 0;
                            }
                            onActivated: {
                                if (danteMonitor && currentIndex >= 0) {
                                    danteMonitor.secondaryAdapter = model[currentIndex].id;
                                }
                            }
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 12
                        Text {
                            text: qsTr("Status:")
                            font.pixelSize: 12
                            color: applicationWindow ? applicationWindow.ui.secondaryText : "#B7BEC8"
                            Layout.preferredWidth: 80
                        }
                        Text {
                            text: danteMonitor ? danteMonitor.secondaryReason : ""
                            font.pixelSize: 12
                            color: applicationWindow ? applicationWindow.ui.text : "#F0F2F5"
                            Layout.fillWidth: true
                        }
                    }
                }
            }

            // DANTE LOCAL TELEMETRY & SERVICES
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: telemetryCol.implicitHeight + 24
                radius: applicationWindow ? applicationWindow.ui.controlRadius : 6
                color: applicationWindow ? applicationWindow.ui.panel : "#292C31"
                border.width: 1
                border.color: applicationWindow ? applicationWindow.ui.separator : "#41464F"

                ColumnLayout {
                    id: telemetryCol
                    anchors.fill: parent
                    anchors.margins: 14
                    spacing: 8

                    Text {
                        text: qsTr("Dante Services & Discovery")
                        font.pixelSize: 14
                        font.bold: true
                        color: applicationWindow ? applicationWindow.ui.text : "#F0F2F5"
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8
                        Text {
                            text: qsTr("Local Service Provider:")
                            font.pixelSize: 12
                            color: applicationWindow ? applicationWindow.ui.secondaryText : "#B7BEC8"
                            Layout.preferredWidth: 160
                        }
                        Text {
                            text: danteMonitor ? danteMonitor.providerStatus : ""
                            font.pixelSize: 12
                            color: applicationWindow ? applicationWindow.ui.text : "#F0F2F5"
                            Layout.fillWidth: true
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8
                        Text {
                            text: qsTr("Network Devices:")
                            font.pixelSize: 12
                            color: applicationWindow ? applicationWindow.ui.secondaryText : "#B7BEC8"
                            Layout.preferredWidth: 160
                        }
                        Text {
                            text: danteMonitor ? danteMonitor.networkDiscoveryState : ""
                            font.pixelSize: 12
                            color: applicationWindow ? applicationWindow.ui.text : "#F0F2F5"
                            Layout.fillWidth: true
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8
                        Text {
                            text: qsTr("Last Observation:")
                            font.pixelSize: 12
                            color: applicationWindow ? applicationWindow.ui.secondaryText : "#B7BEC8"
                            Layout.preferredWidth: 160
                        }
                        Text {
                            text: danteMonitor ? danteMonitor.lastObservationTime : ""
                            font.pixelSize: 12
                            color: applicationWindow ? applicationWindow.ui.text : "#F0F2F5"
                            Layout.fillWidth: true
                        }
                    }
                }
            }

            Item { Layout.fillHeight: true }

            // ACTION BUTTONS
            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                StudioButton {
                    text: qsTr("Auto-detect")
                    onClicked: {
                        if (danteMonitor)
                            danteMonitor.autodetectFromController();
                    }
                }

                StudioButton {
                    text: qsTr("Refresh")
                    onClicked: {
                        if (danteMonitor)
                            danteMonitor.refresh();
                    }
                }

                Item { Layout.fillWidth: true }

                StudioButton {
                    text: qsTr("Close")
                    highlighted: true
                    onClicked: window.close()
                }
            }
        }
    }
}
