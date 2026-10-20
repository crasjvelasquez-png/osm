/**
 *  OSM
 *  Copyright (C) 2018  Pavel Smokotnin

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
#ifndef STORED_H
#define STORED_H

#include <QJsonObject>
#include "abstract/source.h"
#include "meta/metastored.h"

class Stored: public Abstract::Source, public Meta::Stored
{
    Q_OBJECT
    Q_PROPERTY(QString notes READ notes WRITE setNotes NOTIFY notesChanged)
    Q_PROPERTY(bool polarity READ polarity WRITE setPolarity NOTIFY polarityChanged)
    Q_PROPERTY(bool inverse READ inverse WRITE setInverse NOTIFY inverseChanged)
    Q_PROPERTY(bool ignoreCoherence READ ignoreCoherence WRITE setIgnoreCoherence NOTIFY ignoreCoherenceChanged)
    Q_PROPERTY(float gain READ gain WRITE setGain NOTIFY gainChanged)
    Q_PROPERTY(float delay READ delay WRITE setDelay NOTIFY delayChanged)
    Q_PROPERTY(QString captureType READ captureType WRITE setCaptureType NOTIFY captureTypeChanged)
    Q_PROPERTY(QString contributors READ contributors WRITE setContributors NOTIFY contributorsChanged)
    Q_PROPERTY(QString capturedAt READ capturedAt WRITE setCapturedAt NOTIFY capturedAtChanged)

public:
    explicit Stored(QObject *parent = nullptr);
    Shared::Source clone() const override;
    void build (const Abstract::Source &source);
    QString captureType() const { return m_captureType; }
    void setCaptureType(const QString &value) { if (m_captureType != value) { m_captureType = value; emit captureTypeChanged(); } }
    QString contributors() const { return m_contributors; }
    void setContributors(const QString &value) { if (m_contributors != value) { m_contributors = value; emit contributorsChanged(); } }
    QString capturedAt() const { return m_capturedAt; }
    void setCapturedAt(const QString &value) { if (m_capturedAt != value) { m_capturedAt = value; emit capturedAtChanged(); } }

    Q_INVOKABLE void autoName(const QString &prefix) noexcept;

    Q_INVOKABLE bool save(const QUrl &fileName) const noexcept;
    Q_INVOKABLE bool saveCal(const QUrl &fileName) const noexcept;
    Q_INVOKABLE bool saveFRD(const QUrl &fileName) const noexcept;
    Q_INVOKABLE bool saveTXT(const QUrl &fileName) const noexcept;
    Q_INVOKABLE bool saveCSV(const QUrl &fileName) const noexcept;
    Q_INVOKABLE bool saveWAV(const QUrl &fileName) const noexcept;
    Q_INVOKABLE QJsonObject toJSON() const noexcept override;
    void fromJSON(QJsonObject data, const SourceList * = nullptr) noexcept override;

    float module(unsigned int i) const noexcept override;
    float magnitudeRaw(unsigned int i) const noexcept override;
    float magnitude(unsigned int i) const noexcept override;
    Complex phase(unsigned int i) const noexcept override;
    float coherence(unsigned int i) const noexcept override;

    float impulseTime(unsigned int i) const noexcept override;
    float impulseValue(unsigned int i) const noexcept override;

signals:
    void notesChanged() override;
    void polarityChanged() override;
    void inverseChanged() override;
    void ignoreCoherenceChanged() override;
    void gainChanged() override;
    void delayChanged() override;
    void captureTypeChanged();
    void contributorsChanged();
    void capturedAtChanged();

private:
    QString m_captureType { QStringLiteral("Magnitude") };
    QString m_contributors;
    QString m_capturedAt;
};

#endif // STORED_H
