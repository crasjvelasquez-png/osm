import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Controls.Material 2.15
import QtTest 1.2
import "../../qml"
import "../../qml/elements"

TestCase {
    id: suite
    name: "StudioControls"
    width: 768; height: 540
    visible: true
    when: windowShown
    QtObject {
        id: applicationWindow
        readonly property QtObject ui: StudioTheme { id: theme }
        readonly property color accentColor: ui.primary
    }
    Column {
        x: 16; y: 16; spacing: 8
        StudioButton { id: action; text: "Save defaults"; highlighted: true }
        StudioButton { id: iconAction; text: "+"; flat: true; width: 28; height: 28; leftPadding: 4; rightPadding: 4 }
        DropDown { id: choice; width: 240; model: ["Off", "Low-pass smoothing (LPF)", "Rolling frames (FIFO)"] }
        TitledCombo { id: resolution; title: "ppo"; tooltip: "points per octave"; model: ["off", "48"] }
        SelectableSpinBox { id: number; from: -100; to: 100; editable: true }
        StudioTextField { id: field; width: 240; text: "A very long measurement name for elision and editing" }
    }
    function test_focusAndNumericEditing() {
        action.forceActiveFocus(Qt.TabFocusReason);
        verify(action.activeFocus);
        keyClick(Qt.Key_Tab);
        verify(iconAction.activeFocus);
        number.forceActiveFocus(Qt.TabFocusReason);
        keyClick(Qt.Key_A, Qt.ControlModifier);
        keyClick(Qt.Key_4); keyClick(Qt.Key_2);
        keyClick(Qt.Key_Return);
        compare(number.value, 42);
        number.forceActiveFocus(); keyClick(Qt.Key_Up);
        compare(number.value, 43);
        field.forceActiveFocus();
        keyClick(Qt.Key_A, Qt.ControlModifier); keyClick(Qt.Key_T);
        compare(field.text, "t");
    }
    function test_dropdownKeyboard() {
        choice.currentIndex = 0;
        choice.forceActiveFocus();
        keyClick(Qt.Key_Space);
        tryCompare(choice.popup, "visible", true);
        keyClick(Qt.Key_Down); keyClick(Qt.Key_Return);
        compare(choice.currentIndex, 1);
        tryCompare(choice.popup, "visible", false);
    }
    function test_titledDropdownFits() {
        resolution.currentIndex = 0;
        verify(resolution.width >= resolution.contentItem.implicitWidth + resolution.leftPadding + resolution.rightPadding);
        verify(resolution.width >= 110);
        compare(resolution.Accessible.name, "points per octave");
    }
    function test_themesAndBounds_data() {
        return [{tag:"dark-min", dark:true, w:768, h:540}, {tag:"light-min", dark:false, w:768, h:540},
                {tag:"dark-medium", dark:true, w:1024, h:768}, {tag:"light-medium", dark:false, w:1024, h:768},
                {tag:"dark-wide", dark:true, w:1440, h:900}, {tag:"light-wide", dark:false, w:1440, h:900}];
    }
    function test_themesAndBounds(data) {
        theme.darkMode = data.dark; suite.width = data.w; suite.height = data.h;
        wait(20);
        compare(action.height, 36); compare(choice.height, 36); compare(number.height, 36); compare(field.height, 36);
        compare(action.font.pixelSize, 13);
        verify(action.contentItem.paintedWidth <= action.availableWidth);
        verify(action.contentItem.paintedHeight <= action.availableHeight);
        compare(action.background.radius, 6);
        action.enabled = false;
        verify(action.contentItem.color.toString() === theme.secondaryText.toString());
        action.enabled = true;
        compare(action.contentItem.color.toString(), "#ffffff");
    }
}
