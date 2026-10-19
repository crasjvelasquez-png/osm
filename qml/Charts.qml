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
import QtQuick.Controls 1.4 //SplitView needs exactly 1.4
import QtQuick.Layouts 1.3
import QtQuick.Controls 2.15 as Controls

Item {
    id: chartsLayout
    property int count: applicationSettings.value("layout/charts/count", 1)
    property alias rtaItem: rtaLoader.item

    function magnitudePlot() {
        if (first.type === "Magnitude") return first.plot;
        if (second.visible && second.type === "Magnitude") return second.plot;
        if (third.visible && third.type === "Magnitude") return third.plot;
        return null;
    }
    function spectrumPlot() {
        if (rtaLoader.item && rtaLoader.item.spectrum) return rtaLoader.item.spectrum;
        if (first.type === "Spectrum") return first.plot;
        if (second.visible && second.type === "Spectrum") return second.plot;
        if (third.visible && third.type === "Spectrum") return third.plot;
        return null;
    }
    function applyDefaults(chart) {
        if (!chart || !chart.plot) return;
        if (chart.type === "Magnitude") defaultsController.applyPlotDefaults(chart.plot, "magnitude");
        else if (chart.type === "Spectrum") defaultsController.applyPlotDefaults(chart.plot, "rta");
    }

    property bool rtaWorkspace: applicationSettings.value("rta/workspace", false)
    Connections {
        target: sourceList
        // Session files do not opt into a new workspace or change their format.
        function onLoaded() { chartsLayout.rtaWorkspace = false; }
    }
    onRtaWorkspaceChanged: applicationSettings.setValue("rta/workspace", rtaWorkspace)

    Controls.Button {
        id: workspaceAction
        anchors.top: parent.top
        anchors.left: parent.left
        text: chartsLayout.rtaWorkspace ? qsTr("Return to chart layout") : qsTr("RTA")
        onClicked: chartsLayout.rtaWorkspace = !chartsLayout.rtaWorkspace
    }
    Loader {
        id: rtaLoader
        anchors.top: workspaceAction.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        active: chartsLayout.rtaWorkspace
        source: "qrc:/RTAWorkspace.qml"
    }

    Component.onCompleted: {
        chartsLayout.onCountChanged.connect(updateCount);
    }

    function autoHeight() {
        first.height = second.height = third.height = chartsLayout.height / count;
    }

    function updateCount() {
        autoHeight();
        applicationSettings.setValue("layout/charts/count", count)
    }

    SplitView {
        id: sv
        anchors.top: workspaceAction.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        visible: !chartsLayout.rtaWorkspace
        orientation: Qt.Vertical
        readonly property int minimunHeight: 100

         Chart {
             id: first
             Layout.fillWidth: true
             Layout.minimumHeight: sv.minimunHeight
             Layout.preferredWidth: parent.width
             Layout.fillHeight: true
             height: applicationSettings.value("layout/charts/1/height")
             onHeightChanged: applicationSettings.setValue("layout/charts/1/height", height)
             type: applicationSettings.value("layout/charts/1/type", "Spectrum")
             onTypeChanged: applicationSettings.setValue("layout/charts/1/type", type)
             onPlotChanged: Qt.callLater(function() { chartsLayout.applyDefaults(first); })

             Component.onCompleted: {
                 settings = applicationSettings.getGroup("layout/charts/1");
                 Qt.callLater(function() { chartsLayout.applyDefaults(first); });
             }
         }

         Chart {
             id: second
             visible: chartsLayout.count > 1
             Layout.fillWidth: true
             Layout.minimumHeight: sv.minimunHeight
             Layout.preferredWidth: parent.width
             height: applicationSettings.value("layout/charts/2/height")
             onHeightChanged: applicationSettings.setValue("layout/charts/2/height", height)
             type: applicationSettings.value("layout/charts/2/type", "Spectrum")
             onTypeChanged: applicationSettings.setValue("layout/charts/2/type", type)
             onPlotChanged: Qt.callLater(function() { chartsLayout.applyDefaults(second); })

             Component.onCompleted: {
                 settings = applicationSettings.getGroup("layout/charts/2");
                 Qt.callLater(function() { chartsLayout.applyDefaults(second); });
             }
         }

         Chart {
             id: third
             visible: chartsLayout.count > 2
             Layout.fillWidth: true
             Layout.minimumHeight: sv.minimunHeight
             Layout.preferredWidth: parent.width
             height: applicationSettings.value("layout/charts/3/height")
             onHeightChanged: applicationSettings.setValue("layout/charts/3/height", height)
             type: applicationSettings.value("layout/charts/3/type", "Spectrum")
             onTypeChanged: applicationSettings.setValue("layout/charts/3/type", type)
             onPlotChanged: Qt.callLater(function() { chartsLayout.applyDefaults(third); })

             Component.onCompleted: {
                 settings = applicationSettings.getGroup("layout/charts/3");
                 Qt.callLater(function() { chartsLayout.applyDefaults(third); });
             }
         }

         SystemPalette { id: pal }
         handleDelegate: Rectangle {
             width: 1
             height: 1
             color: Qt.darker(pal.window, 1.5)

             MouseArea {
                 anchors.fill: parent
                 propagateComposedEvents: true
                 onDoubleClicked: {
                     autoHeight();
                 }
             }
         }
     }

}
