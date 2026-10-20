/* Dedicated spectrum workspace; analysis remains owned by the selected source. */
import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Controls.Material 2.15
import QtQuick.Layouts 1.3
import Audio 1.0
import "elements"

Item {
    id: workspace
    property var selected: sourceList.selected
    readonly property var measurement: selected && selected.objectName === "Measurement" ? selected.data : null
    readonly property var spectrum: graph.plot
    property bool initialized: false
    property bool showHeatmap: applicationSettings.value("rta/heatmap", true)
    property bool showControls: true
    onShowHeatmapChanged: applicationSettings.setValue("rta/heatmap", showHeatmap)
    property int deviceRevision: 0
    readonly property int deviceIndex: {
        deviceRevision;
        return measurement ? devices.indexOf(measurement.deviceId) : -1;
    }
    readonly property var channels: {
        var names = deviceIndex >= 0 ? devices.channelNames(deviceIndex) : [];
        if (deviceIndex >= 0) names.push(qsTr("Loop"));
        return names;
    }
    readonly property bool available: measurement && deviceIndex >= 0 &&
        measurement.dataChanel >= 0 && measurement.dataChanel < channels.length
    readonly property string stateText: !measurement ? qsTr("Select a measurement in the source list") :
        !available ? qsTr("Input unavailable — select a device or reconnect it") :
        measurement.error ? qsTr("Input unavailable — check microphone permission in System Settings or device access, then press Start") :
        !measurement.active ? qsTr("Stopped — displayed trace is held") :
        !measurement.inputAvailable ? qsTr("Waiting for audio — displayed trace is held") : qsTr("Running • dBFS")

    Component.onCompleted: {
        var savedId = applicationSettings.value("rta/selectedSource", "");
        if (savedId) {
            var restored = sourceList.getByUUid(savedId);
            if (restored && restored.data) sourceList.selectedIndex = sourceList.indexOf(restored);
        }
        initialized = true;
        followSource();
        if (defaultsController.hasSavedDefaults) {
            showHeatmap = defaultsController.value("rta/heatmap", true);
            defaultsController.applyPlotDefaults(spectrum, "rta");
        }
    }

    onSelectedChanged: {
        if (initialized && selected && selected.data) applicationSettings.setValue("rta/selectedSource", selected.uuid);
    }

    function followSource() {
        if (spectrum) spectrum.selected = selected && selected.data ? [selected.uuid] : [];
        if (heatmap.item && heatmap.item.plot) heatmap.item.plot.selected = selected && selected.data ? [selected.uuid] : [];
    }

    DeviceModel {
        id: devices
        scope: DeviceModel.InputOnly
    }
    Connections {
        target: devices
        function onModelReset() { workspace.deviceRevision++; }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 8
        spacing: 4
        Flow {
            Layout.fillWidth: true
            Layout.preferredHeight: childrenRect.height
            spacing: 8
            Label {
                width: Math.min(260, parent.width)
                height: controlsAction.height
                verticalAlignment: Text.AlignVCenter
                text: qsTr("RTA / Spectrum") + (workspace.measurement ? " — " + workspace.measurement.name : "")
                font.bold: true
                elide: Text.ElideRight
            }
            Button {
                id: controlsAction
                font.capitalization: Font.MixedCase
                text: workspace.showControls ? qsTr("Hide controls") : qsTr("Input & display")
                onClicked: workspace.showControls = !workspace.showControls
            }
            CheckBox {
                text: qsTr("Heatmap")
                checked: workspace.showHeatmap
                onClicked: workspace.showHeatmap = checked
            }
        }
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: statusLabel.implicitHeight + 16
            radius: 6
            color: applicationWindow.ui.panel
            border.color: workspace.measurement && (!workspace.available || workspace.measurement.error) ?
                Material.color(Material.Orange) : applicationWindow.ui.separator
            Label {
                id: statusLabel
                anchors.fill: parent
                anchors.margins: 8
                text: workspace.stateText
                color: workspace.measurement && (!workspace.available || workspace.measurement.error) ?
                    Material.color(Material.Orange) : applicationWindow.ui.secondaryText
                wrapMode: Text.WordWrap
                verticalAlignment: Text.AlignVCenter
            }
        }
        ScrollView {
            Layout.fillWidth: true
            visible: workspace.showControls
            Layout.preferredHeight: Math.min(240, workspace.height * 0.32)
            clip: true
            contentWidth: availableWidth
            contentHeight: controls.implicitHeight
            ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
            ColumnLayout {
                id: controls
                width: Math.max(0, workspace.width - 32)
        // Flow wraps complete controls instead of clipping long device names.
        Flow {
            Layout.fillWidth: true
            Layout.preferredHeight: childrenRect.height
            spacing: 8
            Column {
                width: Math.min(240, parent.width); spacing: 4
                Label { text: qsTr("Device"); font.pixelSize: 12; color: applicationWindow.ui.secondaryText }
                TitledCombo {
                    width: parent.width; height: 36; showTitleInValue: false
                    title: qsTr("Device"); model: devices; textRole: "name"
                    currentIndex: workspace.deviceIndex
                    enabled: !!workspace.measurement
                    onActivated: workspace.measurement.deviceId = devices.deviceId(index)
                    tooltip: currentText
                }
            }
            Column {
                width: Math.min(96, parent.width); spacing: 4
                Label { text: qsTr("Input"); font.pixelSize: 12; color: applicationWindow.ui.secondaryText }
                TitledCombo {
                    width: parent.width; height: 36; showTitleInValue: false
                    title: qsTr("Input"); model: workspace.channels
                    currentIndex: workspace.measurement ? workspace.measurement.dataChanel : -1
                    enabled: !!workspace.measurement && workspace.deviceIndex >= 0
                    onActivated: workspace.measurement.dataChanel = index
                }
            }
            Column {
                width: Math.min(144, parent.width); spacing: 4
                Label { text: qsTr("Input meter • dBFS"); font.pixelSize: 12; color: applicationWindow.ui.secondaryText }
                Item {
                    width: parent.width; height: 36
                    Meter {
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width; height: 8
                        dBV: workspace.available && workspace.measurement.active && workspace.measurement.inputAvailable && !workspace.measurement.error ? workspace.measurement.level : -90
                        peak: workspace.available && workspace.measurement.active && workspace.measurement.inputAvailable && !workspace.measurement.error ? workspace.measurement.measurementPeak : -90
                    }
                }
            }
            Column {
                width: Math.min(72, parent.width); spacing: 4
                Label { text: qsTr("Capture"); font.pixelSize: 12; color: applicationWindow.ui.secondaryText }
                Button {
                    width: parent.width; height: 36
                    font.capitalization: Font.MixedCase
                    text: workspace.measurement && workspace.measurement.active ? qsTr("Stop") : qsTr("Start")
                    enabled: !!workspace.measurement && (workspace.available || workspace.measurement.active)
                    onClicked: workspace.measurement.active = !workspace.measurement.active
                }
            }
            Column {
                width: Math.min(168, parent.width); spacing: 4
                Label { text: qsTr("Settings"); font.pixelSize: 12; color: applicationWindow.ui.secondaryText }
                Button {
                    width: parent.width; height: 36
                    font.pixelSize: 12
                    font.capitalization: Font.MixedCase
                    text: qsTr("Measurement settings")
                    enabled: !!workspace.measurement
                    onClicked: applicationWindow.properiesbar.open(workspace.selected, "qrc:/source/MeasurementProperties.qml")
                }
            }
        }
        Flow {
            Layout.fillWidth: true
            Layout.preferredHeight: childrenRect.height
            spacing: 8
            Column {
                width: Math.min(144, parent.width); spacing: 4
                Label { text: qsTr("Display"); font.pixelSize: 12; color: applicationWindow.ui.secondaryText }
                TitledCombo {
                    width: parent.width; height: 36; showTitleInValue: false
                    title: qsTr("Display")
                    model: [qsTr("Line"), qsTr("Bars"), qsTr("Lines")]
                    currentIndex: workspace.spectrum ? workspace.spectrum.mode : 0
                    onActivated: {
                        workspace.spectrum.mode = index;
                        if (index === 1 && workspace.spectrum.pointsPerOctave === 0)
                            workspace.spectrum.pointsPerOctave = 12;
                    }
                }
            }
            Column {
                width: Math.min(176, parent.width); spacing: 4
                Label { text: qsTr("Resolution"); font.pixelSize: 12; color: applicationWindow.ui.secondaryText }
                TitledCombo {
                    width: parent.width; height: 36; showTitleInValue: false
                    title: qsTr("Resolution")
                    property var values: [1, 3, 6, 12, 24, 48, 0]
                    model: [qsTr("1 octave"), qsTr("1/3 octave"), qsTr("1/6 octave"), qsTr("1/12 octave"), qsTr("1/24 octave"), qsTr("1/48 octave"), qsTr("FFT bins")]
                    currentIndex: workspace.spectrum ? values.indexOf(workspace.spectrum.pointsPerOctave) : -1
                    enabled: workspace.spectrum && workspace.spectrum.mode !== 2
                    onActivated: {
                        workspace.spectrum.pointsPerOctave = values[index];
                        if (values[index] === 0 && workspace.spectrum.mode === 1) workspace.spectrum.mode = 0;
                    }
                }
            }
            Column {
                width: Math.min(260, parent.width); spacing: 4
                Label { text: qsTr("Average"); font.pixelSize: 12; color: applicationWindow.ui.secondaryText }
                TitledCombo {
                    width: parent.width; height: 36; showTitleInValue: false
                    title: qsTr("Average")
                    model: [qsTr("Off"), qsTr("Low-pass smoothing (LPF)"), qsTr("Rolling frames (FIFO)")]
                    currentIndex: workspace.measurement ? workspace.measurement.averageType : -1
                    enabled: !!workspace.measurement
                    onActivated: workspace.measurement.averageType = index
                }
            }
            Column {
                width: Math.min(144, parent.width); spacing: 4
                visible: workspace.measurement && workspace.measurement.averageType === 1
                Label { text: qsTr("LPF"); font.pixelSize: 12; color: applicationWindow.ui.secondaryText }
                TitledCombo {
                    width: parent.width; height: 36; showTitleInValue: false
                    title: qsTr("LPF"); model: ["0.25 Hz", "0.5 Hz", "1 Hz"]
                    currentIndex: workspace.measurement ? workspace.measurement.filtersFrequency : -1
                    onActivated: workspace.measurement.filtersFrequency = index
                }
            }
            Column {
                width: Math.min(144, parent.width); spacing: 4
                visible: workspace.measurement && workspace.measurement.averageType === 2
                Label { text: qsTr("FIFO frames"); font.pixelSize: 12; color: applicationWindow.ui.secondaryText }
                SelectableSpinBox {
                    width: parent.width; height: 36
                    from: 1; to: 100; editable: true
                    value: workspace.measurement ? workspace.measurement.average : 1
                    onValueModified: workspace.measurement.average = value
                    ToolTip.visible: hovered
                    ToolTip.text: qsTr("Number of frames in the rolling average")
                }
            }
            CheckBox {
                text: qsTr("Hold peaks")
                enabled: workspace.spectrum && workspace.spectrum.mode !== 0
                checked: workspace.spectrum ? workspace.spectrum.showPeaks : false
                onClicked: workspace.spectrum.showPeaks = checked
            }
        }
        CheckBox {
            text: qsTr("Smooth trace motion")
            checked: workspace.spectrum ? workspace.spectrum.smooth : true
            onClicked: {
                workspace.spectrum.smooth = checked;
                applicationSettings.setValue("rta/smooth", checked);
            }
        }
        Label {
            text: qsTr("Averaging affects all plots using this measurement. Microphone correction is not SPL calibration.")
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
            font.pixelSize: 12
            color: applicationWindow.ui.secondaryText
        }
            }
        }
        Chart {
            id: graph
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.minimumHeight: 120
            Layout.preferredHeight: workspace.height * 0.65
            typeLocked: true
            Connections {
                target: sourceList
                function onSelectedChanged() { workspace.followSource(); }
            }
            Component.onCompleted: {
                applicationSettings.setValue("rta/chart/type", "Spectrum");
                settings = applicationSettings.getGroup("rta/chart");
                plot.smooth = applicationSettings.value("rta/smooth", true);
                if (!applicationSettings.value("rta/displayInitialized", false)) {
                    plot.pointsPerOctave = 12;
                    plot.ymin = -100;
                    plot.ymax = 0;
                    applicationSettings.setValue("rta/displayInitialized", true);
                }
                workspace.followSource();
            }
        }
        RowLayout {
            visible: workspace.showHeatmap
            Layout.fillWidth: true
            Label { text: qsTr("Heatmap · last 4 seconds"); font.bold: true; Layout.fillWidth: true }
            Label { text: qsTr("Quiet  −100"); font.pixelSize: 12 }
            Rectangle {
                width: 100; height: 8
                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop { position: 0; color: "#2196F3" }
                    GradientStop { position: 0.5; color: "#8BC34A" }
                    GradientStop { position: 1; color: "#F44336" }
                }
            }
            Label { text: qsTr("−20 dBFS  Loud"); font.pixelSize: 12 }
        }
        Loader {
            id: heatmap
            active: workspace.showHeatmap
            visible: active
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.preferredHeight: workspace.height * 0.28
            sourceComponent: Component {
                Chart {
                    typeLocked: true
                    spacePausesHeatmap: true
                    Component.onCompleted: {
                        type = "Spectrogram";
                        applicationSettings.setValue("rta/heatmapChart/type", "Spectrogram");
                        settings = applicationSettings.getGroup("rta/heatmapChart");
                        if (!applicationSettings.value("rta/historyInitialized", false)) {
                            plot.pointsPerOctave = 24;
                            plot.min = -100; plot.mid = -60; plot.max = -20;
                            applicationSettings.setValue("rta/historyInitialized", true);
                        }
                        workspace.followSource();
                    }
                    Connections {
                        target: workspace.spectrum
                        function onXminChanged() { if (plot) plot.xmin = workspace.spectrum.xmin; }
                        function onXmaxChanged() { if (plot) plot.xmax = workspace.spectrum.xmax; }
                    }
                }
            }
            onLoaded: {
                item.plot.xmin = workspace.spectrum.xmin;
                item.plot.xmax = workspace.spectrum.xmax;
                workspace.followSource();
            }
        }
    }
}
