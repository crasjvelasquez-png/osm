import QtQuick 2.15
import Qt.labs.settings 1.1

Item {
    id: registry
    visible: false

    readonly property var entries: [
        { id: "project.new", category: qsTr("Project"), title: qsTr("New project"), ctrl: "Ctrl+N", meta: "Meta+N" },
        { id: "project.save", category: qsTr("Project"), title: qsTr("Save project"), ctrl: "Ctrl+S", meta: "Meta+S" },
        { id: "project.open", category: qsTr("Project"), title: qsTr("Open project"), ctrl: "Ctrl+O", meta: "Meta+O" },
        { id: "project.import", category: qsTr("Project"), title: qsTr("Import data"), ctrl: "Ctrl+I", meta: "Ctrl+I" },
        { id: "project.quit", category: qsTr("Project"), title: qsTr("Quit"), ctrl: "Ctrl+Q", meta: "Meta+Q" },
        { id: "source.addMeasurement", category: qsTr("Sources"), title: qsTr("Add measurement"), ctrl: "Ctrl+Shift+A", meta: "Meta+Shift+A" },
        { id: "source.addMath", category: qsTr("Sources"), title: qsTr("Add math source"), ctrl: "Ctrl+Shift+M", meta: "Meta+Shift+M" },
        { id: "source.addStandard", category: qsTr("Sources"), title: qsTr("Add standard line"), ctrl: "Ctrl+Shift+L", meta: "Meta+Shift+L" },
        { id: "source.addFilter", category: qsTr("Sources"), title: qsTr("Add filter"), ctrl: "Ctrl+Shift+F", meta: "Meta+Shift+F" },
        { id: "source.addEqualizer", category: qsTr("Sources"), title: qsTr("Add equalizer"), ctrl: "Ctrl+Shift+E", meta: "Meta+Shift+E" },
        { id: "source.addWindowing", category: qsTr("Sources"), title: qsTr("Add windowing"), ctrl: "Ctrl+Shift+W", meta: "Meta+Shift+W" },
        { id: "source.addGroup", category: qsTr("Sources"), title: qsTr("Add group"), ctrl: "Ctrl+Shift+G", meta: "Meta+Shift+G" },
        { id: "edit.undoRemoval", category: qsTr("Measurements"), title: qsTr("Undo removing an item"), ctrl: "Ctrl+Z", meta: "Meta+Z" },
        { id: "measurement.store", category: qsTr("Measurements"), title: qsTr("Store current measurement"), ctrl: "Ctrl+B", meta: "Meta+B" },
        { id: "measurement.storeAll", category: qsTr("Measurements"), title: qsTr("Store all active measurements"), ctrl: "Ctrl+Shift+X", meta: "Meta+Shift+X" },
        { id: "measurement.resetAverages", category: qsTr("Measurements"), title: qsTr("Reset measurement averages"), ctrl: "Ctrl+R", meta: "Meta+R" },
        { id: "measurement.applyDelay", category: qsTr("Measurements"), title: qsTr("Apply estimated delay"), ctrl: "Ctrl+9", meta: "Meta+9" },
        { id: "generator.toggle", category: qsTr("Generator"), title: qsTr("Toggle generator"), ctrl: "Ctrl+G", meta: "Meta+G" },
        { id: "charts.one", category: qsTr("Charts"), title: qsTr("Show one chart"), ctrl: "Ctrl+1", meta: "Meta+1" },
        { id: "charts.two", category: qsTr("Charts"), title: qsTr("Show two charts"), ctrl: "Ctrl+2", meta: "Meta+2" },
        { id: "charts.three", category: qsTr("Charts"), title: qsTr("Show three charts"), ctrl: "Ctrl+3", meta: "Meta+3" },
        { id: "charts.equalHeights", category: qsTr("Charts"), title: qsTr("Set equal chart heights"), ctrl: "Ctrl+4", meta: "Meta+4" },
        { id: "charts.showHidden", category: qsTr("Charts"), title: qsTr("Show hidden sources"), ctrl: "Ctrl+5", meta: "Meta+5" },
        { id: "charts.capture", category: qsTr("Charts"), title: qsTr("Capture selected traces"), ctrl: "Ctrl+Shift+C", meta: "Meta+Shift+C" },
        { id: "view.target", category: qsTr("View"), title: qsTr("Show target trace"), ctrl: "Ctrl+T", meta: "Ctrl+T" },
        { id: "view.darkMode", category: qsTr("View"), title: qsTr("Toggle dark mode"), ctrl: "Ctrl+D", meta: "Ctrl+D" },
        { id: "view.calculator", category: qsTr("View"), title: qsTr("Open calculator"), ctrl: "Ctrl+K", meta: "Ctrl+K" },
        { id: "view.dante", category: qsTr("View"), title: qsTr("Open Dante monitoring"), ctrl: "Ctrl+Shift+D", meta: "Ctrl+Shift+D" },
        { id: "help.shortcuts", category: qsTr("Help"), title: qsTr("Show keyboard shortcuts"), ctrl: "?", meta: "?" },
        { id: "help.shortcutsSlash", category: qsTr("Help"), title: qsTr("Show keyboard shortcuts"), ctrl: "Ctrl+/", meta: "Meta+/" },
        { id: "help.shortcutsF1", category: qsTr("Help"), title: qsTr("Show keyboard shortcuts"), ctrl: "F1", meta: "F1" },
        { id: "help.about", category: qsTr("Help"), title: qsTr("About Open Sound Meter"), ctrl: "F2", meta: "F2" },
        { id: "help.update", category: qsTr("Help"), title: qsTr("Check for updates"), ctrl: "F3", meta: "F3" },
        { id: "settings.close", category: qsTr("Settings"), title: qsTr("Close settings"), ctrl: "Esc", meta: "Esc" },
        { id: "dante.close", category: qsTr("Dante monitoring"), title: qsTr("Close Dante monitoring"), ctrl: "Esc", meta: "Esc" }
    ]

    property var revision: 0
    Settings {
        id: saved
        category: "KeyboardShortcuts"
        property var assignments: ({})
    }

    function entry(id) {
        for (var i = 0; i < entries.length; ++i)
            if (entries[i].id === id) return entries[i];
        return null;
    }
    function sequence(id) {
        revision;
        var custom = saved.assignments[id];
        if (Object.prototype.hasOwnProperty.call(saved.assignments, id)) return custom;
        var item = entry(id);
        if (!item) return "";
        return Qt.platform.os === "osx" ? item.meta : item.ctrl;
    }
    function sequences(id) { return [sequence(id)]; }
    function display(id) {
        var value = sequence(id);
        if (!value) return qsTr("Unassigned");
        return Qt.platform.os === "osx" ? value.replace(/Meta/g, "⌘") : value;
    }
    function assign(id, value) {
        var map = Object.assign({}, saved.assignments);
        if (value === sequenceDefault(id)) delete map[id];
        else map[id] = value;
        saved.assignments = map;
        revision++;
    }
    function sequenceDefault(id) {
        var item = entry(id);
        return item ? (Qt.platform.os === "osx" ? item.meta : item.ctrl) : "";
    }
    function reset(id) {
        var map = Object.assign({}, saved.assignments);
        delete map[id];
        saved.assignments = map;
        revision++;
    }
    function resetAll() {
        saved.assignments = ({});
        revision++;
    }
    function duplicate(id, value) {
        if (!value) return "";
        for (var i = 0; i < entries.length; ++i) {
            var other = entries[i];
            if (other.id !== id && other.id !== "settings.close" && other.id !== "dante.close" && sequence(other.id).toLowerCase() === value.toLowerCase())
                return other.title;
        }
        return "";
    }
}
