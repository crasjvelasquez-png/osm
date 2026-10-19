#include "defaultscontroller.h"

#include <QColor>
#include <QFileInfo>
#include <QUrl>
#include <QtMath>

#include "settings.h"
#include "sourcelist.h"
#include "source/measurement.h"

namespace {
const QStringList keys {
    "measurement/deviceId", "measurement/dataChannel", "measurement/referenceChannel",
    "measurement/averageType", "measurement/fifoCount", "measurement/lpfFrequency",
    "measurement/polarity", "measurement/mode", "measurement/window",
    "measurement/inputFilter", "measurement/calibrationFile", "measurement/calibrationEnabled",
    "measurement/name", "measurement/color", "measurement/referenceOffset",
    "measurement/gain", "measurement/delayMs",
    "magnitude/minFrequency", "magnitude/maxFrequency", "magnitude/minVertical",
    "magnitude/maxVertical", "magnitude/mode", "magnitude/pointsPerOctave",
    "magnitude/invert", "magnitude/coherence", "magnitude/coherenceThreshold",
    "magnitude/sensorResistance", "magnitude/sources",
    "rta/displayStyle", "rta/resolution", "rta/holdPeaks", "rta/smooth", "rta/heatmap"
};

bool finiteNumber(const QVariant &value)
{
    bool ok = false;
    const double number = value.toDouble(&ok);
    return ok && qIsFinite(number);
}
}

DefaultsController::DefaultsController(Settings *settings, SourceList *sources, QObject *parent) :
    QObject(parent), m_settings(settings), m_sources(sources)
{
    loadSaved();
    if (m_hasSavedDefaults && m_sources) {
        for (const auto &source : m_sources->items())
            if (auto measurement = std::dynamic_pointer_cast<Measurement>(source))
                applyMeasurement(measurement.get());
    }
    if (m_sources) {
        connect(m_sources, &SourceList::postItemAppended, this, [this](const Shared::Source &source) {
            if (!m_hasSavedDefaults || m_sources->loadingProject()) return;
            if (auto measurement = std::dynamic_pointer_cast<Measurement>(source))
                applyMeasurement(measurement.get());
        });
    }
}

QVariantMap DefaultsController::factoryDefaults() const
{
    return {
        {"measurement/deviceId", QString()}, {"measurement/dataChannel", 0},
        {"measurement/referenceChannel", 1}, {"measurement/averageType", 0},
        {"measurement/fifoCount", 8}, {"measurement/lpfFrequency", 1},
        {"measurement/polarity", false}, {"measurement/mode", 0},
        {"measurement/window", 0}, {"measurement/inputFilter", 0},
        {"measurement/calibrationFile", QString()}, {"measurement/calibrationEnabled", false},
        {"measurement/name", QStringLiteral("Measurement")},
        {"measurement/color", QColor("#673AB7")}, {"measurement/referenceOffset", 0.0},
        {"measurement/gain", 0.0}, {"measurement/delayMs", 0.0},
        {"magnitude/minFrequency", 20.0}, {"magnitude/maxFrequency", 20000.0},
        {"magnitude/minVertical", -18.0}, {"magnitude/maxVertical", 18.0},
        {"magnitude/mode", 0}, {"magnitude/pointsPerOctave", 12},
        {"magnitude/invert", false}, {"magnitude/coherence", true},
        {"magnitude/coherenceThreshold", 0.7}, {"magnitude/sensorResistance", 2.6},
        {"magnitude/sources", QStringList {QStringLiteral("all")}},
        {"rta/displayStyle", 0}, {"rta/resolution", 0}, {"rta/holdPeaks", true},
        {"rta/smooth", true}, {"rta/heatmap", true}
    };
}

void DefaultsController::loadSaved()
{
    m_hasSavedDefaults = m_settings && m_settings->value("saved", false).toBool();
    m_saved = factoryDefaults();
    if (m_hasSavedDefaults) {
        for (const auto &key : keys) {
            const QVariant stored = m_settings->value(key);
            if (stored.isValid()) m_saved.insert(key, stored);
        }
    }
    m_draft = m_saved;
}

void DefaultsController::loadDraft(QObject *measurement, QObject *magnitudePlot, QObject *rtaPlot)
{
    setError({});
    if (m_hasSavedDefaults) {
        m_draft = m_saved;
    } else {
        m_draft = factoryDefaults();
        captureMeasurement(measurement);
        captureMagnitude(magnitudePlot);
        captureRta(rtaPlot);
    }
    setDirty(false);
    emit draftChanged();
}

QVariant DefaultsController::value(const QString &key, const QVariant &fallback) const
{
    return m_draft.value(key, fallback);
}

void DefaultsController::setValue(const QString &key, const QVariant &value)
{
    if (m_draft.value(key) == value) return;
    m_draft.insert(key, value);
    setError({});
    setDirty(true);
    emit draftChanged();
}

void DefaultsController::captureMeasurement(QObject *o)
{
    if (!o) return;
    m_draft["measurement/deviceId"] = o->property("deviceId");
    m_draft["measurement/dataChannel"] = o->property("dataChanel");
    m_draft["measurement/referenceChannel"] = o->property("referenceChanel");
    m_draft["measurement/averageType"] = o->property("averageType");
    m_draft["measurement/fifoCount"] = o->property("average");
    m_draft["measurement/lpfFrequency"] = o->property("filtersFrequency");
    m_draft["measurement/polarity"] = o->property("polarity");
    m_draft["measurement/mode"] = o->property("mode");
    m_draft["measurement/window"] = o->property("window");
    m_draft["measurement/inputFilter"] = o->property("inputFilter");
    m_draft["measurement/calibrationFile"] = o->property("calibrationFile");
    m_draft["measurement/calibrationEnabled"] = o->property("calibration");
    m_draft["measurement/name"] = o->property("name");
    m_draft["measurement/color"] = o->property("color");
    m_draft["measurement/referenceOffset"] = o->property("offset");
    m_draft["measurement/gain"] = o->property("gain");
    const double rate = o->property("sampleRate").toDouble();
    m_draft["measurement/delayMs"] = rate > 0.0 ? o->property("delay").toDouble() * 1000.0 / rate : 0.0;
}

void DefaultsController::captureMagnitude(QObject *o)
{
    if (!o) return;
    m_draft["magnitude/minFrequency"] = o->property("xmin");
    m_draft["magnitude/maxFrequency"] = o->property("xmax");
    m_draft["magnitude/minVertical"] = o->property("ymin");
    m_draft["magnitude/maxVertical"] = o->property("ymax");
    m_draft["magnitude/mode"] = o->property("mode");
    m_draft["magnitude/pointsPerOctave"] = o->property("pointsPerOctave");
    m_draft["magnitude/invert"] = o->property("invert");
    m_draft["magnitude/coherence"] = o->property("coherence");
    m_draft["magnitude/coherenceThreshold"] = o->property("coherenceThreshold");
    m_draft["magnitude/sensorResistance"] = o->property("sensor");
    if (o->property("selected").isValid()) m_draft["magnitude/sources"] = o->property("selected");
}

void DefaultsController::captureRta(QObject *o)
{
    if (!o) return;
    m_draft["rta/displayStyle"] = o->property("mode");
    m_draft["rta/resolution"] = o->property("pointsPerOctave");
    m_draft["rta/holdPeaks"] = o->property("showPeaks");
    m_draft["rta/smooth"] = o->property("smooth");
}

void DefaultsController::useCurrentValues(const QString &tab, QObject *measurement,
                                          QObject *magnitudePlot, QObject *rtaPlot)
{
    if (tab == "measurement") captureMeasurement(measurement);
    else if (tab == "magnitude") captureMagnitude(magnitudePlot);
    else if (tab == "rta") captureRta(rtaPlot);
    setDirty(true);
    setError({});
    emit draftChanged();
}

void DefaultsController::resetTab(const QString &tab)
{
    const QVariantMap defaults = factoryDefaults();
    const QString prefix = tab + "/";
    for (auto it = defaults.constBegin(); it != defaults.constEnd(); ++it)
        if (it.key().startsWith(prefix)) m_draft[it.key()] = it.value();
    setDirty(true);
    setError({});
    emit draftChanged();
}

bool DefaultsController::validate(QString &message) const
{
    const QStringList numericKeys {
        "measurement/fifoCount", "measurement/delayMs", "measurement/referenceOffset", "measurement/gain",
        "magnitude/minFrequency", "magnitude/maxFrequency", "magnitude/minVertical", "magnitude/maxVertical",
        "magnitude/coherenceThreshold", "magnitude/sensorResistance"
    };
    for (const auto &key : numericKeys) {
        if (!finiteNumber(m_draft.value(key))) {
            message = tr("Enter a finite number for %1.").arg(key.section('/', -1));
            return false;
        }
    }
    const double minFrequency = m_draft.value("magnitude/minFrequency").toDouble();
    const double maxFrequency = m_draft.value("magnitude/maxFrequency").toDouble();
    if (minFrequency < 12.0 || maxFrequency > 96000.0 || minFrequency >= maxFrequency) {
        message = tr("Frequency range must be ordered and between 12 Hz and 96,000 Hz.");
        return false;
    }
    if (m_draft.value("magnitude/minVertical").toDouble() >= m_draft.value("magnitude/maxVertical").toDouble()) {
        message = tr("Minimum vertical range must be lower than the maximum."); return false;
    }
    const int ppo = m_draft.value("magnitude/pointsPerOctave").toInt();
    if (ppo < 1 || ppo > 48) {
        message = tr("Magnitude resolution must be between 1 and 48 points per octave."); return false;
    }
    const int rtaPpo = m_draft.value("rta/resolution").toInt();
    if (rtaPpo < 0 || rtaPpo > 48 || (m_draft.value("rta/displayStyle").toInt() == 1 && rtaPpo == 0)) {
        message = tr("Bars require an octave resolution; FFT bins are available for Line only."); return false;
    }
    const double threshold = m_draft.value("magnitude/coherenceThreshold").toDouble();
    if (threshold < 0.0 || threshold > 1.0) {
        message = tr("Coherence threshold must be between 0 and 1."); return false;
    }
    const int fifo = m_draft.value("measurement/fifoCount").toInt();
    if (fifo < 1 || fifo > 100) {
        message = tr("FIFO count must be between 1 and 100."); return false;
    }
    if (m_draft.value("magnitude/mode").toInt() == 2 &&
            m_draft.value("magnitude/sensorResistance").toDouble() <= 0.0) {
        message = tr("Impedance sensor resistance must be greater than zero."); return false;
    }
    const QString correction = m_draft.value("measurement/calibrationFile").toString();
    if (m_draft.value("measurement/calibrationEnabled").toBool() &&
            (correction.isEmpty() || !QFileInfo::exists(correction))) {
        message = tr("Choose an existing microphone correction file or turn correction off."); return false;
    }
    return true;
}

bool DefaultsController::save()
{
    QString validationError;
    if (!validate(validationError)) { setError(validationError); return false; }
    if (!m_settings) { setError(tr("Defaults storage is unavailable.")); return false; }
    for (const auto &key : keys) m_settings->setValue(key, m_draft.value(key));
    m_settings->setValue("saved", true);
    m_settings->flush();
    m_saved = m_draft;
    if (!m_hasSavedDefaults) { m_hasSavedDefaults = true; emit hasSavedDefaultsChanged(); }
    setDirty(false);
    setError({});
    return true;
}

void DefaultsController::discard()
{
    m_draft = m_saved;
    setDirty(false);
    setError({});
    emit draftChanged();
}

void DefaultsController::applyMeasurement(Measurement *m) const
{
    if (!m || !m_hasSavedDefaults) return;
    m->setDeviceId(m_saved.value("measurement/deviceId").toString());
    m->setDataChanel(m_saved.value("measurement/dataChannel").toUInt());
    m->setReferenceChanel(m_saved.value("measurement/referenceChannel").toUInt());
    m->setAverageType(m_saved.value("measurement/averageType"));
    m->setAverage(m_saved.value("measurement/fifoCount").toUInt());
    m->setFiltersFrequency(m_saved.value("measurement/lpfFrequency"));
    m->setPolarity(m_saved.value("measurement/polarity").toBool());
    m->setMode(m_saved.value("measurement/mode"));
    m->setWindowFunctionType(m_saved.value("measurement/window"));
    m->setInputFilter(static_cast<Meta::Measurement::InputFilter>(m_saved.value("measurement/inputFilter").toInt()));
    m->setName(m_saved.value("measurement/name").toString());
    m->setColor(m_saved.value("measurement/color").value<QColor>());
    m->setOffset(m_saved.value("measurement/referenceOffset").toFloat());
    m->setGain(m_saved.value("measurement/gain").toFloat());
    m->setDelay(qRound(m_saved.value("measurement/delayMs").toDouble() * m->sampleRate() / 1000.0));
    if (!m->property("defaultsDelayConnected").toBool()) {
        m->setProperty("defaultsDelayConnected", true);
        connect(m, &Measurement::sampleRateChanged, m, [this, m](unsigned int sampleRate) {
            if (m_hasSavedDefaults)
                m->setDelay(qRound(m_saved.value("measurement/delayMs").toDouble() * sampleRate / 1000.0));
        });
    }
    const QString correction = m_saved.value("measurement/calibrationFile").toString();
    if (!correction.isEmpty()) m->loadCalibrationFile(QUrl::fromLocalFile(correction));
    m->setCalibration(m_saved.value("measurement/calibrationEnabled").toBool() && m->calibrationLoaded());
}

void DefaultsController::applyPlotDefaults(QObject *plot, const QString &kind) const
{
    if (!plot || !m_hasSavedDefaults) return;
    if (kind == "magnitude") {
        plot->setProperty("mode", m_saved.value("magnitude/mode"));
        plot->setProperty("xmin", m_saved.value("magnitude/minFrequency"));
        plot->setProperty("xmax", m_saved.value("magnitude/maxFrequency"));
        plot->setProperty("ymin", m_saved.value("magnitude/minVertical"));
        plot->setProperty("ymax", m_saved.value("magnitude/maxVertical"));
        plot->setProperty("pointsPerOctave", m_saved.value("magnitude/pointsPerOctave"));
        plot->setProperty("invert", m_saved.value("magnitude/invert"));
        plot->setProperty("coherence", m_saved.value("magnitude/coherence"));
        plot->setProperty("coherenceThreshold", m_saved.value("magnitude/coherenceThreshold"));
        plot->setProperty("sensor", m_saved.value("magnitude/sensorResistance"));
        const QVariant sources = m_saved.value("magnitude/sources");
        if (sources.toStringList() != QStringList {QStringLiteral("all")}) plot->setProperty("selected", sources);
    } else if (kind == "rta") {
        plot->setProperty("mode", m_saved.value("rta/displayStyle"));
        plot->setProperty("pointsPerOctave", m_saved.value("rta/resolution"));
        plot->setProperty("showPeaks", m_saved.value("rta/holdPeaks"));
        plot->setProperty("smooth", m_saved.value("rta/smooth"));
    }
}

void DefaultsController::setDirty(bool dirty)
{
    if (m_dirty == dirty) return;
    m_dirty = dirty;
    emit dirtyChanged();
}

void DefaultsController::setError(const QString &error)
{
    if (m_error == error) return;
    m_error = error;
    emit errorChanged();
}
