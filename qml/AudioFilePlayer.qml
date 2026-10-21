import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Controls.Material 2.15
import QtQuick.Layouts 1.15
import QtQuick.Dialogs 1.2 as Dialogs
import Audio 1.0
import "elements"

ApplicationWindow {
    id: player
    title: qsTr("Generator — Audio file")
    width: 700
    height: 630
    minimumWidth: 620
    minimumHeight: 610
    visible: false
    color: applicationWindow.ui.shell
    font.family: applicationWindow.ui.fontFamily
    font.pixelSize: applicationWindow.ui.controlFontSize
    Material.theme: applicationAppearance.darkMode ? Material.Dark : Material.Light
    Material.accent: applicationWindow.ui.primary
    readonly property var file: generatorModel.audioFile
    readonly property bool loading: generatorModel.audioFileLoading
    readonly property bool local: !remoteClient.controlledGenerator || !remoteClient.controlledGenerator.data
    readonly property bool playable: local && file.ready && !loading
    readonly property bool playing: generatorModel.type === 9 && generatorModel.enabled

    function open() { show(); raise(); requestActivate(); }
    function time(seconds) {
        var value = Math.floor(Math.max(0, seconds));
        return Math.floor(value / 60) + ":" + (value % 60 < 10 ? "0" : "") + value % 60;
    }
    function togglePlayback() {
        if (!playable) return;
        if (generatorModel.type !== 9) generatorModel.type = 9;
        generatorModel.enabled = !playing;
    }

    Dialogs.FileDialog {
        id: chooser
        title: qsTr("Choose audio for the Generator")
        selectExisting: true
        selectMultiple: false
        nameFilters: [qsTr("Audio files (*.wav *.wave *.aif *.aiff *.aifc *.mp3 *.m4a *.aac *.flac *.caf)"), qsTr("All files (*)")]
        onAccepted: generatorModel.loadAudioFile(fileUrl)
    }

    DropArea {
        anchors.fill: parent
        enabled: player.local && !player.loading
        onDropped: {
            if (drop.urls.length === 1) generatorModel.loadAudioFile(drop.urls[0]);
        }
    }
    ScrollView {
        anchors.fill: parent
        anchors.margins: 24
        contentWidth: availableWidth
        ColumnLayout {
            width: parent.width
            spacing: 12
            RowLayout {
                Layout.fillWidth: true
                Label {
                    Layout.fillWidth: true
                    text: player.loading ? qsTr("Loading audio…") : player.file.ready ? player.file.name : qsTr("Choose an audio file")
                    font.pixelSize: 20
                    elide: Text.ElideMiddle
                    ToolTip.visible: nameHover.containsMouse && player.file.ready
                    ToolTip.text: player.file.path
                    MouseArea { id: nameHover; anchors.fill: parent; hoverEnabled: true; acceptedButtons: Qt.NoButton }
                }
                StudioButton {
                    text: player.file.ready ? qsTr("Replace file…") : qsTr("Choose file…")
                    enabled: player.local && !player.loading
                    onClicked: chooser.open()
                }
            }
            Label {
                Layout.fillWidth: true
                text: player.file.ready ? qsTr("%1 · %2 Hz · %3").arg(player.time(player.file.duration)).arg(player.file.sampleRate).arg(player.file.channels === 1 ? qsTr("Mono") : qsTr("Stereo"))
                                        : qsTr("WAV, AIFF, MP3, M4A / ALAC, AAC, FLAC, CAF. You can also drop a file here.")
                wrapMode: Text.WordWrap
                opacity: 0.8
            }
            Label {
                Layout.fillWidth: true
                visible: !!player.file.error || !player.local
                text: !player.local ? qsTr("Select Local in the Generator to use audio files.") : player.file.error
                wrapMode: Text.WordWrap
                color: Material.color(Material.Red, applicationAppearance.darkMode ? Material.Shade200 : Material.Shade700)
            }
            Label {
                Layout.fillWidth: true
                visible: player.playable && player.file.outputs === 0
                text: qsTr("No output channels selected. Choose channels under Output to hear audio.")
                wrapMode: Text.WordWrap
                color: Material.color(Material.Amber, applicationAppearance.darkMode ? Material.Shade200 : Material.Shade900)
            }
            RowLayout {
                Layout.fillWidth: true
                enabled: player.playable
                StudioButton { text: player.playing ? qsTr("Pause") : qsTr("Play"); onClicked: player.togglePlayback() }
                StudioButton { text: qsTr("Stop"); onClicked: generatorModel.stopAudioFile() }
                StudioButton { text: qsTr("−5 sec"); onClicked: generatorModel.seekAudioFile(player.file.position - 5) }
                StudioButton { text: qsTr("+5 sec"); onClicked: generatorModel.seekAudioFile(player.file.position + 5) }
                Item { Layout.fillWidth: true }
                CheckBox {
                    text: qsTr("Loop")
                    checked: !!player.file.loop
                    onToggled: generatorModel.setAudioFileLoop(checked)
                }
            }
            Slider {
                id: position
                Layout.fillWidth: true
                enabled: player.playable
                from: player.file.start || 0
                to: Math.max(from + 0.001, player.file.end || 0)
                value: player.file.position || 0
                onMoved: generatorModel.seekAudioFile(value)
                Accessible.name: qsTr("Playback position")
                ToolTip.visible: pressed
                ToolTip.text: player.time(value)
            }
            RowLayout {
                Layout.fillWidth: true
                Label { text: player.time(position.pressed ? position.value : player.file.position || 0) }
                Item { Layout.fillWidth: true }
                Label { text: player.time(player.file.duration || 0) }
            }
            GridLayout {
                columns: 3
                columnSpacing: 12
                rowSpacing: 8
                Layout.fillWidth: true
                enabled: player.playable
                Label { text: qsTr("Start (sec)") }
                SelectableSpinBox {
                    id: regionStart
                    Layout.fillWidth: true
                    from: 0
                    to: Math.max(0, Math.round((player.file.end || 0) * 100) - 1)
                    value: Math.round((player.file.start || 0) * 100)
                    editable: true
                    stepSize: 100
                    textFromValue: function(value, locale) { return Number(value / 100).toLocaleString(locale, 'f', 2); }
                    valueFromText: function(text, locale) { return Math.round(Number.fromLocaleString(locale, text) * 100); }
                    validator: DoubleValidator { bottom: 0; top: regionStart.to / 100; decimals: 2 }
                    onValueModified: generatorModel.setAudioFileRegion(value / 100, player.file.end)
                    Accessible.name: qsTr("Region start in seconds")
                }
                StudioButton {
                    text: qsTr("Set to playhead")
                    enabled: player.file.position < player.file.end - 0.01
                    onClicked: generatorModel.setAudioFileRegion(player.file.position, player.file.end)
                }
                Label { text: qsTr("End (sec)") }
                SelectableSpinBox {
                    id: regionEnd
                    Layout.fillWidth: true
                    from: Math.round((player.file.start || 0) * 100) + 1
                    to: Math.max(from, Math.ceil((player.file.duration || 0) * 100))
                    value: Math.round((player.file.end || 0) * 100)
                    editable: true
                    stepSize: 100
                    textFromValue: function(value, locale) { return Number(value / 100).toLocaleString(locale, 'f', 2); }
                    valueFromText: function(text, locale) { return Math.round(Number.fromLocaleString(locale, text) * 100); }
                    validator: DoubleValidator { bottom: regionEnd.from / 100; top: regionEnd.to / 100; decimals: 2 }
                    onValueModified: generatorModel.setAudioFileRegion(player.file.start, Math.min(value / 100, player.file.duration))
                    Accessible.name: qsTr("Region end in seconds")
                }
                StudioButton {
                    text: qsTr("Set to playhead")
                    enabled: player.file.position > player.file.start + 0.01
                    onClicked: generatorModel.setAudioFileRegion(player.file.start, player.file.position)
                }
            }
            RowLayout {
                Layout.fillWidth: true
                StudioButton {
                    text: qsTr("Reset full file")
                    enabled: player.playable
                    onClicked: generatorModel.setAudioFileRegion(0, player.file.duration)
                }
                Item { Layout.fillWidth: true }
                Label { text: qsTr("Gain (dB)") }
                SelectableSpinBox {
                    from: -140; to: 0
                    value: generatorModel.gain
                    editable: true
                    enabled: player.local
                    onValueModified: generatorModel.gain = value
                    Accessible.name: qsTr("Generator gain in decibels")
                }
            }
            Rectangle { Layout.fillWidth: true; height: 1; color: applicationWindow.ui.separator }
            RowLayout {
                Layout.fillWidth: true
                enabled: player.local && !player.loading
                Label { text: qsTr("Output") }
                DropDown {
                    id: output
                    Layout.fillWidth: true
                    model: DeviceModel { id: outputs; scope: DeviceModel.OutputOnly }
                    textRole: "name"
                    currentIndex: outputs.indexOf(generatorModel.deviceId)
                    onActivated: generatorModel.deviceId = outputs.deviceId(currentIndex)
                    Accessible.name: qsTr("Audio output device")
                }
                GeneratorChannelSelect {
                    Layout.preferredWidth: 190
                    list: outputs.channelNames(output.currentIndex)
                    dataObject: generatorModel
                    tooltip: qsTr("Choose output channels")
                }
            }
            RowLayout {
                Layout.fillWidth: true
                Label { text: qsTr("File channels") }
                DropDown {
                    Layout.fillWidth: true
                    model: [qsTr("Stereo (L / R)"), qsTr("Mono (L + R)"), qsTr("Left only"), qsTr("Right only")]
                    currentIndex: player.file.mode || 0
                    enabled: player.playable
                    onActivated: generatorModel.setAudioFileMode(currentIndex)
                }
            }
            Label {
                Layout.fillWidth: true
                text: qsTr("Stereo sends L / R to selected outputs in order. The internal reference follows the first selected output. Stop returns to Start; Loop repeats Start–End.")
                wrapMode: Text.WordWrap
                font.pixelSize: 12
                opacity: 0.8
            }
        }
    }
}
