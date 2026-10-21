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
    DelayFinder { id: pill; width: 760; measurement: source; cursorFrequency: 1000 }
    function init() {
        source.active = true; source.error = false; source.inputAvailable = true;
        source.sampleRate = 48000; source.estimated = 480; source.delay = 0;
        pill.measurement = source; pill.width = 760; pill.feet = false;
        pill.cursorFrequency = 1000; pill.invalidate();
    }
    function test_conversionsAndUnits() {
        verify(!pill.usable);
        source.delayEstimateUpdated();
        compare(pill.delayMs, 10);
        fuzzyCompare(pill.distance, 3.432, 0.001);
        compare(pill.wavelengths, 10);
        wait(30);
        mouseClick(findChild(pill, "delayUnits"));
        fuzzyCompare(pill.distance, 11.26, 0.01);
        pill.cursorFrequency = 125;
        compare(pill.wavelengths, 1.25);
        source.sampleRate = 44100; source.estimated = -441;
        source.delayEstimateUpdated();
        compare(pill.delayMs, -10);
        compare(pill.wavelengths, -1.25);
    }
    function test_applyAbsoluteTarget() {
        source.delay = 240;
        source.delayEstimateUpdated();
        wait(30);
        mouseClick(findChild(pill, "applyReferenceDelay"));
        compare(source.delay, 480); // Do not add 480 to the existing 240.
        verify(!pill.usable);
        source.estimated = 0; source.delayEstimateUpdated();
        wait(30);
        mouseClick(findChild(pill, "applyReferenceDelay"));
        compare(source.delay, 0);
    }
    function test_unavailableAndExpiry() {
        var action = findChild(pill, "applyReferenceDelay");
        verify(!action.enabled);
        source.delayEstimateUpdated(); verify(action.enabled);
        source.active = false; verify(!action.enabled);
        source.active = true; verify(!action.enabled);
        source.delayEstimateUpdated(); source.error = true; verify(!action.enabled);
        source.error = false; source.delayEstimateUpdated();
        source.inputAvailable = false; verify(!action.enabled);
        source.inputAvailable = true; source.delayEstimateUpdated();
        tryCompare(pill, "fresh", false, 3500);
        verify(!action.enabled);
        pill.measurement = null;
        verify(!action.enabled);
        compare(pill.status, "Select measurement");
    }
    function test_cursorAndNarrowLayout() {
        pill.cursorFrequency = 0;
        source.delayEstimateUpdated();
        verify(!findChild(pill, "delayWavelengths").visible);
        pill.width = 280;
        wait(30);
        verify(pill.height > 40);
        var action = findChild(pill, "applyReferenceDelay");
        verify(action.x + action.width <= pill.width - 12);
        verify(action.y + action.height <= pill.height);
    }
}
