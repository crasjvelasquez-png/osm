/**
 *  OSM
 *  Copyright (C) 2021  Pavel Smokotnin

 *  This program is free software: you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation, either version 3 of the License, or
 *  (at your option) any later version.

 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.

 *  You should have received a copy of the GNU General Public License
 *  along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */
import QtQuick 2.15
import QtQuick.Controls 1.4
import QtQml.Models 2.12
import QtQuick.Controls.Styles 1.4
import QtQuick.Controls.Material 2.1
import OpenSoundMeterModule 1.0

MenuBar {
    id: menuBar;
    style: MenuBarStyle{
                background: Rectangle{ color:Material.backgroundColor}
                itemDelegate: Rectangle {
                    implicitWidth: menuBarLabel.contentWidth * 1.4
                    implicitHeight: menuBarLabel.contentHeight * 1.5
                    color: styleData.selected || styleData.open ? accentColor : backgroundColor
                    Label {
                        id:menuBarLabel
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.bottom: parent.bottom
                        anchors.bottomMargin: menuBarLabel.contentHeight/5
                        color: styleData.selected  || styleData.open ? backgroundColor : foregroundColor
                        text: formatMnemonic(styleData.text,true)
                    }
                }
                menuStyle: MenuStyle {
                    frame: Rectangle {
                        color: backgroundColor
                        border.width: 0
                    }

                    //FIXME: Colors doesn't set correctly from Material
                    itemDelegate {
                        background: Rectangle {
                            color:  styleData.selected || styleData.open ? accentColor : backgroundColor
                            border.width: 0
                        }
                        label: Label {
                            color: styleData.selected ? backgroundColor : foregroundColor
                            text: formatMnemonic(styleData.text,true)
                        }

                        submenuIndicator: Text {
                            text: "\u25ba"
                            color: styleData.selected  || styleData.open ? accentColor : backgroundColor
                        }

                        shortcut: Label {
                            color: styleData.selected ? backgroundColor : foregroundColor
                            text: styleData.shortcut
                        }

                        checkmarkIndicator: CheckBox {
                            checked: styleData.checked
                        }
                    }
                }
            }

    Menu {
        title: qsTr("&File")
        MenuItem {
            text: qsTr("&New")
            shortcut: applicationWindow.shortcutRegistry.sequence("project.new")
            onTriggered: {
                dialog.title = qsTr("Create new workspace?")
                dialog.accepted.connect(closeAccepted);
                dialog.rejected.connect(closeRejected);
                dialog.open();
            }
            function closeAccepted() {
                applicationWindow.properiesbar.clear();
                sourceList.reset();
                closeRejected();
            }
            function closeRejected() {
                applicationWindow.dialog.accepted.disconnect(closeAccepted);
                applicationWindow.dialog.rejected.disconnect(closeRejected);
            }
        }
        MenuItem {
            text: qsTr("&Save")
            shortcut: applicationWindow.shortcutRegistry.sequence("project.save")
            onTriggered: saveDialog.open();
        }
        MenuItem {
            text: qsTr("&Open")
            shortcut: applicationWindow.shortcutRegistry.sequence("project.open")
            onTriggered: openDialog.open()
        }

        Menu {
            title: qsTr("Recent projects")
            id: recentFilesMenu

            RecentFilesModel {
                id: recentFilesModel
                settings: applicationSettings.getGroup("recentFiles");
                onProjectFolderChanged: {
                    let folder = recentFilesModel.projectFolder();
                    if (folder) {
                        openDialog.folder = folder;
                        saveDialog.folder = folder;
                    }
                }
            }

            Connections {
                target: sourceList
                function onLoaded(url) {
                    recentFilesModel.addUrl(url);
                }
            }

            Connections {
                target: saveDialog
                function onAccepted() {
                    recentFilesModel.storeProjectFolder(saveDialog.fileUrl);
                }
            }

            Connections {
                target: openDialog
                function onAccepted() {
                    recentFilesModel.storeProjectFolder(openDialog.fileUrl);
                }
            }

            Instantiator {
                model: recentFilesModel
                MenuItem {
                    text: model.fileName
                    onTriggered: sourceList.load(model.url)
                }
                onObjectAdded: recentFilesMenu.insertItem(index, object);
                onObjectRemoved: recentFilesMenu.removeItem(object)
            }

            MenuSeparator {
                visible: recentFilesModel.count > 0
            }

            MenuItem {
                text: "Clear menu"
                enabled: recentFilesModel.count > 0
                onTriggered: recentFilesModel.clear()
            }
        }
        MenuItem {
            text: qsTr("&Import")
            shortcut: applicationWindow.shortcutRegistry.sequence("project.import")
            onTriggered: importDialog.open()
        }
        MenuItem {
            text: qsTr("&Add measurement")
            shortcut: applicationWindow.shortcutRegistry.sequence("source.addMeasurement")
            onTriggered: sourceList.addMeasurement();
        }
        MenuItem {
            text: qsTr("&Add math source")
            shortcut: applicationWindow.shortcutRegistry.sequence("source.addMath")
            onTriggered: sourceList.addUnion();
        }
        MenuItem {
            text: qsTr("&Add standard line")
            shortcut: applicationWindow.shortcutRegistry.sequence("source.addStandard")
            onTriggered: sourceList.addStandardLine();
        }
        MenuItem {
            text: qsTr("&Add filter")
            shortcut: applicationWindow.shortcutRegistry.sequence("source.addFilter")
            onTriggered: sourceList.addFilter();
        }
        MenuItem {
            text: qsTr("&Add equalizer")
            shortcut: applicationWindow.shortcutRegistry.sequence("source.addEqualizer")
            onTriggered: sourceList.addEqualizer();
        }
        MenuItem {
            text: qsTr("&Add windowing")
            shortcut: applicationWindow.shortcutRegistry.sequence("source.addWindowing")
            onTriggered: sourceList.addWindowing();
        }
        MenuItem {
            text: qsTr("&Add Group")
            shortcut: applicationWindow.shortcutRegistry.sequence("source.addGroup")
            onTriggered: sourceList.addGroup();
        }
        MenuItem {
            text: qsTr("&Show target")
            shortcut: applicationWindow.shortcutRegistry.sequence("view.target")
            checkable: true
            checked: targetTraceModel.show
            onCheckedChanged: targetTraceModel.show = checked
        }
        MenuItem {
            text: qsTr("Quit")
            shortcut: applicationWindow.shortcutRegistry.sequence("project.quit")
            onTriggered: applicationWindow.close();
        }
    }
    Menu {
        title: qsTr("&View")
        MenuItem {
            id: darkModeSelect
            text: qsTr("&Dark Mode")
            shortcut: applicationWindow.shortcutRegistry.sequence("view.darkMode")
            checkable: true
            checked: applicationAppearance.darkMode
            onCheckedChanged: {
                applicationAppearance.darkMode = darkModeSelect.checked;
            }
        }
        MenuItem {
            id: calculator
            text: qsTr("&Calculator")
            shortcut: applicationWindow.shortcutRegistry.sequence("view.calculator")
            checkable: false
            onTriggered: {
                applicationWindow.properiesbar.open(null, "qrc:/Calculator.qml");
            }
        }
        MenuItem {
            id: danteMonitoringItem
            text: qsTr("&Dante monitoring")
            shortcut: applicationWindow.shortcutRegistry.sequence("view.dante")
            checkable: false
            onTriggered: {
                danteWindow.open();
            }
        }
        MenuItem {
            id: experimentFunctions
            text: qsTr("&Experiment functions")
            checkable: true
            checked: applicationAppearance.experimentFunctions
            onCheckedChanged: {
                applicationAppearance.experimentFunctions = experimentFunctions.checked;
            }
        }
    }

    Menu {
        title: qsTr("&Help")
        MenuItem {
            text: qsTr("&Shortcuts")
            shortcut: applicationWindow.shortcutRegistry.sequence("help.shortcutsF1")
            checkable: false
            onTriggered: shortcutsPopup.open();
        }
        MenuItem {
            text: qsTr("Customize shortcuts…")
            onTriggered: defaultsWindow.openFor(null, charts.magnitudePlot(), charts.spectrumPlot(), 3);
        }
        MenuItem {
            text: qsTr("About")
            onTriggered: aboutpopup.open();
            shortcut: applicationWindow.shortcutRegistry.sequence("help.about")
        }
        MenuItem {
            text: qsTr("Check for update")
            shortcut: applicationWindow.shortcutRegistry.sequence("help.update")
            onTriggered: update.show();
        }
    }
}
