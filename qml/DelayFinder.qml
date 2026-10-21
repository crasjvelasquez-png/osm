import "elements"
import QtQuick 2.15
import QtQuick.Controls 2.15

Rectangle {
    id: finder
    objectName: "delayFinder"
    property color surfaceColor: colors.alternateBase
    property color textColor: colors.text
    property color outlineColor: colors.mid
    property var measurement: null
    property real cursorFrequency: 0
    property bool feet: false
    property bool fresh: false
    property real estimatedSamples: 0
    // Match Calculator.qml's default air temperature (20 °C).
    readonly property real speedOfSound: 20.05 * Math.sqrt(273.15 + 20)
    readonly property bool live: measurement !== null && measurement.active && !measurement.error
                                && measurement.inputAvailable && measurement.sampleRate > 0
    readonly property bool usable: live && fresh
    readonly property real delayMs: usable ? 1000 * estimatedSamples / measurement.sampleRate : 0
    readonly property real distance: delayMs / 1000 * speedOfSound * (feet ? 1 / 0.3048 : 1)
    readonly property real wavelengths: delayMs / 1000 * cursorFrequency
    readonly property bool hasFrequency: isFinite(cursorFrequency) && cursorFrequency > 0
    readonly property string status: !measurement ? qsTr("Select measurement")
                                    : !live ? qsTr("No live input")
                                    : !fresh ? qsTr("Measuring…") : measurement.name

    implicitWidth: title.implicitWidth + time.implicitWidth + apply.implicitWidth + 40
                   + (usable ? units.implicitWidth + 8 : 0)
                   + (usable && hasFrequency ? waves.implicitWidth + 8 : 0)
    implicitHeight: content.height + 8
    height: implicitHeight
    radius: applicationWindow.ui.controlRadius
    color: surfaceColor
    border.color: outlineColor
    SystemPalette { id: colors }

    function invalidate() { fresh = false; expiry.stop(); }
    function applyDelay() {
        if (!usable) return;
        // estimated is the absolute target, not a delta to add a second time.
        measurement.delay = Math.round(estimatedSamples);
        invalidate();
    }
    onMeasurementChanged: invalidate()
    Timer { id: expiry; interval: 3000; onTriggered: finder.fresh = false }
    Connections {
        target: finder.measurement
        ignoreUnknownSignals: true
        function onDelayEstimateUpdated() {
            if (!finder.live) return;
            finder.estimatedSamples = Number(finder.measurement.estimated);
            finder.fresh = true;
            expiry.restart();
        }
        function onActiveChanged() { finder.invalidate(); }
        function onErrorChanged() { finder.invalidate(); }
        function onDeviceIdChanged() { finder.invalidate(); }
        function onSampleRateChanged() { finder.invalidate(); }
        function onDataChanelChanged() { finder.invalidate(); }
        function onReferenceChanelChanged() { finder.invalidate(); }
        function onDelayChanged() { finder.invalidate(); }
    }

    Flow {
        id: content
        x: 12; y: 4
        width: parent.width - 24
        spacing: 8
        Label {
            id: title
            color: finder.textColor
            height: applicationWindow.ui.controlHeight; verticalAlignment: Text.AlignVCenter
            text: qsTr("Delay Finder"); font.bold: true
            HoverHandler { id: titleHover }
            ToolTip.visible: titleHover.hovered
            ToolTip.text: (finder.measurement ? finder.measurement.name + "\n" : "")
                          + qsTr("Total reference-delay target. Distance assumes 20 °C.\nMove the chart cursor to show wavelengths at that frequency.")
        }
        Label {
            id: time
            color: finder.textColor
            objectName: "delayTime"
            height: applicationWindow.ui.controlHeight; verticalAlignment: Text.AlignVCenter
            text: finder.usable ? finder.delayMs.toFixed(2) + " ms" : finder.status
        }
        StudioButton {
            id: units
            objectName: "delayUnits"
            visible: finder.usable
            height: applicationWindow.ui.controlHeight
            font.capitalization: Font.MixedCase
            leftPadding: 4; rightPadding: 4
            implicitWidth: contentItem.implicitWidth + 8
            flat: true
            text: finder.distance.toFixed(2) + (finder.feet ? " ft" : " m")
            onClicked: finder.feet = !finder.feet
            ToolTip.visible: hovered || activeFocus
            ToolTip.text: qsTr("Switch to %1 · assumes 20 °C").arg(finder.feet ? qsTr("metres") : qsTr("feet"))
            Accessible.name: qsTr("Distance %1. Switch distance units").arg(text)
        }
        Label {
            id: waves
            color: finder.textColor
            objectName: "delayWavelengths"
            visible: finder.usable && finder.hasFrequency
            height: applicationWindow.ui.controlHeight; verticalAlignment: Text.AlignVCenter
            text: finder.wavelengths.toFixed(2) + " λ"
            HoverHandler { id: waveHover }
            ToolTip.visible: waveHover.hovered
            ToolTip.text: qsTr("Wavelengths at %1 Hz").arg(finder.cursorFrequency.toFixed(0))
            Accessible.name: text + qsTr(" at %1 Hz").arg(finder.cursorFrequency.toFixed(0))
        }
        StudioButton {
            id: apply
            objectName: "applyReferenceDelay"
            height: applicationWindow.ui.controlHeight
            font.capitalization: Font.MixedCase
            text: qsTr("Apply")
            Accessible.name: qsTr("Apply to Reference Delay")
            enabled: finder.usable
            onClicked: finder.applyDelay()
            ToolTip.visible: hovered || activeFocus
            ToolTip.text: qsTr("Apply to Reference Delay")
        }
    }
}
