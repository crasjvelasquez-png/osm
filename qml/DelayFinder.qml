import "elements"
import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

Rectangle {
    id: finder
    objectName: "delayFinder"

    property color surfaceColor: colors.alternateBase
    property color textColor: colors.text
    property color outlineColor: colors.mid
    property var measurement: null
    property real cursorFrequency: 0
    property bool feet: false

    // Match Calculator.qml's default air temperature (20 °C).
    readonly property real speedOfSound: 20.05 * Math.sqrt(273.15 + 20)

    // Capture & held state
    property bool hasHeldResult: false
    property real heldSamples: 0
    property var capturedMeasurement: null
    property string capturedMeasurementName: ""
    property int capturedSampleRate: 0
    property int capturedCurrentDelaySamples: 0
    property int appliedDelaySamples: 0
    property string unstableReason: "" // "insufficient" or "variable"

    // Configurable capture parameters
    property int captureDurationMs: 2000
    property int minEstimateCount: 3
    property real repeatabilityThresholdMs: 0.10

    // Internal state
    property var collectedSamples: []
    property double lastEstimateTimeMs: 0
    property bool applyingDelay: false

    readonly property bool live: measurement !== null &&
                                Boolean(measurement.active) &&
                                !measurement.error &&
                                Boolean(measurement.inputAvailable) &&
                                measurement.sampleRate > 0

    readonly property bool usable: live && hasHeldResult && state === "held"
    readonly property bool fresh: hasHeldResult

    readonly property real delayMs: hasHeldResult && capturedSampleRate > 0 ?
                                    1000 * heldSamples / capturedSampleRate : 0

    readonly property real distance: delayMs / 1000 * speedOfSound * (feet ? 1 / 0.3048 : 1)
    readonly property real wavelengths: delayMs / 1000 * cursorFrequency
    readonly property bool hasFrequency: isFinite(cursorFrequency) && cursorFrequency > 0

    readonly property real measuredMs: delayMs
    readonly property real currentDelayMs: (state === "applied") ? delayMs :
        (capturedSampleRate > 0 ? 1000 * capturedCurrentDelaySamples / capturedSampleRate : 0)
    readonly property real changeMs: (state === "applied") ? 0 :
        (capturedSampleRate > 0 ? 1000 * (heldSamples - capturedCurrentDelaySamples) / capturedSampleRate : 0)

    function formatChange(val) {
        if (state === "applied") return "+0.00 ms";
        return (val >= 0 ? "+" : "") + val.toFixed(2) + " ms";
    }

    readonly property string status: !measurement ? qsTr("Select measurement") :
                                    !live ? qsTr("No live input") :
                                    state === "capturing" ? qsTr("Finding…") :
                                    state === "unstable" ? (unstableReason === "insufficient" ?
                                        qsTr("Not enough readings — find again") :
                                        qsTr("Readings vary — find again")) :
                                    (state === "held" || state === "applied") ? (delayMs.toFixed(2) + " ms") :
                                    qsTr("Ready")

    state: live ? "idle" : "unavailable"

    states: [
        State { name: "idle" },
        State { name: "capturing" },
        State { name: "held" },
        State { name: "applied" },
        State { name: "unstable" },
        State { name: "unavailable" }
    ]

    implicitWidth: content.implicitWidth + 24
    implicitHeight: content.height + 8
    height: implicitHeight
    radius: applicationWindow.ui.controlRadius
    color: surfaceColor
    border.color: outlineColor

    SystemPalette { id: colors }

    function startCapture() {
        if (!live) return;
        captureTimer.stop();
        collectedSamples = [];
        hasHeldResult = false;
        heldSamples = 0;
        unstableReason = "";
        if (detailsPopup.opened) {
            detailsPopup.close();
        }
        capturedMeasurement = measurement;
        capturedMeasurementName = measurement && measurement.name ? measurement.name : "";
        capturedSampleRate = measurement ? measurement.sampleRate : 0;
        capturedCurrentDelaySamples = measurement ? measurement.delay : 0;
        state = "capturing";
        captureTimer.interval = captureDurationMs;
        captureTimer.start();
    }

    function cancelCapture() {
        captureTimer.stop();
        collectedSamples = [];
        state = live ? "idle" : "unavailable";
    }

    function finishCapture() {
        captureTimer.stop();
        if (state !== "capturing") return;

        if (collectedSamples.length < minEstimateCount) {
            unstableReason = "insufficient";
            state = "unstable";
            return;
        }

        let min = collectedSamples[0];
        let max = collectedSamples[0];
        for (let i = 1; i < collectedSamples.length; ++i) {
            if (collectedSamples[i] < min) min = collectedSamples[i];
            if (collectedSamples[i] > max) max = collectedSamples[i];
        }

        const thresholdSamples = Math.max(1, Math.ceil(capturedSampleRate * (repeatabilityThresholdMs / 1000)));
        if ((max - min) <= thresholdSamples) {
            const sorted = collectedSamples.slice().sort(function(a, b) { return a - b; });
            const mid = Math.floor(sorted.length / 2);
            const median = (sorted.length % 2 === 0) ? (sorted[mid - 1] + sorted[mid]) / 2 : sorted[mid];
            heldSamples = Math.round(median);
            hasHeldResult = true;
            state = "held";
        } else {
            unstableReason = "variable";
            state = "unstable";
        }
    }

    function invalidate() {
        captureTimer.stop();
        collectedSamples = [];
        hasHeldResult = false;
        heldSamples = 0;
        unstableReason = "";
        if (detailsPopup && detailsPopup.opened) {
            detailsPopup.close();
        }
        state = live ? "idle" : "unavailable";
    }

    function applyDelay() {
        if (state !== "held" || !hasHeldResult || !live || !measurement) return;
        if (measurement !== capturedMeasurement || measurement.sampleRate !== capturedSampleRate) {
            invalidate();
            return;
        }
        applyingDelay = true;
        try {
            measurement.delay = Math.round(heldSamples);
            appliedDelaySamples = Math.round(heldSamples);
            state = "applied";
        } finally {
            applyingDelay = false;
        }
    }

    onMeasurementChanged: {
        invalidate();
    }

    onVisibleChanged: {
        if (!visible) {
            if (state === "capturing") {
                cancelCapture();
            }
            if (detailsPopup.opened) {
                detailsPopup.close();
            }
        }
    }

    Component.onDestruction: {
        cancelCapture();
        invalidate();
    }

    Timer {
        id: captureTimer
        repeat: false
        onTriggered: finder.finishCapture()
    }

    Timer {
        id: watchdogTimer
        interval: 250
        repeat: true
        running: true
        onTriggered: {
            const isCurrentlyLive = finder.measurement !== null &&
                                    Boolean(finder.measurement.active) &&
                                    !finder.measurement.error &&
                                    Boolean(finder.measurement.inputAvailable) &&
                                    finder.measurement.sampleRate > 0;

            if (!isCurrentlyLive) {
                if (finder.state === "capturing") {
                    finder.cancelCapture();
                }
                if (finder.hasHeldResult || finder.state === "held" || finder.state === "applied" || finder.state === "unstable") {
                    finder.invalidate();
                } else if (finder.state !== "unavailable") {
                    finder.state = "unavailable";
                }
                return;
            }

            if (finder.state === "unavailable") {
                finder.state = "idle";
            }

            // Check heartbeat: invalidate if no estimate received for > 3000 ms
            if (finder.hasHeldResult || finder.state === "capturing" || finder.state === "held" || finder.state === "applied") {
                if (finder.lastEstimateTimeMs > 0 && (Date.now() - finder.lastEstimateTimeMs > 3000)) {
                    finder.invalidate();
                }
            }
        }
    }

    Connections {
        target: finder.measurement
        ignoreUnknownSignals: true
        function onDelayEstimateUpdated() {
            finder.lastEstimateTimeMs = Date.now();
            if (finder.state === "capturing" && finder.live) {
                const est = Number(finder.measurement.estimated);
                if (isFinite(est)) {
                    finder.collectedSamples.push(est);
                }
            }
        }
        function onActiveChanged() { finder.invalidate(); }
        function onErrorChanged() { finder.invalidate(); }
        function onDeviceIdChanged() { finder.invalidate(); }
        function onSampleRateChanged() { finder.invalidate(); }
        function onDataChanelChanged() { finder.invalidate(); }
        function onReferenceChanelChanged() { finder.invalidate(); }
        function onInputFilterChanged() { finder.invalidate(); }
        function onWindowFunctionTypeChanged() { finder.invalidate(); }
        function onDelayChanged() {
            if (finder.applyingDelay) return;
            finder.invalidate();
        }
        function onLevelChanged() {
            if (!finder.live) {
                finder.invalidate();
            }
        }
    }

    Flickable {
        x: 12; y: 4
        width: parent.width - 24
        height: content.implicitHeight
        contentWidth: content.implicitWidth
        contentHeight: height
        flickableDirection: Flickable.HorizontalFlick
        boundsBehavior: Flickable.StopAtBounds
        clip: true

        Row {
            id: content
            spacing: 8

            Label {
                id: title
                color: finder.textColor
                height: applicationWindow.ui.controlHeight
                verticalAlignment: Text.AlignVCenter
                text: qsTr("Delay Finder")
                font.bold: true
                font.family: applicationWindow.ui.fontFamily
                font.pixelSize: applicationWindow.ui.controlFontSize
                HoverHandler { id: titleHover }
                ToolTip.visible: titleHover.hovered
                ToolTip.text: (finder.measurement ? finder.measurement.name + "\n" : "")
                              + qsTr("Total reference-delay target. Distance assumes 20 °C.\nMove the chart cursor to show wavelengths at that frequency.")
            }

            Label {
                id: time
                objectName: "delayTime"
                color: finder.textColor
                height: applicationWindow.ui.controlHeight
                verticalAlignment: Text.AlignVCenter
                font.family: applicationWindow.ui.fontFamily
                font.pixelSize: applicationWindow.ui.controlFontSize
                width: (finder.state === "held" || finder.state === "applied") ?
                       Math.max(76, contentWidth) : contentWidth
                text: (finder.state === "held" || finder.state === "applied") ?
                      (finder.delayMs.toFixed(2) + " ms") : finder.status
            }

            Label {
                id: appliedBadge
                objectName: "appliedBadge"
                visible: finder.state === "applied"
                color: applicationWindow.ui.secondaryText
                height: applicationWindow.ui.controlHeight
                verticalAlignment: Text.AlignVCenter
                font.family: applicationWindow.ui.fontFamily
                font.pixelSize: applicationWindow.ui.secondaryFontSize
                text: qsTr("Applied")
            }

            StudioButton {
                id: findButton
                objectName: "findDelay"
                height: applicationWindow.ui.controlHeight
                font.capitalization: Font.MixedCase
                implicitWidth: Math.max(96, contentItem.implicitWidth + leftPadding + rightPadding)
                text: finder.state === "capturing" ? qsTr("Cancel") :
                      (finder.hasHeldResult || finder.state === "unstable" || finder.state === "applied") ?
                      qsTr("Find again") : qsTr("Find Delay")
                enabled: finder.state === "capturing" ? true : finder.live
                onClicked: {
                    if (finder.state === "capturing") {
                        finder.cancelCapture();
                    } else {
                        finder.startCapture();
                    }
                }
                ToolTip.visible: hovered || activeFocus
                ToolTip.text: finder.state === "capturing" ? qsTr("Cancel delay capture") :
                              finder.hasHeldResult ? qsTr("Capture delay estimate again") :
                              qsTr("Capture delay estimate over 2 seconds")
            }

            StudioButton {
                id: apply
                objectName: "applyReferenceDelay"
                height: applicationWindow.ui.controlHeight
                font.capitalization: Font.MixedCase
                implicitWidth: Math.max(64, contentItem.implicitWidth + leftPadding + rightPadding)
                text: qsTr("Apply")
                Accessible.name: qsTr("Apply to Reference Delay")
                enabled: finder.state === "held" && finder.live && finder.hasHeldResult
                onClicked: finder.applyDelay()
                ToolTip.visible: hovered || activeFocus
                ToolTip.text: qsTr("Apply to Reference Delay")
            }

            StudioButton {
                id: detailsButton
                objectName: "delayDetails"
                height: applicationWindow.ui.controlHeight
                font.capitalization: Font.MixedCase
                implicitWidth: Math.max(68, contentItem.implicitWidth + leftPadding + rightPadding)
                text: qsTr("Details")
                enabled: finder.hasHeldResult
                onClicked: {
                    if (detailsPopup.opened) {
                        detailsPopup.close();
                    } else {
                        detailsPopup.open();
                    }
                }
                ToolTip.visible: hovered || activeFocus
                ToolTip.text: qsTr("Show delay details, distance, and wavelength")
            }
        }

    }

    Popup {
        id: detailsPopup
        objectName: "delayDetailsPopup"
        parent: detailsButton
        y: detailsButton.height + 6
        x: Math.min(0, Math.max(-200, -(width - detailsButton.width)))
        width: 280
        padding: 12
        modal: false
        focus: true
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutsideParent
        onClosed: {
            if (detailsButton.enabled) {
                detailsButton.forceActiveFocus();
            }
        }
        background: Rectangle {
            color: applicationWindow.ui.panel
            radius: applicationWindow.ui.controlRadius
            border.color: applicationWindow.ui.separator
        }
        contentItem: ColumnLayout {
            spacing: 8
            Label {
                id: detailsTitle
                Layout.fillWidth: true
                text: finder.capturedMeasurementName
                font.bold: true
                font.family: applicationWindow.ui.fontFamily
                font.pixelSize: applicationWindow.ui.controlFontSize
                color: applicationWindow.ui.text
                elide: Text.ElideRight
                HoverHandler { id: detailsTitleHover }
                ToolTip.visible: detailsTitleHover.hovered && detailsTitle.truncated
                ToolTip.text: finder.capturedMeasurementName
            }
            GridLayout {
                columns: 2
                columnSpacing: 12
                rowSpacing: 4
                Layout.fillWidth: true

                Label {
                    text: qsTr("Measured")
                    color: applicationWindow.ui.secondaryText
                    font.family: applicationWindow.ui.fontFamily
                    font.pixelSize: applicationWindow.ui.secondaryFontSize
                }
                Label {
                    id: measuredDelayLabel
                    objectName: "measuredDelay"
                    Layout.alignment: Qt.AlignRight
                    text: finder.measuredMs.toFixed(2) + " ms"
                    color: applicationWindow.ui.text
                    font.family: applicationWindow.ui.fontFamily
                    font.pixelSize: applicationWindow.ui.secondaryFontSize
                }

                Label {
                    text: qsTr("Current")
                    color: applicationWindow.ui.secondaryText
                    font.family: applicationWindow.ui.fontFamily
                    font.pixelSize: applicationWindow.ui.secondaryFontSize
                }
                Label {
                    id: currentDelayLabel
                    objectName: "currentDelay"
                    Layout.alignment: Qt.AlignRight
                    text: finder.currentDelayMs.toFixed(2) + " ms"
                    color: applicationWindow.ui.text
                    font.family: applicationWindow.ui.fontFamily
                    font.pixelSize: applicationWindow.ui.secondaryFontSize
                }

                Label {
                    text: qsTr("Change")
                    color: applicationWindow.ui.secondaryText
                    font.family: applicationWindow.ui.fontFamily
                    font.pixelSize: applicationWindow.ui.secondaryFontSize
                }
                Label {
                    id: changeDelayLabel
                    objectName: "changeDelay"
                    Layout.alignment: Qt.AlignRight
                    text: finder.formatChange(finder.changeMs)
                    color: applicationWindow.ui.text
                    font.family: applicationWindow.ui.fontFamily
                    font.pixelSize: applicationWindow.ui.secondaryFontSize
                }
            }
            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: applicationWindow.ui.separator
            }
            RowLayout {
                Layout.fillWidth: true
                Label {
                    Layout.fillWidth: true
                    text: qsTr("Equivalent distance (20 °C)")
                    color: applicationWindow.ui.secondaryText
                    font.family: applicationWindow.ui.fontFamily
                    font.pixelSize: applicationWindow.ui.secondaryFontSize
                    wrapMode: Text.WordWrap
                }
                StudioButton {
                    id: units
                    objectName: "delayUnits"
                    height: applicationWindow.ui.controlHeight - 6
                    font.capitalization: Font.MixedCase
                    leftPadding: 6; rightPadding: 6
                    flat: true
                    text: finder.distance.toFixed(2) + (finder.feet ? " ft" : " m")
                    onClicked: finder.feet = !finder.feet
                    ToolTip.visible: hovered || activeFocus
                    ToolTip.text: qsTr("Switch to %1 · assumes 20 °C").arg(finder.feet ? qsTr("metres") : qsTr("feet"))
                    Accessible.name: qsTr("Distance %1. Switch distance units").arg(text)
                }
            }
            RowLayout {
                id: waveRow
                objectName: "delayWavelengths"
                Layout.fillWidth: true
                visible: finder.hasFrequency
                Label {
                    Layout.fillWidth: true
                    text: qsTr("Wavelengths at %1 Hz").arg(finder.cursorFrequency.toFixed(0))
                    color: applicationWindow.ui.secondaryText
                    font.family: applicationWindow.ui.fontFamily
                    font.pixelSize: applicationWindow.ui.secondaryFontSize
                }
                Label {
                    text: finder.wavelengths.toFixed(2) + " λ"
                    color: applicationWindow.ui.text
                    font.family: applicationWindow.ui.fontFamily
                    font.pixelSize: applicationWindow.ui.secondaryFontSize
                }
            }
        }
    }
}
