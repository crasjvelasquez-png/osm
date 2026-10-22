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
    color: applicationWindow.ui.shell
    font.family: applicationWindow.ui.fontFamily
    font.pixelSize: applicationWindow.ui.controlFontSize
    Material.theme: applicationAppearance.darkMode ? Material.Dark : Material.Light
    Material.accent: applicationWindow.ui.primary

    property var measurement: null
    property var magnitudePlot: null
    property var rtaPlot: null
    property int revision: 0
    property bool allowClose: false
    readonly property string activeTab: tabs.currentIndex === 0 ? "measurement" : tabs.currentIndex === 1 ? "magnitude" : "rta"
    property string recordingShortcutId: ""
    property string shortcutError: ""

    function draft(key, fallback) { revision; return defaultsController.value(key, fallback); }
    function put(key, value) { defaultsController.setValue(key, value); }
    function openFor(measurementObject, magnitudeObject, rtaObject, selectedTab) {
        measurement = measurementObject;
        magnitudePlot = magnitudeObject;
        rtaPlot = rtaObject;
        defaultsController.loadDraft(measurement, magnitudePlot, rtaPlot);
        allowClose = false;
        show();
        raise();
        if (selectedTab !== undefined) tabs.currentIndex = selectedTab;
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
    Shortcut { sequence: applicationWindow.shortcutRegistry.sequence("settings.close"); enabled: !applicationWindow.isTextEntryFocused(settingsWindow.activeFocusItem); onActivated: settingsWindow.requestClose() }

    Connections {
        target: defaultsController
        function onDraftChanged() { settingsWindow.revision++; }
    }

    DeviceModel { id: devices; scope: DeviceModel.InputOnly }
    readonly property int deviceIndex: devices.indexOf(draft("measurement/deviceId", ""))
    readonly property var inputChannels: deviceIndex >= 0 ? devices.channelNames(deviceIndex) : []

    header: TabBar {
        id: tabs
        padding: 8
        spacing: 4
        background: Rectangle { color: applicationWindow.ui.panel }
        Repeater {
            model: [qsTr("Measurement"), qsTr("Magnitude"), qsTr("RTA / Spectrum"), qsTr("Shortcuts")]
            TabButton {
                text: modelData
                implicitHeight: 36
                font.pixelSize: applicationWindow.ui.controlFontSize
                font.capitalization: Font.MixedCase
                topInset: 0; bottomInset: 0
                contentItem: Text {
                    text: parent.text; font: parent.font
                    color: applicationWindow.ui.text
                    horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter
                    elide: Text.ElideRight
                }
                background: Rectangle {
                    radius: applicationWindow.ui.controlRadius
                    color: parent.checked ? applicationWindow.ui.selection : parent.hovered ? applicationWindow.ui.hover : "transparent"
                    border.width: parent.visualFocus ? 2 : parent.checked ? 1 : 0
                    border.color: parent.visualFocus ? applicationWindow.ui.focus : applicationWindow.ui.separator
                }
            }
        }
    }

    footer: Pane {
        padding: 16
        background: Rectangle { color: applicationWindow.ui.panel; Rectangle { anchors.top: parent.top; width: parent.width; height: 1; color: applicationWindow.ui.separator } }
        RowLayout {
            anchors.fill: parent
            Label {
                Layout.fillWidth: true
                font.pixelSize: 12
                text: tabs.currentIndex === 3 ? (settingsWindow.shortcutError || qsTr("Click a shortcut field, then press the new key combination. Changes apply immediately.")) : (defaultsController.error.length ? defaultsController.error : qsTr("Saved defaults apply the next time you open the app."))
                color: ((tabs.currentIndex === 3 && settingsWindow.shortcutError.length) || (tabs.currentIndex !== 3 && defaultsController.error.length)) ? (applicationAppearance.darkMode ? "#FF9696" : "#B02030") : applicationWindow.ui.secondaryText
                wrapMode: Text.WordWrap
            }
            StudioButton { text: tabs.currentIndex === 3 ? qsTr("Close") : qsTr("Cancel"); onClicked: settingsWindow.requestClose() }
            StudioButton {
                text: qsTr("Save defaults")
                visible: tabs.currentIndex !== 3
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

                    DefaultsSection { text: qsTr("Audio routing") }
                    GridLayout {
                        columns: 2; columnSpacing: 16; rowSpacing: 8; Layout.fillWidth: true
                        Label { Layout.preferredWidth: 180; text: qsTr("Audio device") }
                        ColumnLayout {
                            Layout.fillWidth: true
                            DropDown {
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
                        Label { Layout.preferredWidth: 180; text: qsTr("Measurement input") }
                        DropDown { Layout.minimumWidth: 240;
                            Layout.fillWidth: true; model: settingsWindow.inputChannels
                            currentIndex: settingsWindow.draft("measurement/dataChannel", 0)
                            onActivated: settingsWindow.put("measurement/dataChannel", index)
                        }
                        Label { Layout.preferredWidth: 180; text: qsTr("Reference input") }
                        DropDown { Layout.minimumWidth: 240;
                            Layout.fillWidth: true; model: settingsWindow.inputChannels
                            currentIndex: settingsWindow.draft("measurement/referenceChannel", 1)
                            onActivated: settingsWindow.put("measurement/referenceChannel", index)
                        }
                    }

                    DefaultsSection { text: qsTr("Analysis") }
                    GridLayout {
                        columns: 2; columnSpacing: 16; rowSpacing: 8; Layout.fillWidth: true
                        Label { Layout.preferredWidth: 180; text: qsTr("Averaging mode") }
                        DropDown { Layout.minimumWidth: 240;
                            model: [qsTr("Off"), qsTr("Low-pass smoothing (LPF)"), qsTr("Rolling frames (FIFO)")]
                            currentIndex: settingsWindow.draft("measurement/averageType", 0)
                            onActivated: settingsWindow.put("measurement/averageType", index)
                        }
                        Label { Layout.preferredWidth: 180; visible: settingsWindow.draft("measurement/averageType", 0) === 2; text: qsTr("FIFO count") }
                        SelectableSpinBox { Layout.minimumWidth: 240;
                            visible: settingsWindow.draft("measurement/averageType", 0) === 2
                            from: 1; to: 100; editable: true; value: settingsWindow.draft("measurement/fifoCount", 2)
                            onValueModified: settingsWindow.put("measurement/fifoCount", value)
                        }
                        Label { Layout.preferredWidth: 180; visible: settingsWindow.draft("measurement/averageType", 0) === 1; text: qsTr("LPF frequency") }
                        DropDown { Layout.minimumWidth: 240;
                            visible: settingsWindow.draft("measurement/averageType", 0) === 1
                            model: ["0.25 Hz", "0.5 Hz", "1 Hz"]
                            currentIndex: settingsWindow.draft("measurement/lpfFrequency", 2)
                            onActivated: settingsWindow.put("measurement/lpfFrequency", index)
                        }
                        Label { Layout.preferredWidth: 180; text: qsTr("Transform mode") }
                        DropDown { Layout.minimumWidth: 240;
                            model: ["FFT 10", "FFT 11", "FFT 12", "FFT 13", "FFT 14", "FFT 15", "FFT 16", "LFT"]
                            currentIndex: settingsWindow.draft("measurement/mode", 3)
                            onActivated: settingsWindow.put("measurement/mode", index)
                        }
                        Label { Layout.preferredWidth: 180; text: qsTr("Window function") }
                        DropDown { Layout.minimumWidth: 240;
                            model: measurement ? measurement.windows : ["Hann", "Hamming", "Blackman-Harris"]
                            currentIndex: settingsWindow.draft("measurement/window", 1)
                            onActivated: settingsWindow.put("measurement/window", index)
                        }
                        Label { Layout.preferredWidth: 180; text: qsTr("Input filter") }
                        DropDown { Layout.minimumWidth: 240;
                            model: measurement ? measurement.inputFilters : ["Z", "A", "C", "Notch", "BP100", "LP200"]
                            currentIndex: settingsWindow.draft("measurement/inputFilter", 0)
                            onActivated: settingsWindow.put("measurement/inputFilter", index)
                        }
                        Label { Layout.preferredWidth: 180; text: qsTr("Polarity") }
                        CheckBox {
                            text: qsTr("Invert measurement input"); checked: settingsWindow.draft("measurement/polarity", false)
                            onCheckedChanged: if (settingsWindow.visible) settingsWindow.put("measurement/polarity", checked)
                        }
                    }

                    DefaultsSection { text: qsTr("Identity and calibration") }
                    GridLayout {
                        columns: 2; columnSpacing: 16; rowSpacing: 8; Layout.fillWidth: true
                        Label { Layout.preferredWidth: 180; text: qsTr("Name") }
                        StudioTextField {
                            Layout.fillWidth: true; text: settingsWindow.draft("measurement/name", "Measurement")
                            implicitHeight: 36; font.pixelSize: applicationWindow.ui.controlFontSize
                            onEditingFinished: settingsWindow.put("measurement/name", text)
                        }
                        Label { Layout.preferredWidth: 180; text: qsTr("Color") }
                        StudioTextField {
                            text: settingsWindow.draft("measurement/color", "#673AB7").toString()
                            implicitHeight: 36; font.pixelSize: applicationWindow.ui.controlFontSize
                            onEditingFinished: settingsWindow.put("measurement/color", text)
                        }
                        Label { Layout.preferredWidth: 180; text: qsTr("Microphone correction") }
                        RowLayout {
                            Layout.fillWidth: true
                            StudioTextField {
                                Layout.fillWidth: true; readOnly: true; text: settingsWindow.draft("measurement/calibrationFile", "")
                                implicitHeight: 36; font.pixelSize: applicationWindow.ui.controlFontSize
                            }
                            StudioButton { text: qsTr("Choose…"); onClicked: correctionDialog.open() }
                        }
                        Label { Layout.preferredWidth: 180; text: qsTr("Correction state") }
                        CheckBox {
                            text: qsTr("Enabled"); checked: settingsWindow.draft("measurement/calibrationEnabled", false)
                            onCheckedChanged: if (settingsWindow.visible) settingsWindow.put("measurement/calibrationEnabled", checked)
                        }
                    }

                    DefaultsSection { text: qsTr("Levels and timing") }
                    GridLayout {
                        columns: 2; columnSpacing: 16; rowSpacing: 8; Layout.fillWidth: true
                        Label { Layout.preferredWidth: 180; text: qsTr("Reference offset") }
                        FloatSpinBox { Layout.minimumWidth: 240; from: -100; to: 100; step: 0.1; decimals: 1; units: " dB"; value: settingsWindow.draft("measurement/referenceOffset", 0); onValueChanged: settingsWindow.put("measurement/referenceOffset", value) }
                        Label { Layout.preferredWidth: 180; text: qsTr("Gain") }
                        FloatSpinBox { Layout.minimumWidth: 240; from: -100; to: 100; step: 0.1; decimals: 1; units: " dB"; value: settingsWindow.draft("measurement/gain", 0); onValueChanged: settingsWindow.put("measurement/gain", value) }
                        Label { Layout.preferredWidth: 180; text: qsTr("Delay") }
                        FloatSpinBox { Layout.minimumWidth: 240; from: -10000; to: 10000; step: 0.01; decimals: 2; units: " ms"; value: settingsWindow.draft("measurement/delayMs", 0); onValueChanged: settingsWindow.put("measurement/delayMs", value) }
                    }
                }
            }

            ScrollView {
                clip: true; contentWidth: availableWidth
                ColumnLayout {
                    x: 18; width: parent.width - 36; spacing: 14
                    DefaultsSection { text: qsTr("Magnitude plot") }
                    GridLayout {
                        columns: 2; columnSpacing: 16; rowSpacing: 8; Layout.fillWidth: true
                        Label { Layout.preferredWidth: 180; text: qsTr("Minimum frequency") }
                        FloatSpinBox { Layout.minimumWidth: 240; from: 12; to: 95999; step: 1; decimals: 0; units: " Hz"; value: settingsWindow.draft("magnitude/minFrequency", 20); onValueChanged: settingsWindow.put("magnitude/minFrequency", value) }
                        Label { Layout.preferredWidth: 180; text: qsTr("Maximum frequency") }
                        FloatSpinBox { Layout.minimumWidth: 240; from: 13; to: 96000; step: 100; decimals: 0; units: " Hz"; value: settingsWindow.draft("magnitude/maxFrequency", 20000); onValueChanged: settingsWindow.put("magnitude/maxFrequency", value) }
                        Label { Layout.preferredWidth: 180; text: qsTr("Minimum vertical range") }
                        FloatSpinBox { Layout.minimumWidth: 240; from: -200; to: 199; step: 1; decimals: 1; units: " dB"; value: settingsWindow.draft("magnitude/minVertical", -18); onValueChanged: settingsWindow.put("magnitude/minVertical", value) }
                        Label { Layout.preferredWidth: 180; text: qsTr("Maximum vertical range") }
                        FloatSpinBox { Layout.minimumWidth: 240; from: -199; to: 200; step: 1; decimals: 1; units: " dB"; value: settingsWindow.draft("magnitude/maxVertical", 18); onValueChanged: settingsWindow.put("magnitude/maxVertical", value) }
                        Label { Layout.preferredWidth: 180; text: qsTr("Axis mode") }
                        DropDown { Layout.minimumWidth: 240; model: [qsTr("dB"), qsTr("Linear"), qsTr("Impedance")]; currentIndex: settingsWindow.draft("magnitude/mode", 0); onActivated: settingsWindow.put("magnitude/mode", index) }
                        Label { Layout.preferredWidth: 180; text: qsTr("Points per octave") }
                        SelectableSpinBox { Layout.minimumWidth: 240; from: 1; to: 48; editable: true; value: settingsWindow.draft("magnitude/pointsPerOctave", 12); onValueModified: settingsWindow.put("magnitude/pointsPerOctave", value) }
                        Label { Layout.preferredWidth: 180; text: qsTr("Invert") }
                        CheckBox { checked: settingsWindow.draft("magnitude/invert", false); onCheckedChanged: if (settingsWindow.visible) settingsWindow.put("magnitude/invert", checked) }
                        Label { Layout.preferredWidth: 180; text: qsTr("Coherence") }
                        CheckBox { text: qsTr("Enabled"); checked: settingsWindow.draft("magnitude/coherence", true); onCheckedChanged: if (settingsWindow.visible) settingsWindow.put("magnitude/coherence", checked) }
                        Label { Layout.preferredWidth: 180; visible: settingsWindow.draft("magnitude/coherence", true); text: qsTr("Coherence threshold") }
                        FloatSpinBox { Layout.minimumWidth: 240; visible: settingsWindow.draft("magnitude/coherence", true); from: 0; to: 1; step: 0.05; decimals: 2; value: settingsWindow.draft("magnitude/coherenceThreshold", 0.7); onValueChanged: settingsWindow.put("magnitude/coherenceThreshold", value) }
                        Label { Layout.preferredWidth: 180; visible: settingsWindow.draft("magnitude/mode", 0) === 2; text: qsTr("Sensor resistance") }
                        FloatSpinBox { Layout.minimumWidth: 240; visible: settingsWindow.draft("magnitude/mode", 0) === 2; from: 0.01; to: 1000; step: 0.1; decimals: 2; units: " Ω"; value: settingsWindow.draft("magnitude/sensorResistance", 2.6); onValueChanged: settingsWindow.put("magnitude/sensorResistance", value) }
                        Label { Layout.preferredWidth: 180; text: qsTr("Displayed sources") }
                        DropDown { Layout.minimumWidth: 240;
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
                    DefaultsSection { text: qsTr("RTA / Spectrum display") }
                    Label { Layout.fillWidth: true; wrapMode: Text.WordWrap; text: qsTr("Input routing and averaging defaults come from the Measurement tab.") }
                    GridLayout {
                        columns: 2; columnSpacing: 16; rowSpacing: 8; Layout.fillWidth: true
                        Label { Layout.preferredWidth: 180; text: qsTr("Display style") }
                        DropDown { Layout.minimumWidth: 240; model: [qsTr("Line"), qsTr("Bars"), qsTr("Lines")]; currentIndex: settingsWindow.draft("rta/displayStyle", 1); onActivated: settingsWindow.put("rta/displayStyle", index) }
                        Label { Layout.preferredWidth: 180; text: qsTr("Resolution") }
                        DropDown { Layout.minimumWidth: 240;
                            property var values: [1, 3, 6, 12, 24, 48, 0]
                            model: [qsTr("1 octave"), qsTr("1/3 octave"), qsTr("1/6 octave"), qsTr("1/12 octave"), qsTr("1/24 octave"), qsTr("1/48 octave"), qsTr("FFT bins")]
                            currentIndex: values.indexOf(settingsWindow.draft("rta/resolution", 24))
                            onActivated: settingsWindow.put("rta/resolution", values[index])
                        }
                        Label { Layout.preferredWidth: 180; text: qsTr("Peak display") }
                        CheckBox { text: qsTr("Hold peaks"); checked: settingsWindow.draft("rta/holdPeaks", true); onCheckedChanged: if (settingsWindow.visible) settingsWindow.put("rta/holdPeaks", checked) }
                        Label { Layout.preferredWidth: 180; text: qsTr("Trace motion") }
                        CheckBox { text: qsTr("Smooth trace motion"); checked: settingsWindow.draft("rta/smooth", false); onCheckedChanged: if (settingsWindow.visible) settingsWindow.put("rta/smooth", checked) }
                        Label { Layout.preferredWidth: 180; text: qsTr("Heatmap") }
                        CheckBox { text: qsTr("Visible"); checked: settingsWindow.draft("rta/heatmap", true); onCheckedChanged: if (settingsWindow.visible) settingsWindow.put("rta/heatmap", checked) }
                    }
                }
            }

            ScrollView {
                clip: true
                contentWidth: availableWidth
                ColumnLayout {
                    x: 18
                    width: parent.width - 36
                    spacing: 8
                    DefaultsSection { text: qsTr("Keyboard shortcuts") }
                    Label {
                        Layout.fillWidth: true
                        wrapMode: Text.WordWrap
                        color: applicationWindow.ui.secondaryText
                        text: qsTr("Shortcuts apply immediately. Click a key field and press a combination to assign it. Press Backspace to clear one, or use Reset to restore an individual default. Reset all restores every default.")
                    }
                    GridLayout {
                        id: shortcutGrid
                        columns: 3
                        columnSpacing: 12
                        rowSpacing: 4
                        Layout.fillWidth: true
                        Layout.topMargin: 8
                        Label { text: qsTr("Action"); font.bold: true; color: applicationWindow.ui.secondaryText }
                        Label { text: qsTr("Shortcut"); font.bold: true; color: applicationWindow.ui.secondaryText }
                        Item { Layout.preferredWidth: 64 }

                        Repeater {
                            model: applicationWindow.shortcutRegistry.entries
                            delegate: Item {
                                id: shortcutRow
                                property var entryData: modelData
                                Layout.columnSpan: 3
                                Layout.fillWidth: true
                                implicitHeight: categoryLabel.visible ? 72 : 44
                                Label {
                                    id: categoryLabel
                                    anchors.left: parent.left
                                    anchors.right: parent.right
                                    anchors.top: parent.top
                                    height: visible ? 28 : 0
                                    visible: index === 0 || modelData.category !== applicationWindow.shortcutRegistry.entries[index - 1].category
                                    text: visible ? modelData.category : ""
                                    font.pixelSize: applicationWindow.ui.secondaryFontSize
                                    font.bold: true
                                    color: applicationWindow.ui.secondaryText
                                    verticalAlignment: Text.AlignBottom
                                    bottomPadding: 4
                                }
                                RowLayout {
                                    anchors.left: parent.left
                                    anchors.right: parent.right
                                    anchors.bottom: parent.bottom
                                    height: 40
                                    spacing: 12
                                    Label {
                                        Layout.fillWidth: true
                                        text: modelData.title
                                        color: applicationWindow.ui.text
                                        elide: Text.ElideRight
                                    }
                                    TextField {
                                        id: sequenceField
                                        Layout.preferredWidth: 190
                                        Layout.minimumWidth: 140
                                        implicitHeight: 34
                                        readOnly: true
                                        selectByMouse: false
                                        text: settingsWindow.recordingShortcutId === modelData.id ? qsTr("Press keys…") : applicationWindow.shortcutRegistry.display(modelData.id)
                                        placeholderText: qsTr("Unassigned")
                                        font.pixelSize: applicationWindow.ui.controlFontSize
                                        background: Rectangle {
                                            radius: applicationWindow.ui.controlRadius
                                            color: sequenceField.activeFocus ? applicationWindow.ui.selection : applicationWindow.ui.control
                                            border.width: sequenceField.activeFocus ? 2 : 1
                                            border.color: sequenceField.activeFocus ? applicationWindow.ui.focus : applicationWindow.ui.separator
                                        }
                                        TapHandler {
                                            onTapped: {
                                                sequenceField.forceActiveFocus();
                                                settingsWindow.recordingShortcutId = modelData.id;
                                                settingsWindow.shortcutError = "";
                                            }
                                        }
                                        Keys.onPressed: function(event) {
                                            event.accepted = true;
                                            if (event.key === Qt.Key_Escape) {
                                                settingsWindow.recordingShortcutId = "";
                                                return;
                                            }
                                            if (event.key === Qt.Key_Backspace && event.modifiers === Qt.NoModifier) {
                                                applicationWindow.shortcutRegistry.assign(modelData.id, "");
                                                settingsWindow.recordingShortcutId = "";
                                                settingsWindow.shortcutError = "";
                                                return;
                                            }
                                            if ([Qt.Key_Control, Qt.Key_Meta, Qt.Key_Shift, Qt.Key_Alt].indexOf(event.key) >= 0) return;
                                            var parts = [];
                                            if (event.modifiers & Qt.ControlModifier) parts.push("Ctrl");
                                            if (event.modifiers & Qt.MetaModifier) parts.push("Meta");
                                            if (event.modifiers & Qt.AltModifier) parts.push("Alt");
                                            if (event.modifiers & Qt.ShiftModifier) parts.push("Shift");
                                            var keyName = event.key >= Qt.Key_A && event.key <= Qt.Key_Z ? String.fromCharCode(event.key) :
                                                          event.key >= Qt.Key_0 && event.key <= Qt.Key_9 ? String.fromCharCode(event.key) : "";
                                            if (event.key === Qt.Key_Slash) keyName = "/";
                                            else if (event.key === Qt.Key_Space) keyName = "Space";
                                            else if (event.key >= Qt.Key_F1 && event.key <= Qt.Key_F12) keyName = "F" + (event.key - Qt.Key_F1 + 1);
                                            else if (event.key === Qt.Key_Backspace) keyName = "Backspace";
                                            else if (event.key === Qt.Key_Delete) keyName = "Delete";
                                            else if (event.key === Qt.Key_Tab) keyName = "Tab";
                                            if (!keyName.length) {
                                                settingsWindow.shortcutError = qsTr("That key cannot be assigned here.");
                                                return;
                                            }
                                            parts.push(keyName);
                                            var sequence = parts.join("+");
                                            var conflict = applicationWindow.shortcutRegistry.duplicate(modelData.id, sequence);
                                            if (conflict.length) {
                                                settingsWindow.shortcutError = qsTr("That combination is already assigned to %1.").arg(conflict);
                                                return;
                                            }
                                            applicationWindow.shortcutRegistry.assign(modelData.id, sequence);
                                            settingsWindow.recordingShortcutId = "";
                                            settingsWindow.shortcutError = "";
                                        }
                                    }
                                    StudioButton {
                                        Layout.preferredWidth: 64
                                        text: qsTr("Reset")
                                        flat: true
                                        onClicked: applicationWindow.shortcutRegistry.reset(modelData.id)
                                    }
                                }
                            }
                        }
                    }
                    StudioButton {
                        text: qsTr("Reset all shortcuts")
                        flat: true
                        Layout.topMargin: 8
                        onClicked: {
                            applicationWindow.shortcutRegistry.resetAll();
                            settingsWindow.shortcutError = "";
                        }
                    }
                }
            }
        }

        ToolBar {
            visible: tabs.currentIndex !== 3
            Layout.fillWidth: true
            background: Rectangle { color: applicationWindow.ui.panel; Rectangle { anchors.top: parent.top; width: parent.width; height: 1; color: applicationWindow.ui.separator } }
            RowLayout {
                anchors.fill: parent
                StudioButton {
                    text: qsTr("Use current values")
                    flat: true
                    onClicked: defaultsController.useCurrentValues(settingsWindow.activeTab, measurement, magnitudePlot, rtaPlot)
                }
                Item { Layout.fillWidth: true }
                StudioButton {
                    text: qsTr("Reset tab to factory defaults")
                    flat: true
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

    ModalDialog {
        id: unsavedDialog
        width: Math.min(480, parent.width - 32)
        title: qsTr("Save changes to defaults?")
        detail: qsTr("You have unsaved changes.")
        acceptOnReturn: false
        footer: DialogButtonBox {
            padding: 24
            topPadding: 0
            spacing: 8
            alignment: Qt.AlignRight
            background: Item {}
            StudioButton { text: qsTr("Discard"); onClicked: { defaultsController.discard(); unsavedDialog.close(); settingsWindow.finishClose(); } }
            StudioButton { text: qsTr("Keep editing"); onClicked: unsavedDialog.close() }
            StudioButton { text: qsTr("Save"); highlighted: true; onClicked: { if (defaultsController.save()) { unsavedDialog.close(); settingsWindow.finishClose(); } } }
        }
    }
}
