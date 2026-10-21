import QtQuick 2.15

QtObject {
    property bool darkMode: true

    readonly property string fontFamily: Qt.application.font.family
    readonly property int controlFontSize: 13
    readonly property int secondaryFontSize: 12
    readonly property int sectionFontSize: 15
    readonly property int controlHeight: 36
    readonly property int controlRadius: 6
    readonly property int spacing: 8
    readonly property color primary: "#505D9B"
    readonly property color primaryHover: "#46528B"
    readonly property color primaryPressed: "#3C4779"
    readonly property color focus: darkMode ? "#AEBBF5" : "#505D9B"
    readonly property color selection: darkMode ? "#353B50" : "#E0E4F0"
    readonly property color shell: darkMode ? "#202226" : "#ECEEF1"
    readonly property color panel: darkMode ? "#292C31" : "#F7F8FA"
    readonly property color control: darkMode ? "#31353B" : "#FFFFFF"
    readonly property color hover: darkMode ? "#3B4048" : "#E8ECF2"
    readonly property color separator: darkMode ? "#41464F" : "#D0D5DD"
    readonly property color text: darkMode ? "#F0F2F5" : "#20252D"
    readonly property color secondaryText: darkMode ? "#B7BEC8" : "#5C6573"
}
