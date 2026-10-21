import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

ColumnLayout {
    property alias text: title.text
    Layout.fillWidth: true
    Layout.topMargin: 8
    spacing: 8
    Rectangle { Layout.fillWidth: true; implicitHeight: 1; color: applicationWindow.ui.separator }
    Label { id: title; font.pixelSize: applicationWindow.ui.sectionFontSize; font.weight: Font.DemiBold }
}
