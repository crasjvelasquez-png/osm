/**
 *  OSM
 *  Copyright (C) 2020  Pavel Smokotnin
 *
 *  This program is free software; you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation, either version 3 of the License, or
 *  (at your option) any later version.
 */
import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import "elements"

Popup {
    id: popup
    modal: true
    Overlay.modal: Rectangle { color: applicationAppearance.darkMode ? "#99000000" : "#55000000" }
    background: Rectangle { radius: applicationWindow.ui.controlRadius; color: applicationWindow.ui.panel; border.color: applicationWindow.ui.separator }
    focus: true
    padding: 20
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
    width: Math.min(620, applicationWindow.width - 40)
    height: Math.min(applicationWindow.height - 40, 680)

    ColumnLayout {
        anchors.fill: parent
        spacing: 12

        RowLayout {
            Layout.fillWidth: true
            Label {
                Layout.fillWidth: true
                text: qsTr("Keyboard shortcuts")
                font.pixelSize: applicationWindow.ui.sectionFontSize
                font.bold: true
                color: applicationWindow.ui.text
            }
            StudioButton {
                text: qsTr("Customize…")
                flat: true
                onClicked: {
                    popup.close();
                    defaultsWindow.openFor(null, charts.magnitudePlot(), charts.spectrumPlot(), 3);
                }
            }
        }

        ScrollView {
            clip: true
            contentWidth: availableWidth
            Layout.fillWidth: true
            Layout.fillHeight: true

            GridLayout {
                columns: 2
                columnSpacing: 16
                rowSpacing: 0
                width: availableWidth
            Label { text: qsTr("Shortcut"); font.bold: true; color: applicationWindow.ui.secondaryText; Layout.bottomMargin: 6 }
            Label { text: qsTr("Action"); font.bold: true; color: applicationWindow.ui.secondaryText; Layout.bottomMargin: 6 }

            Repeater {
                model: applicationWindow.shortcutRegistry.entries
                delegate: Item {
                    Layout.columnSpan: 2
                    Layout.fillWidth: true
                    implicitHeight: categoryTitle.visible ? 58 : 34
                    Label {
                        id: categoryTitle
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.top: parent.top
                        height: visible ? 25 : 0
                        visible: index === 0 || modelData.category !== applicationWindow.shortcutRegistry.entries[index - 1].category
                        text: visible ? modelData.category : ""
                        font.pixelSize: applicationWindow.ui.secondaryFontSize
                        font.bold: true
                        color: applicationWindow.ui.text
                        verticalAlignment: Text.AlignBottom
                        bottomPadding: 3
                    }
                    Rectangle {
                        anchors.fill: actionRow
                        color: index % 2 ? "transparent" : applicationWindow.ui.control
                        opacity: 0.42
                        radius: 3
                    }
                    RowLayout {
                        id: actionRow
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.bottom: parent.bottom
                        height: 32
                        spacing: 16
                        Label {
                            Layout.preferredWidth: 150
                            text: applicationWindow.shortcutRegistry.display(modelData.id)
                            color: applicationWindow.ui.secondaryText
                            font.bold: true
                            elide: Text.ElideRight
                        }
                        Label {
                            Layout.fillWidth: true
                            text: modelData.title
                            color: applicationWindow.ui.text
                            elide: Text.ElideRight
                        }
                    }
                }
            }
            }
        }
        Label {
            Layout.fillWidth: true
            text: qsTr("Right-click a plot point to open the wavelength calculator. Shortcuts are also available in Settings → Shortcuts.")
            wrapMode: Text.WordWrap
            color: applicationWindow.ui.secondaryText
            font.pixelSize: applicationWindow.ui.secondaryFontSize
        }
    }
}
