/* Continuous level status. Analysis and calibration remain owned by Measurement. */
import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.3
import OpenSoundMeter 1.0
import "elements"

Rectangle {
    id: header
    height: 56
    color: applicationWindow.ui.shell
    property string monitoredId: ""
    readonly property var source: {
        sourceList.count;
        var item = monitoredId ? sourceList.getByUUid(monitoredId) : null;
        return item && item.objectName === "Measurement" ? item.data : null;
    }
    readonly property bool live: !!source && source.active && !source.error && source.inputAvailable
    readonly property real headroom: live ? source.inputHeadroom : NaN
    readonly property bool clipping: live && headroom <= 0
    readonly property bool lowHeadroom: live && headroom < 6
    readonly property color warningColor: applicationAppearance.darkMode ? "#FFB86B" : "#8A4700"
    readonly property color clipColor: applicationAppearance.darkMode ? "#FF9696" : "#B02030"
    readonly property string state: !source ? qsTr("Select a live measurement") :
        source.error ? qsTr("Input unavailable") : !source.active ? qsTr("Stopped") :
        !source.inputAvailable ? qsTr("Waiting for input") : clipping ? qsTr("Clipping") :
        lowHeadroom ? qsTr("Low headroom") : qsTr("Live input")

    function followSelection() {
        var selected = sourceList.selected;
        if (selected && selected.objectName === "Measurement") {
            monitoredId = selected.uuid.toString();
            return;
        }
        if (source) return; // Keep monitoring while inspecting saved traces.
        monitoredId = "";
        for (var i = 0; i < sourceList.count; ++i) {
            var candidate = sourceList.get(i);
            if (candidate && candidate.objectName === "Measurement") {
                monitoredId = candidate.uuid.toString();
                return;
            }
        }
    }
    Component.onCompleted: followSelection()
    Connections {
        target: sourceList
        function onSelectedChanged() { header.followSelection(); }
        function onCountChanged() { header.followSelection(); }
        function onLoaded() { header.followSelection(); }
    }

    MeterPlot {
        id: aSlow
        list: sourceList
        source: header.source ? header.source.uuid : "00000000-0000-0000-0000-000000000000"
        curve: "A"; time: "Slow"; type: "RMS"
    }
    MeterPlot {
        id: cFast
        list: sourceList
        source: header.source ? header.source.uuid : "00000000-0000-0000-0000-000000000000"
        curve: "C"; time: "Fast"; type: "RMS"
    }
    MeterPlot {
        id: zSlow
        list: sourceList
        source: header.source ? header.source.uuid : "00000000-0000-0000-0000-000000000000"
        curve: header.splCurve; time: header.splResponse; type: "RMS"
        peakHold: header.splPeakHold
    }
    property bool averageSPL: false
    property string splCurve: "Z"
    property string splResponse: "Slow"
    property string splWindow: "  1 min"
    property bool splPeakHold: false
    readonly property var splMeter: averageSPL ? averageLoader.item : zSlow
    readonly property string splLabel: "SPL (" + splCurve + " " +
        (averageSPL ? "Leq " + splWindow.trim() : splResponse) + (splPeakHold ? " max" : "") + ")"
    // Recreate the averaging meter when its input or weighting changes so history cannot mix.
    function restartAverage() {
        averageLoader.active = false;
        averageLoader.active = averageSPL && !!source;
    }
    onAverageSPLChanged: restartAverage()
    onSourceChanged: restartAverage()
    onSplCurveChanged: restartAverage()
    onSplWindowChanged: restartAverage()
    Loader {
        id: averageLoader
        active: false
        sourceComponent: Component {
            MeterPlot {
                list: sourceList
                source: header.source ? header.source.uuid : "00000000-0000-0000-0000-000000000000"
                type: "Leq"; curve: header.splCurve; time: header.splWindow
                peakHold: header.splPeakHold
            }
        }
    }
    function reading(value) {
        if (!live) return "—";
        var number = Number(value);
        return isFinite(number) ? number.toFixed(1) : "−∞";
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 16; anchors.rightMargin: 16
        spacing: 16
        ColumnLayout {
            Layout.fillWidth: true
            Layout.minimumWidth: 0
            spacing: 2
            Label {
                Layout.fillWidth: true
                text: header.source ? header.source.name : qsTr("Input monitor")
                elide: Text.ElideRight
                color: applicationWindow.ui.text
                font.pixelSize: 13; font.weight: Font.DemiBold
            }
            Label {
                Layout.fillWidth: true
                text: header.state
                elide: Text.ElideRight
                color: header.clipping ? header.clipColor : header.lowHeadroom ? header.warningColor : applicationWindow.ui.secondaryText
                font.pixelSize: applicationWindow.ui.secondaryFontSize
            }
        }
        Control {
            id: readings
            Layout.preferredWidth: 438
            Layout.minimumWidth: 438
            Layout.preferredHeight: 48
            hoverEnabled: true
            activeFocusOnTab: true
            Accessible.role: Accessible.Grouping
            Accessible.name: qsTr("Input levels for %1. %2. dBA Slow %3. dBC Fast %4. %5 %6 dB.")
                .arg(header.source ? header.source.name : qsTr("no measurement")).arg(header.state)
                .arg(header.reading(aSlow.value)).arg(header.reading(cFast.value)).arg(header.splLabel).arg(header.reading(header.splMeter ? header.splMeter.value : NaN))
            background: Rectangle {
                radius: 0
                color: "transparent"
                border.width: readings.visualFocus ? 2 : 0
                border.color: readings.activeFocus ? applicationWindow.accentColor : applicationWindow.ui.separator
            }
            contentItem: Row {
                Repeater {
                    model: [qsTr("dBA Slow"), qsTr("dBC Fast"), header.splLabel]
                    delegate: Item {
                        width: index === 2 ? 198 : 120
                        height: readings.height
                        Rectangle {
                            visible: index > 0
                            width: 1; height: 26
                            anchors.verticalCenter: parent.verticalCenter
                            color: applicationWindow.ui.separator
                        }
                        Rectangle {
                            anchors.fill: parent
                            anchors.margins: 3
                            radius: applicationWindow.ui.controlRadius
                            visible: index === 2
                            color: splMouse.containsMouse || splPopup.opened ? applicationWindow.ui.hover : "transparent"
                            border.width: splButton.visualFocus || splPopup.opened ? 1 : 0
                            border.color: applicationWindow.ui.focus
                        }
                        Button {
                            id: splButton
                            visible: index === 2
                            anchors.fill: parent
                            background: Item {}
                            contentItem: Item {}
                            Accessible.name: qsTr("SPL settings")
                            onClicked: splPopup.open()
                            MouseArea {
                                id: splMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: { splButton.forceActiveFocus(); splPopup.open(); }
                            }
                        }
                        Column {
                            anchors.centerIn: parent
                            spacing: 1
                            Label {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: modelData
                                font.pixelSize: applicationWindow.ui.secondaryFontSize
                                color: applicationWindow.ui.secondaryText
                            }
                            Label {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: index === 0 ? header.reading(aSlow.value) : index === 1 ? header.reading(cFast.value) :
                                    header.reading(header.splMeter ? header.splMeter.value : NaN)
                                font.family: applicationWindow.ui.fontFamily
                                font.pixelSize: 17; font.weight: Font.DemiBold
                                color: applicationWindow.ui.text
                            }
                        }
                    }
                }
            }

        }
    }
    Popup {
        id: splPopup
        parent: header
        x: Math.max(8, header.width - width - 16)
        y: header.height + 6
        width: 320
        padding: 20
        modal: false
        focus: true
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
        background: Rectangle {
            color: applicationWindow.ui.panel
            radius: 10
            border.color: applicationWindow.ui.separator
        }
        contentItem: ColumnLayout {
            spacing: 16
            Label {
                text: qsTr("SPL settings")
                font.pixelSize: 16; font.weight: Font.DemiBold
                color: applicationWindow.ui.text
            }
            ColumnLayout {
                spacing: 6
                Label { text: qsTr("Reading"); color: applicationWindow.ui.secondaryText; font.pixelSize: 12 }
                RowLayout {
                    spacing: 8
                    StudioButton {
                        Layout.fillWidth: true
                        text: qsTr("Live")
                        checked: !header.averageSPL
                        onClicked: header.averageSPL = false
                    }
                    StudioButton {
                        Layout.fillWidth: true
                        text: qsTr("Average · Leq")
                        checked: header.averageSPL
                        onClicked: header.averageSPL = true
                    }
                }
            }
            GridLayout {
                columns: 2
                columnSpacing: 16; rowSpacing: 12
                Label { text: qsTr("Weighting"); color: applicationWindow.ui.secondaryText }
                ComboBox {
                    Layout.fillWidth: true
                    model: ["A", "C", "Z"]
                    currentIndex: model.indexOf(header.splCurve)
                    Accessible.name: qsTr("SPL weighting")
                    onActivated: header.splCurve = currentText
                }
                Label {
                    text: header.averageSPL ? qsTr("Average over") : qsTr("Response")
                    color: applicationWindow.ui.secondaryText
                }
                ComboBox {
                    Layout.fillWidth: true
                    model: header.averageSPL ? ["  1 min", "  5 min", " 10 min", " 15 min", " 30 min", " 60 min", "120 min"] : ["Fast", "Slow"]
                    currentIndex: model.indexOf(header.averageSPL ? header.splWindow : header.splResponse)
                    Accessible.name: header.averageSPL ? qsTr("SPL averaging duration") : qsTr("SPL response")
                    onActivated: {
                        if (header.averageSPL) header.splWindow = currentText;
                        else header.splResponse = currentText;
                    }
                }
            }
            CheckBox {
                text: qsTr("Hold highest reading")
                checked: header.splPeakHold
                onToggled: header.splPeakHold = checked
            }
            StudioButton {
                Layout.fillWidth: true
                text: header.averageSPL ? qsTr("Restart average") : qsTr("Reset highest reading")
                enabled: !!header.source && (header.averageSPL || header.splPeakHold)
                onClicked: {
                    if (header.averageSPL) header.restartAverage();
                    else zSlow.reset();
                }
            }
        }
    }
    Rectangle {
        anchors.bottom: parent.bottom
        width: parent.width; height: 1
        color: applicationWindow.ui.separator
    }
}
