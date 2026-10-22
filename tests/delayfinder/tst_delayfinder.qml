import QtQuick 2.15
import QtTest 1.2
import "../../qml"

TestCase {
    id: testCase
    name: "DelayFinder"
    visible: true
    width: 900; height: 300
    when: windowShown

    QtObject {
        id: applicationWindow
        readonly property QtObject ui: StudioTheme {}
    }

    QtObject {
        id: source
        property bool active: true
        property bool error: false
        property bool inputAvailable: true
        property int sampleRate: 48000
        property int estimated: 480
        property int delay: 0
        property string name: "Test measurement"
        signal delayEstimateUpdated()
    }

    DelayFinder {
        id: pill
        width: 760
        measurement: source
        cursorFrequency: 1000
        captureDurationMs: 50
    }

    function init() {
        source.active = true;
        source.error = false;
        source.inputAvailable = true;
        source.sampleRate = 48000;
        source.estimated = 480;
        source.delay = 0;
        pill.measurement = source;
        pill.width = 760;
        pill.feet = false;
        pill.cursorFrequency = 1000;
        pill.captureDurationMs = 50;
        pill.invalidate();
    }

    function test_findHoldApplyHappyPath() {
        var findBtn = findChild(pill, "findDelay");
        var applyBtn = findChild(pill, "applyReferenceDelay");
        var detailsBtn = findChild(pill, "delayDetails");

        verify(findBtn.enabled);
        verify(!applyBtn.enabled);
        verify(!detailsBtn.enabled);
        compare(pill.state, "idle");

        // Start capture
        mouseClick(findBtn);
        compare(pill.state, "capturing");
        compare(findBtn.text, "Cancel");

        // Emit 4 consistent estimates (480 samples = 10.00 ms at 48 kHz)
        source.estimated = 480;
        source.delayEstimateUpdated();
        source.delayEstimateUpdated();
        source.delayEstimateUpdated();
        source.delayEstimateUpdated();

        // Wait for capture timer to finish
        tryCompare(pill, "state", "held", 300);
        compare(pill.delayMs, 10.00);
        verify(applyBtn.enabled);
        verify(detailsBtn.enabled);
        compare(findBtn.text, "Find again");

        // Apply delay
        mouseClick(applyBtn);
        compare(pill.state, "applied");
        compare(source.delay, 480);
        verify(!applyBtn.enabled);
        verify(findBtn.enabled);
    }

    function test_repeatabilityRejection() {
        var findBtn = findChild(pill, "findDelay");
        var applyBtn = findChild(pill, "applyReferenceDelay");

        // Start capture
        mouseClick(findBtn);
        compare(pill.state, "capturing");

        // Emit 4 readings with large variance (> 0.10 ms = 4.8 samples at 48k)
        source.estimated = 480;
        source.delayEstimateUpdated();
        source.estimated = 550;
        source.delayEstimateUpdated();
        source.estimated = 480;
        source.delayEstimateUpdated();
        source.estimated = 530;
        source.delayEstimateUpdated();

        tryCompare(pill, "state", "unstable", 300);
        verify(!applyBtn.enabled);
        compare(pill.status, "Readings vary — find again");
    }

    function test_insufficientReadingsRejection() {
        var findBtn = findChild(pill, "findDelay");
        var applyBtn = findChild(pill, "applyReferenceDelay");

        mouseClick(findBtn);
        compare(pill.state, "capturing");

        // Only 1 reading (< minEstimateCount of 3)
        source.estimated = 480;
        source.delayEstimateUpdated();

        tryCompare(pill, "state", "unstable", 300);
        verify(!applyBtn.enabled);
        compare(pill.status, "Not enough readings — find again");
    }

    function test_cancelCapture() {
        var findBtn = findChild(pill, "findDelay");
        var applyBtn = findChild(pill, "applyReferenceDelay");

        mouseClick(findBtn);
        compare(pill.state, "capturing");
        compare(findBtn.text, "Cancel");

        // Cancel during capture
        mouseClick(findBtn);
        compare(pill.state, "idle");
        verify(!applyBtn.enabled);
        compare(findBtn.text, "Find Delay");
    }

    function test_detailsPopupAndConversions() {
        var findBtn = findChild(pill, "findDelay");
        var detailsBtn = findChild(pill, "delayDetails");

        source.delay = 120; // Current delay = 2.50 ms
        source.estimated = 480; // Measured = 10.00 ms
        mouseClick(findBtn);
        source.delayEstimateUpdated();
        source.delayEstimateUpdated();
        source.delayEstimateUpdated();
        source.delayEstimateUpdated();
        tryCompare(pill, "state", "held", 300);

        fuzzyCompare(pill.distance, 3.432, 0.01);
        compare(pill.wavelengths, 10);

        // Open details
        mouseClick(detailsBtn);
        var popup = findChild(pill, "delayDetailsPopup");
        verify(popup !== null);
        tryCompare(popup, "opened", true, 300);

        // Check unit toggle
        var unitBtn = findChild(pill, "delayUnits");
        verify(unitBtn !== null);
        mouseClick(unitBtn);
        verify(pill.feet);
        fuzzyCompare(pill.distance, 11.26, 0.05);

        // Check wavelength at different cursor frequency
        pill.cursorFrequency = 125;
        compare(pill.wavelengths, 1.25);

        popup.close();
        tryCompare(popup, "opened", false, 300);
    }

    function test_invalidationOnSourceChange() {
        var findBtn = findChild(pill, "findDelay");
        var applyBtn = findChild(pill, "applyReferenceDelay");

        // Get to held state
        mouseClick(findBtn);
        source.estimated = 480;
        source.delayEstimateUpdated();
        source.delayEstimateUpdated();
        source.delayEstimateUpdated();
        source.delayEstimateUpdated();
        tryCompare(pill, "state", "held", 300);
        verify(applyBtn.enabled);

        // Changing active state invalidates
        source.active = false;
        tryCompare(pill, "state", "unavailable", 400);
        verify(!applyBtn.enabled);

        source.active = true;
        tryCompare(pill, "state", "idle", 400);

        // Get to held state again
        mouseClick(findBtn);
        source.delayEstimateUpdated();
        source.delayEstimateUpdated();
        source.delayEstimateUpdated();
        source.delayEstimateUpdated();
        tryCompare(pill, "state", "held", 300);

        // Measurement becomes null invalidates
        pill.measurement = null;
        compare(pill.status, "Select measurement");
        verify(!applyBtn.enabled);
    }

    function test_cursorAndNarrowLayout() {
        pill.cursorFrequency = 0;
        verify(!pill.hasFrequency);
        wait(30);
        var rowHeight = pill.height;
        pill.width = 280;
        wait(30);
        compare(pill.height, rowHeight);
        var findBtn = findChild(pill, "findDelay");
        var applyBtn = findChild(pill, "applyReferenceDelay");
        var detailsBtn = findChild(pill, "delayDetails");
        compare(findBtn.y, applyBtn.y);
        compare(findBtn.y, detailsBtn.y);
        verify(applyBtn.x >= findBtn.x + findBtn.width);
        verify(detailsBtn.x >= applyBtn.x + applyBtn.width);
        verify(pill.implicitWidth > pill.width);
    }
}
