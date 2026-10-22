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
import QtQuick 2.12
import QtQuick.Layouts 1.3
import QtQuick.Controls 2.15 as Controls
import QtQuick.Controls 1.4
import QtQuick.Dialogs 1.2 as Dialogs
import Stored 1.0
import "elements"

Item {
    id: chartsLayout
    property int count: applicationSettings.value("layout/charts/count", 1)
    property alias rtaItem: rtaLoader.item
    property bool sidebarOpen: false
    property int captureNumber: 1
    property string selectedCapture: ""
    property var selectedCaptures: []
    property string captureError: ""

    function capture() {
        var live = sourceList.selected;
        if (!live || live.objectName !== "Measurement") { captureError = qsTr("Select a live measurement source first."); return; }
        if (live.error || !live.inputAvailable) { captureError = qsTr("The selected source has no live audio input. Check the device, then press Start."); return; }
        if (!live.frequencyDomainCount || live.frequencyDomainCount < 2) { captureError = qsTr("No valid frequency data is available yet."); return; }
        var stored = live.store();
        if (!stored) { captureError = qsTr("Capture failed."); return; }
        stored.name = live.name + " " + new Date().toLocaleTimeString(Qt.locale(), "HH:mm:ss");
        stored.color = sourceList.nextColor();
        stored.active = true;
        stored.captureType = captureTypeSelection.currentText;
        stored.capturedAt = new Date().toISOString();
        sourceList.appendItem(stored, false);
        selectedCapture = stored.uuid.toString();
        selectedCaptures = [stored.uuid];
        captureError = "";
        Qt.callLater(function() { renameField.forceActiveFocus(); renameField.selectAll(); });
    }
    function applySelectedTraces() {
        var live = sourceList.selected;
        function update(chart) {
            if (!chart || !chart.plot) return;
            var ids = [];
            for (var i = 0; i < selectedCaptures.length; ++i) {
                var saved = sourceList.getByUUid(selectedCaptures[i]);
                if (!saved || saved.objectName !== "Stored") continue;
                var spectrum = saved.captureType === "Spectrum";
                if ((spectrum && chart.type === "Spectrum") || (!spectrum && chart.type !== "Spectrum")) ids.push(saved.uuid);
            }
            if (live && live.objectName === "Measurement") ids.push(live.uuid);
            chart.plot.selected = ids;
        }
        update(first); update(second.visible ? second : null); update(third.visible ? third : null);
    }
    function isStored(source) { return source && source.objectName === "Stored"; }
    function toggleCaptureSelection(uuid, modifiers) {
        var values = selectedCaptures.slice(0);
        var index = values.indexOf(uuid);
        if (modifiers & Qt.ControlModifier || modifiers & Qt.ShiftModifier) {
            if (index >= 0) values.splice(index, 1); else values.push(uuid);
        } else values = [uuid];
        selectedCaptures = values;
        selectedCapture = uuid.toString();
        applySelectedTraces();
    }
    function averageSelection() {
        var ids = [];
        for (var i = 0; i < selectedCaptures.length; ++i) ids.push(selectedCaptures[i]);
        var error = "";
        var result = sourceList.averageStoredResult(ids, qsTr("Average (%1)").arg(ids.length));
        var avg = result.source;
        error = result.error;
        if (!avg) { captureError = error || qsTr("Could not average these traces."); return; }
        selectedCaptures = [avg.uuid]; selectedCapture = avg.uuid.toString();
        applySelectedTraces(); captureError = "";
    }

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

    property real delayCursorFrequency: 0

    Flow {
        id: alignmentToolbar
        anchors.top: parent.top
        anchors.topMargin: applicationWindow.ui.spacing
        x: applicationWindow.ui.spacing
        width: parent.width - 2 * applicationWindow.ui.spacing
        spacing: applicationWindow.ui.spacing

        StudioButton {
            id: workspaceAction
            height: applicationWindow.ui.controlHeight + 8
            text: chartsLayout.rtaWorkspace ? qsTr("Return to chart layout") : qsTr("RTA")
            onClicked: chartsLayout.rtaWorkspace = !chartsLayout.rtaWorkspace
        }
        StudioButton {
            id: captureToggle
            height: workspaceAction.height
            text: chartsLayout.sidebarOpen ? qsTr("Hide traces") : qsTr("Traces")
            onClicked: chartsLayout.sidebarOpen = !chartsLayout.sidebarOpen
        }
        DelayFinder {
            surfaceColor: applicationWindow.ui.panel
            textColor: applicationWindow.ui.text
            outlineColor: applicationWindow.ui.separator
            width: Math.min(implicitWidth, alignmentToolbar.width)
            visible: !chartsLayout.rtaWorkspace
            measurement: sourceList.selected && sourceList.selected.objectName === "Measurement" ? sourceList.selected.data : null
            cursorFrequency: chartsLayout.delayCursorFrequency
        }
    }
    SplitView {
        id: chartArea
        anchors.top: alignmentToolbar.bottom
        anchors.topMargin: applicationWindow.ui.spacing
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        orientation: Qt.Horizontal
        visible: !chartsLayout.rtaWorkspace
        Item {
            id: captureSidebar
            visible: chartsLayout.sidebarOpen
            onWidthChanged: applicationSettings.setValue("layout/chartCapture/sidebarWidth", width)
            Layout.preferredWidth: applicationSettings.value("layout/chartCapture/sidebarWidth", 276)
            Layout.minimumWidth: 230
            Layout.maximumWidth: 420
            Layout.fillHeight: true
            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 10
                spacing: 8
                RowLayout {
                    Layout.fillWidth: true
                    Controls.ComboBox {
                        id: captureTypeSelection
                        model: ["Magnitude", "Spectrum", "Phase"]
                        currentIndex: model.indexOf(first.type === "Spectrum" ? "Spectrum" : first.type === "Phase" ? "Phase" : "Magnitude")
                        Controls.ToolTip.visible: hovered; Controls.ToolTip.text: qsTr("Capture magnitude, spectrum, or phase data")
                    }
                    Controls.Button { text: qsTr("Capture"); highlighted: true; Controls.ToolTip.visible: hovered; Controls.ToolTip.text: qsTr("Capture the selected live trace (%1)").arg(applicationWindow.shortcutRegistry.display("charts.capture")); onClicked: chartsLayout.capture() }
                    Controls.Button { text: qsTr("Average selected"); enabled: chartsLayout.selectedCaptures.length > 1; Controls.ToolTip.visible: hovered; Controls.ToolTip.text: qsTr("Create a new linear-amplitude and complex-phase average"); onClicked: chartsLayout.averageSelection() }
                }
                Controls.Label { Layout.fillWidth: true; text: qsTr("Saved traces"); font.bold: true }
                Controls.Label { Layout.fillWidth: true; visible: captureError.length > 0; text: captureError; color: "#D94F4F"; wrapMode: Text.Wrap }
                Controls.Label { Layout.fillWidth: true; visible: !hasStored; text: qsTr("No captures yet. Select a live measurement and press Capture."); color: applicationWindow.ui.secondaryText; wrapMode: Text.Wrap }
                ListView {
                    id: captureList
                    Layout.fillWidth: true; Layout.fillHeight: true
                    clip: true; spacing: 4
                    model: sourceList.count
                    delegate: Item {
                        id: row
                        required property int index
                        property var itemSource: sourceList.get(index)
                        visible: chartsLayout.isStored(itemSource)
                        width: captureList.width; height: visible ? 76 : 0
                        Rectangle {
                            anchors.fill: parent; radius: 5
                            color: selectedCapture === itemSource.uuid.toString() ? applicationWindow.ui.hover : "transparent"
                            border.width: chartsLayout.selectedCaptures.indexOf(itemSource.uuid) >= 0 ? 1 : 0
                            border.color: itemSource.color
                        }
                        MouseArea { anchors.fill: parent; acceptedButtons: Qt.LeftButton; onClicked: chartsLayout.toggleCaptureSelection(itemSource.uuid, mouse.modifiers); onDoubleClicked: { chartsLayout.toggleCaptureSelection(itemSource.uuid, Qt.NoModifier); renameField.forceActiveFocus(); renameField.selectAll(); } }
                        Rectangle { x: 8; y: 12; width: 12; height: 12; radius: 6; color: itemSource.color }
                        Controls.CheckBox { x: 24; y: 1; checked: itemSource.active; text: itemSource.name; width: parent.width - 30; onClicked: itemSource.active = checked; Controls.ToolTip.visible: hovered; Controls.ToolTip.text: qsTr("Show or hide this trace") }
                        Controls.Label { x: 34; y: 35; text: (itemSource.captureType || "Magnitude") + (itemSource.contributors ? qsTr(" · average of %1").arg(itemSource.contributors.split("\n").length) : ""); color: applicationWindow.ui.secondaryText; font.pixelSize: 11 }
                        Controls.Button { x: parent.width - 42; y: 32; width: 36; height: 30; text: "⋯"; Controls.ToolTip.visible: hovered; Controls.ToolTip.text: qsTr("Rename, recolor, or delete"); onClicked: { chartsLayout.selectedCapture = itemSource.uuid.toString(); chartsLayout.selectedCaptures = [itemSource.uuid]; actionMenu.open(); } }
                    }
                    property bool hasStored: {
                        for (var i = 0; i < sourceList.count; ++i) if (chartsLayout.isStored(sourceList.get(i))) return true;
                        return false;
                    }
                }
                Controls.TextField { id: renameField; Layout.fillWidth: true; placeholderText: qsTr("Selected trace name"); enabled: !!sourceList.getByUUid(chartsLayout.selectedCapture); text: enabled ? sourceList.getByUUid(chartsLayout.selectedCapture).name : ""; onEditingFinished: { var s = sourceList.getByUUid(chartsLayout.selectedCapture); if (s && text.trim().length) s.name = text.trim(); } }
                RowLayout {
                    Layout.fillWidth: true
                    Repeater {
                        model: ["#F44336", "#FFEB3B", "#9C27B0", "#2196F3", "#00BCD4", "#4CAF50", "#FF9800"]
                        delegate: Rectangle { required property string modelData; width: 20; height: 20; radius: 10; color: modelData; border.color: "#777"; MouseArea { anchors.fill: parent; onClicked: { var s = sourceList.getByUUid(chartsLayout.selectedCapture); if (s) s.color = parent.color; } } }
                    }
                    Item { Layout.fillWidth: true }
                    Controls.Button { text: qsTr("Delete"); enabled: !!sourceList.getByUUid(chartsLayout.selectedCapture); onClicked: deleteDialog.open() }
                }
            }
            Controls.Menu { id: actionMenu
                Controls.MenuItem { text: qsTr("Rename in field below") }
                Controls.MenuItem { text: qsTr("Delete…"); onTriggered: deleteDialog.open() }
            }
            ModalDialog { id: deleteDialog; title: qsTr("Delete saved trace?"); detail: qsTr("This removes the trace from the current session."); onOpened: acceptText = qsTr("Delete"); onAccepted: { var removed = sourceList.getByUUid(chartsLayout.selectedCapture); if (removed) { sourceList.removeItem(chartsLayout.selectedCapture); chartsLayout.selectedCaptures = []; chartsLayout.selectedCapture = ""; chartsLayout.applySelectedTraces(); applicationWindow.showUndoableRemoval(sourceList, qsTr("%1 removed").arg(removed.name), function() { chartsLayout.selectedCapture = removed.uuid.toString(); chartsLayout.selectedCaptures = [removed.uuid]; chartsLayout.applySelectedTraces(); }); } } }
        }
        SplitView {
            id: sv
            orientation: Qt.Vertical
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.minimumWidth: 300
            readonly property int minimunHeight: 100
            Chart {
                id: first
                Layout.fillWidth: true; Layout.minimumHeight: 100; Layout.fillHeight: true
                height: applicationSettings.value("layout/charts/1/height")
                onHeightChanged: applicationSettings.setValue("layout/charts/1/height", height)
                type: applicationSettings.value("layout/charts/1/type", "Spectrum")
                onTypeChanged: applicationSettings.setValue("layout/charts/1/type", type)
                onFrequencyCursorMoved: chartsLayout.delayCursorFrequency = frequency
                onPlotChanged: Qt.callLater(function() { chartsLayout.applyDefaults(first); chartsLayout.applySelectedTraces(); })
                Component.onCompleted: { settings = applicationSettings.getGroup("layout/charts/1"); Qt.callLater(function() { chartsLayout.applyDefaults(first); chartsLayout.applySelectedTraces(); }); }
            }
            Chart {
                id: second; visible: chartsLayout.count > 1
                Layout.fillWidth: true; Layout.minimumHeight: 100; Layout.fillHeight: true
                height: applicationSettings.value("layout/charts/2/height")
                onHeightChanged: applicationSettings.setValue("layout/charts/2/height", height)
                type: applicationSettings.value("layout/charts/2/type", "Spectrum")
                onTypeChanged: applicationSettings.setValue("layout/charts/2/type", type)
                onFrequencyCursorMoved: chartsLayout.delayCursorFrequency = frequency
                onPlotChanged: Qt.callLater(function() { chartsLayout.applyDefaults(second); chartsLayout.applySelectedTraces(); })
                Component.onCompleted: { settings = applicationSettings.getGroup("layout/charts/2"); Qt.callLater(function() { chartsLayout.applyDefaults(second); chartsLayout.applySelectedTraces(); }); }
            }
            Chart {
                id: third; visible: chartsLayout.count > 2
                Layout.fillWidth: true; Layout.minimumHeight: 100; Layout.fillHeight: true
                height: applicationSettings.value("layout/charts/3/height")
                onHeightChanged: applicationSettings.setValue("layout/charts/3/height", height)
                type: applicationSettings.value("layout/charts/3/type", "Spectrum")
                onTypeChanged: applicationSettings.setValue("layout/charts/3/type", type)
                onFrequencyCursorMoved: chartsLayout.delayCursorFrequency = frequency
                onPlotChanged: Qt.callLater(function() { chartsLayout.applyDefaults(third); chartsLayout.applySelectedTraces(); })
                Component.onCompleted: { settings = applicationSettings.getGroup("layout/charts/3"); Qt.callLater(function() { chartsLayout.applyDefaults(third); chartsLayout.applySelectedTraces(); }); }
            }
            SystemPalette { id: pal }
            handleDelegate: Rectangle { width: 1; height: 1; color: Qt.darker(pal.window, 1.5); MouseArea { anchors.fill: parent; propagateComposedEvents: true; onDoubleClicked: chartsLayout.autoHeight() } }
        }
    }

    Rectangle {
        id: emptyWorkspace
        anchors.fill: chartArea
        z: 2
        visible: chartArea.visible && sourceList.count === 0
        color: applicationWindow.ui.panel
        opacity: 0.96

        ColumnLayout {
            anchors.centerIn: parent
            width: Math.min(parent.width - 32, 320)
            spacing: 10
            Controls.Label {
                Layout.fillWidth: true
                text: qsTr("No measurements in this workspace.")
                color: applicationWindow.ui.secondaryText
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.Wrap
            }
            Controls.Button {
                Layout.alignment: Qt.AlignHCenter
                text: qsTr("Add Measurement")
                highlighted: true
                onClicked: sourceList.addMeasurement()
            }
            Controls.Button {
                Layout.alignment: Qt.AlignHCenter
                text: qsTr("Open Project")
                onClicked: openDialog.open()
            }
        }
    }

    Shortcut { sequence: applicationWindow.shortcutRegistry.sequence("charts.capture"); context: Qt.ApplicationShortcut; enabled: !chartsLayout.rtaWorkspace && !applicationWindow.textEntryFocused; onActivated: chartsLayout.capture() }
    Loader {
        id: rtaLoader
        anchors.top: alignmentToolbar.bottom
        anchors.topMargin: applicationWindow.ui.spacing
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

    Connections { target: sourceList; function onPostItemAppended(item) { if (item && item.objectName === "Stored") { selectedCapture = item.uuid.toString(); selectedCaptures = [item.uuid]; Qt.callLater(applySelectedTraces); } } }

}
