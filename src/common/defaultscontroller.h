#ifndef DEFAULTSCONTROLLER_H
#define DEFAULTSCONTROLLER_H

#include <QObject>
#include <QVariantMap>

class Settings;
class SourceList;
class Measurement;

class DefaultsController : public QObject
{
    Q_OBJECT
    Q_PROPERTY(bool dirty READ dirty NOTIFY dirtyChanged)
    Q_PROPERTY(bool hasSavedDefaults READ hasSavedDefaults NOTIFY hasSavedDefaultsChanged)
    Q_PROPERTY(QString error READ error NOTIFY errorChanged)

public:
    explicit DefaultsController(Settings *settings, SourceList *sources, QObject *parent = nullptr);
    bool dirty() const noexcept { return m_dirty; }
    bool hasSavedDefaults() const noexcept { return m_hasSavedDefaults; }
    QString error() const noexcept { return m_error; }

    Q_INVOKABLE void loadDraft(QObject *measurement, QObject *magnitudePlot, QObject *rtaPlot);
    Q_INVOKABLE QVariant value(const QString &key, const QVariant &fallback = QVariant()) const;
    Q_INVOKABLE void setValue(const QString &key, const QVariant &value);
    Q_INVOKABLE void useCurrentValues(const QString &tab, QObject *measurement,
                                      QObject *magnitudePlot, QObject *rtaPlot);
    Q_INVOKABLE void resetTab(const QString &tab);
    Q_INVOKABLE bool save();
    Q_INVOKABLE void discard();
    Q_INVOKABLE void applyPlotDefaults(QObject *plot, const QString &kind) const;

signals:
    void dirtyChanged();
    void hasSavedDefaultsChanged();
    void errorChanged();
    void draftChanged();

private:
    QVariantMap factoryDefaults() const;
    void loadSaved();
    void captureMeasurement(QObject *object);
    void captureMagnitude(QObject *object);
    void captureRta(QObject *object);
    bool validate(QString &message) const;
    void applyMeasurement(Measurement *measurement) const;
    void setDirty(bool dirty);
    void setError(const QString &error);

    Settings *m_settings;
    SourceList *m_sources;
    QVariantMap m_draft;
    QVariantMap m_saved;
    bool m_dirty = false;
    bool m_hasSavedDefaults = false;
    QString m_error;
};

#endif
