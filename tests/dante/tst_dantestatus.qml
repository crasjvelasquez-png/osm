/**
 *  OSM
 *  Copyright (C) 2026  Pavel Smokotnin
 *
 *  This program is free software: you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation, either version 3 of the License, or
 *  (at your option) any later version.
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */
import QtQuick 2.15
import QtTest 1.2
import "../../qml"

TestCase {
    id: testCase
    name: "DanteStatusUi"
    visible: true
    width: 800; height: 400
    when: windowShown

    QtObject {
        id: mockAppearance
        property bool darkMode: true
    }

    QtObject {
        id: mockWindow
        property int width: 1200
        readonly property QtObject ui: StudioTheme { darkMode: mockAppearance.darkMode }
    }

    QtObject {
        id: mockDanteMonitor
        property bool enabled: false
        property string primaryRoleState: "Off"
        property string secondaryRoleState: "Off"
        property string primaryAdapter: ""
        property string secondaryAdapter: ""
        property string primaryReason: ""
        property string secondaryReason: ""
        property string degradedReason: ""
        property string providerStatus: "ConMon running"
        property string networkDiscoveryState: "No Dante devices detected"
        property string lastObservationTime: "Just now"
        property string scope: "This Mac: Network Links"
        property bool fixtureMode: false
        property string overallStatusText: "Dante Monitoring: Off"
    }

    // In production, these are injected in QML engine root context:
    property alias applicationAppearance: mockAppearance
    property alias applicationWindow: mockWindow
    property alias danteMonitor: mockDanteMonitor

    DanteStatus {
        id: statusItem
        anchors.centerIn: parent
        compact: mockWindow.width < 1024
    }

    SignalSpy {
        id: clickSpy
        target: statusItem
        signalName: "clicked"
    }

    function init() {
        clickSpy.clear();
        mockWindow.width = 1200;
        mockAppearance.darkMode = true;
        mockDanteMonitor.enabled = false;
        mockDanteMonitor.fixtureMode = false;
        mockDanteMonitor.primaryRoleState = "Off";
        mockDanteMonitor.secondaryRoleState = "Off";
        mockDanteMonitor.overallStatusText = "Dante Monitoring: Off";
    }

    function test_initialOffState() {
        compare(statusItem.compact, false);
        compare(mockDanteMonitor.enabled, false);
        verify(statusItem.Accessible.name.indexOf("Off") !== -1);
    }

    function test_compactModeToggle() {
        mockWindow.width = 1200;
        compare(statusItem.compact, false);

        mockWindow.width = 800;
        compare(statusItem.compact, true);
    }

    function test_clickAndKeyboardActivation() {
        clickSpy.clear();
        mouseClick(statusItem);
        compare(clickSpy.count, 1);

        statusItem.forceActiveFocus();
        verify(statusItem.activeFocus);
        keyClick(Qt.Key_Return);
        compare(clickSpy.count, 2);

        keyClick(Qt.Key_Space);
        compare(clickSpy.count, 3);
    }

    function test_fixtureDisplay() {
        mockDanteMonitor.enabled = true;
        mockDanteMonitor.fixtureMode = true;
        mockDanteMonitor.primaryRoleState = "Up";
        mockDanteMonitor.secondaryRoleState = "Up";
        mockDanteMonitor.overallStatusText = "[FIXTURE] Dante: Primary Up · Secondary Up";

        verify(statusItem.Accessible.name.indexOf("[FIXTURE]") !== -1);
    }

    function test_themeSwitching() {
        mockAppearance.darkMode = true;
        compare(statusItem.stateColor("Up"), "#2ECC71");
        compare(statusItem.stateColor("Down"), "#E74C3C");
        compare(statusItem.stateColor("Degraded"), "#F39C12");

        mockAppearance.darkMode = false;
        compare(statusItem.stateColor("Up"), "#2ECC71");
        compare(statusItem.stateColor("Down"), "#E74C3C");
        compare(statusItem.stateColor("Degraded"), "#F39C12");
    }
}
