import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Controls.Material 2.15
import QtQuick.Layouts 1.15
import QtQuick.Dialogs 1.2 as Dialogs
import QtQuick.Window 2.15
import Audio 1.0
import "elements"

ApplicationWindow {
    id: settingsWindow
    title: defaultsController.dirty ? qsTr("Settings — Defaults *") : qsTr("Settings — Defaults")
    width: 760
    height: 640
    minimumWidth: 620
    minimumHeight: 480
    visible: false
    flags: Qt.Window
    color: applicationWindow.color
    Material.theme: applicationAppearance.darkMode ? Material.Dark : Material.Light
    Material.accent: Material.Indigo

    property var measurement: null
    property var magnitudePlot: null
    property var rtaPlot: null
    property int revision: 0
    property bool allowClose: false
    readonly property string activeTab: tabs.currentIndex === 0 ? "measurement" : tabs.currentIndex === 1 ? "magnitude" : "rta"

    function draft(key, fallback) { revision; return defaultsController.value(key, fallback); }
    function put(key, value) { defaultsController.setValue(key, value); }
    function openFor(measurementObject, magnitudeObject, rtaObject) {
        measurement = measurementObject;
        magnitudePlot = magnitudeObject;
        rtaPlot = rtaObject;
        defaultsController.loadDraft(measurement, magnitudePlot, rtaPlot);
        allowClose = false;
        show();
        raise();
        requestActivate();
    }
    function finishClose() {
        allowClose = true;
        close();
        applicationWindow.raise();
        applicationWindow.requestActivate();
    }
    function requestClose() {
        if (defaultsController.dirty) unsavedDialog.open();
        else finishClose();
    }

    onClosing: function(closeEvent) {
        if (allowClose) return;
        closeEvent.accepted = false;
        requestClose();
    }
    Shortcut { sequence: "Esc"; onActivated: settingsWindow.requestClose() }

    Connections {
        target: defaultsController
        function onDraftChanged() { settingsWindow.revision++; }
    }

    DeviceModel { id: devices; scope: DeviceModel.InputOnly }
    readonly property int deviceIndex: devices.indexOf(draft("measurement/deviceId", ""))
    readonly property var inputChannels: deviceIndex >= 0 ? devices.channelNames(deviceIndex) : []

    header: TabBar {
        id: tabs
        TabButton { text: qsTr("Measurement") }
        TabButton { text: qsTr("Magnitude") }
        TabButton { text: qsTr("RTA / Spectrum") }
    }

    footer: Pane {
        padding: 12
        RowLayout {
            anchors.fill: parent
            Label {
                Layout.fillWidth: true
                text: defaultsController.error.length ? defaultsController.error : qsTr("Saved defaults apply the next time you open the app.")
                color: defaultsController.error.length ? Material.color(Material.Red) : applicationWindow.foregroundColor
                wrapMode: Text.WordWrap
            }
            Button { text: qsTr("Cancel"); onClicked: settingsWindow.requestClose() }
            Button {
                text: qsTr("Save defaults")
                highlighted: true
                onClicked: if (defaultsController.save()) settingsWindow.finishClose()
            }
        }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        StackLayout {
            currentIndex: tabs.currentIndex
            Layout.fillWidth: true
            Layout.fillHeight: true

            ScrollView {
                clip: true
                contentWidth: availableWidth
                ColumnLayout {
                    x: 18
                    width: parent.width - 36
                    spacing: 14

                    Label { text: qsTr("Audio routing"); font.bold: true }
                    GridLayout {
                        columns: 2; columnSpacing: 14; rowSpacing: 10; Layout.fillWidth: true
                        Label { text: qsTr("Audio device") }
                        ColumnLayout {
                            Layout.fillWidth: true
                            ComboBox {
                                Layout.fillWidth: true; model: devices; textRole: "name"
                                currentIndex: settingsWindow.deviceIndex
                                onActivated: settingsWindow.put("measurement/deviceId", devices.deviceId(index))
                            }
                            Label {
                                visible: settingsWindow.draft("measurement/deviceId", "") !== "" && settingsWindow.deviceIndex < 0
                                text: qsTr("Unavailable: %1 (preference retained)").arg(settingsWindow.draft("measurement/deviceId", ""))
                                color: Material.color(Material.Orange); wrapMode: Text.WordWrap
                            }
                        }
                        Label { text: qsTr("Measurement input") }
                        ComboBox {
                            Layout.fillWidth: true; model: settingsWindow.inputChannels
                            currentIndex: settingsWindow.draft("measurement/dataChannel", 0)
                            onActivated: settingsWindow.put("measurement/dataChannel", index)
                        }
                        Label { text: qsTr("Reference input") }
                        ComboBox {
                            Layout.fillWidth: true; model: settingsWindow.inputChannels
                            currentIndex: settingsWindow.draft("measurement/referenceChannel", 1)
                            onActivated: settingsWindow.put("measurement/referenceChannel", index)
                        }
                    }

                    Label { text: qsTr("Analysis"); font.bold: true }
                    GridLayout {
                        columns: 2; columnSpacing: 14; rowSpacing: 10; Layout.fillWidth: true
                        Label { text: qsTr("Averaging mode") }
                        ComboBox {
                            model: [qsTr("Off"), qsTr("Low-pass smoothing (LPF)"), qsTr("Rolling frames (FIFO)")]
                            currentIndex: settingsWindow.draft("measurement/averageType", 0)
                            onActivated: settingsWindow.put("measurement/averageType", index)
                        }
                        Label { visible: settingsWindow.draft("measurement/averageType", 0) === 2; text: qsTr("FIFO count") }
                        SpinBox {
                            visible: settingsWindow.draft("measurement/averageType", 0) === 2
                            from: 1; to: 100; editable: true; value: settingsWindow.draft("measurement/fifoCount", 8)
                            onValueModified: settingsWindow.put("measurement/fifoCount", value)
                        }
                        Label { visible: settingsWindow.draft("measurement/averageType", 0) === 1; text: qsTr("LPF frequency") }
                        ComboBox {
                            visible: settingsWindow.draft("measurement/averageType", 0) === 1
                            model: ["0.25 Hz", "0.5 Hz", "1 Hz"]
                            currentIndex: settingsWindow.draft("measurement/lpfFrequency", 1)
                            onActivated: settingsWindow.put("measurement/lpfFrequency", index)
                        }
                        Label { text: qsTr("Transform mode") }
                        ComboBox {
                            model: ["FFT 10", "FFT 11", "FFT 12", "FFT 13", "FFT 14", "FFT 15", "FFT 16", "LFT"]
                            currentIndex: settingsWindow.draft("measurement/mode", 0)
                            onActivated: settingsWindow.put("measurement/mode", index)
                        }
                        Label { text: qsTr("Window function") }
                        ComboBox {
                            model: measurement ? measurement.windows : ["Hann", "Hamming", "Blackman-Harris"]
                            currentIndex: settingsWindow.draft("measurement/window", 0)
                            onActivated: settingsWindow.put("measurement/window", index)
                        }
                        Label { text: qsTr("Input filter") }
                        ComboBox {
                            model: measurement ? measurement.inputFilters : ["Z", "A", "C", "Notch", "BP100", "LP200"]
                            currentIndex: settingsWindow.draft("measurement/inputFilter", 0)
                            onActivated: settingsWindow.put("measurement/inputFilter", index)
                        }
                        Label { text: qsTr("Polarity") }
                        CheckBox {
                            text: qsTr("Invert measurement input"); checked: settingsWindow.draft("measurement/polarity", false)
                            onCheckedChanged: if (settingsWindow.visible) settingsWindow.put("measurement/polarity", checked)
                        }
                    }

                    Label { text: qsTr("Identity and calibration"); font.bold: true }
                    GridLayout {
                        columns: 2; columnSpacing: 14; rowSpacing: 10; Layout.fillWidth: true
                        Label { text: qsTr("Name") }
                        TextField {
                            Layout.fillWidth: true; text: settingsWindow.draft("measurement/name", "Measurement")
                            onEditingFinished: settingsWindow.put("measurement/name", text)
                        }
                        Label { text: qsTr("Color") }
                        TextField {
                            text: settingsWindow.draft("measurement/color", "#673AB7").toString()
                            onEditingFinished: settingsWindow.put("measurement/color", text)
                        }
                        Label { text: qsTr("Microphone correction") }
                        RowLayout {
                            Layout.fillWidth: true
                            TextField { Layout.fillWidth: true; readOnly: true; text: settingsWindow.draft("measurement/calibrationFile", "") }
                            Button { text: qsTr("Choose…"); onClicked: correctionDialog.open() }
                        }
                        Label { text: qsTr("Correction state") }
                        CheckBox {
                            text: qsTr("Enabled"); checked: settingsWindow.draft("measurement/calibrationEnabled", false)
                            onCheckedChanged: if (settingsWindow.visible) settingsWindow.put("measurement/calibrationEnabled", checked)
                        }
                    }

                    Label { text: qsTr("Levels and timing"); font.bold: true }
                    GridLayout {
                        columns: 2; columnSpacing: 14; rowSpacing: 10; Layout.fillWidth: true
                        Label { text: qsTr("Reference offset") }
                        FloatSpinBox { from: -100; to: 100; step: 0.1; decimals: 1; units: " dB"; value: settingsWindow.draft("measurement/referenceOffset", 0); onValueChanged: settingsWindow.put("measurement/referenceOffset", value) }
                        Label { text: qsTr("Gain") }
                        FloatSpinBox { from: -100; to: 100; step: 0.1; decimals: 1; units: " dB"; value: settingsWindow.draft("measurement/gain", 0); onValueChanged: settingsWindow.put("measurement/gain", value) }
                        Label { text: qsTr("Delay") }
                        FloatSpinBox { from: -10000; to: 10000; step: 0.01; decimals: 2; units: " ms"; value: settingsWindow.draft("measurement/delayMs", 0); onValueChanged: settingsWindow.put("measurement/delayMs", value) }
                    }
                }
            }

            ScrollView {
                clip: true; contentWidth: availableWidth
                ColumnLayout {
                    x: 18; width: parent.width - 36; spacing: 14
                    Label { text: qsTr("Magnitude plot"); font.bold: true }
                    GridLayout {
                        columns: 2; columnSpacing: 14; rowSpacing: 10; Layout.fillWidth: true
                        Label { text: qsTr("Minimum frequency") }
                        FloatSpinBox { from: 12; to: 95999; step: 1; decimals: 0; units: " Hz"; value: settingsWindow.draft("magnitude/minFrequency", 20); onValueChanged: settingsWindow.put("magnitude/minFrequency", value) }
                        Label { text: qsTr("Maximum frequency") }
                        FloatSpinBox { from: 13; to: 96000; step: 100; decimals: 0; units: " Hz"; value: settingsWindow.draft("magnitude/maxFrequency", 20000); onValueChanged: settingsWindow.put("magnitude/maxFrequency", value) }
                        Label { text: qsTr("Minimum vertical range") }
                        FloatSpinBox { from: -200; to: 199; step: 1; decimals: 1; units: " dB"; value: settingsWindow.draft("magnitude/minVertical", -18); onValueChanged: settingsWindow.put("magnitude/minVertical", value) }
                        Label { text: qsTr("Maximum vertical range") }
                        FloatSpinBox { from: -199; to: 200; step: 1; decimals: 1; units: " dB"; value: settingsWindow.draft("magnitude/maxVertical", 18); onValueChanged: settingsWindow.put("magnitude/maxVertical", value) }
                        Label { text: qsTr("Axis mode") }
                        ComboBox { model: [qsTr("dB"), qsTr("Linear"), qsTr("Impedance")]; currentIndex: settingsWindow.draft("magnitude/mode", 0); onActivated: settingsWindow.put("magnitude/mode", index) }
                        Label { text: qsTr("Points per octave") }
                        SpinBox { from: 1; to: 48; editable: true; value: settingsWindow.draft("magnitude/pointsPerOctave", 12); onValueModified: settingsWindow.put("magnitude/pointsPerOctave", value) }
                        Label { text: qsTr("Invert") }
                        CheckBox { checked: settingsWindow.draft("magnitude/invert", false); onCheckedChanged: if (settingsWindow.visible) settingsWindow.put("magnitude/invert", checked) }
                        Label { text: qsTr("Coherence") }
                        CheckBox { text: qsTr("Enabled"); checked: settingsWindow.draft("magnitude/coherence", true); onCheckedChanged: if (settingsWindow.visible) settingsWindow.put("magnitude/coherence", checked) }
                        Label { visible: settingsWindow.draft("magnitude/coherence", true); text: qsTr("Coherence threshold") }
                        FloatSpinBox { visible: settingsWindow.draft("magnitude/coherence", true); from: 0; to: 1; step: 0.05; decimals: 2; value: settingsWindow.draft("magnitude/coherenceThreshold", 0.7); onValueChanged: settingsWindow.put("magnitude/coherenceThreshold", value) }
                        Label { visible: settingsWindow.draft("magnitude/mode", 0) === 2; text: qsTr("Sensor resistance") }
                        FloatSpinBox { visible: settingsWindow.draft("magnitude/mode", 0) === 2; from: 0.01; to: 1000; step: 0.1; decimals: 2; units: " Ω"; value: settingsWindow.draft("magnitude/sensorResistance", 2.6); onValueChanged: settingsWindow.put("magnitude/sensorResistance", value) }
                        Label { text: qsTr("Displayed sources") }
                        ComboBox {
                            model: [qsTr("All"), qsTr("None"), qsTr("Current selection")]
                            onActivated: settingsWindow.put("magnitude/sources", index === 0 ? ["all"] : index === 1 ? [] : (magnitudePlot ? magnitudePlot.selected : []))
                        }
                    }
                }
            }

            ScrollView {
                clip: true; contentWidth: availableWidth
                ColumnLayout {
                    x: 18; width: parent.width - 36; spacing: 14
                    Label { text: qsTr("RTA / Spectrum display"); font.bold: true }
                    Label { Layout.fillWidth: true; wrapMode: Text.WordWrap; text: qsTr("Input routing and averaging defaults come from the Measurement tab.") }
                    GridLayout {
                        columns: 2; columnSpacing: 14; rowSpacing: 10; Layout.fillWidth: true
                        Label { text: qsTr("Display style") }
                        ComboBox { model: [qsTr("Line"), qsTr("Bars"), qsTr("Lines")]; currentIndex: settingsWindow.draft("rta/displayStyle", 0); onActivated: settingsWindow.put("rta/displayStyle", index) }
                        Label { text: qsTr("Resolution") }
                        ComboBox {
                            property var values: [1, 3, 6, 12, 24, 48, 0]
                            model: [qsTr("1 octave"), qsTr("1/3 octave"), qsTr("1/6 octave"), qsTr("1/12 octave"), qsTr("1/24 octave"), qsTr("1/48 octave"), qsTr("FFT bins")]
                            currentIndex: values.indexOf(settingsWindow.draft("rta/resolution", 0))
                            onActivated: settingsWindow.put("rta/resolution", values[index])
                        }
                        Label { text: qsTr("Peak display") }
                        CheckBox { text: qsTr("Hold peaks"); checked: settingsWindow.draft("rta/holdPeaks", true); onCheckedChanged: if (settingsWindow.visible) settingsWindow.put("rta/holdPeaks", checked) }
                        Label { text: qsTr("Trace motion") }
                        CheckBox { text: qsTr("Smooth trace motion"); checked: settingsWindow.draft("rta/smooth", true); onCheckedChanged: if (settingsWindow.visible) settingsWindow.put("rta/smooth", checked) }
                        Label { text: qsTr("Heatmap") }
                        CheckBox { text: qsTr("Visible"); checked: settingsWindow.draft("rta/heatmap", true); onCheckedChanged: if (settingsWindow.visible) settingsWindow.put("rta/heatmap", checked) }
                    }
                }
            }
        }

        ToolBar {
            Layout.fillWidth: true
            RowLayout {
                anchors.fill: parent
                Button {
                    text: qsTr("Use current values")
                    onClicked: defaultsController.useCurrentValues(settingsWindow.activeTab, measurement, magnitudePlot, rtaPlot)
                }
                Item { Layout.fillWidth: true }
                Button {
                    text: qsTr("Reset tab to factory defaults")
                    onClicked: defaultsController.resetTab(settingsWindow.activeTab)
                }
            }
        }
    }

    Dialogs.FileDialog {
        id: correctionDialog
        title: qsTr("Choose a microphone correction file")
        selectExisting: true
        nameFilters: [qsTr("Correction files (*.txt *.cal *.csv)"), qsTr("All files (*)")]
        onAccepted: settingsWindow.put("measurement/calibrationFile", fileUrl.toString().replace("file://", ""))
    }

    Dialog {
        id: unsavedDialog
        modal: true
        width: 480
        title: qsTr("Save changes to defaults?")
        anchors.centerIn: parent
        contentItem: ColumnLayout {
            spacing: 12
            Label { text: qsTr("You have unsaved changes."); wrapMode: Text.WordWrap }
            RowLayout {
                Button { text: qsTr("Save"); highlighted: true; onClicked: { if (defaultsController.save()) { unsavedDialog.close(); settingsWindow.finishClose(); } } }
                Button { text: qsTr("Discard"); onClicked: { defaultsController.discard(); unsavedDialog.close(); settingsWindow.finishClose(); } }
                Button { text: qsTr("Keep editing"); onClicked: unsavedDialog.close() }
            }
        }
    }
}
