/**
 *  OSM
 *  Copyright (C) 2026  Pavel Smokotnin
 *
 *  This program is free software: you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation, either version 3 of the License, or
 *  (at your option) any later version.
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */
#ifndef DANTEMONITOR_H
#define DANTEMONITOR_H

#include <QObject>
#include <QString>
#include <QVariantList>
#include <QVariantMap>
#include <QDateTime>
#include <QTimer>
#include <QList>
#include "common/settings.h"

namespace dante {

enum class LinkState {
    Off,
    NotConfigured,
    Up,
    Down,
    Degraded,
    Unknown,
    Stale
};

struct AdapterInfo {
    QString id;       // e.g. "en0"
    QString name;     // e.g. "Wi-Fi (en0)"
    QString mac;      // e.g. "80:a9:97:44:c7:39"
    bool active = false;
};

struct Snapshot {
    quint64 generation = 0;
    qint64 monotonicTimestampMs = 0;
    QDateTime observationTime;

    bool enabled = false;
    bool fixtureMode = false;

    QString providerId;
    QString providerStatus;
    bool conmonRunning = false;
    bool controllerRunning = false;
    QString discoveryState;

    QString primaryAdapter;
    QString primaryAdapterName;
    LinkState primaryState = LinkState::Off;
    QString primaryReason;

    QString secondaryAdapter;
    QString secondaryAdapterName;
    LinkState secondaryState = LinkState::Off;
    QString secondaryReason;

    QString degradedReason;
    QString scope;

    bool operator==(const Snapshot &other) const {
        return enabled == other.enabled &&
               fixtureMode == other.fixtureMode &&
               providerId == other.providerId &&
               providerStatus == other.providerStatus &&
               conmonRunning == other.conmonRunning &&
               controllerRunning == other.controllerRunning &&
               discoveryState == other.discoveryState &&
               primaryAdapter == other.primaryAdapter &&
               primaryAdapterName == other.primaryAdapterName &&
               primaryState == other.primaryState &&
               primaryReason == other.primaryReason &&
               secondaryAdapter == other.secondaryAdapter &&
               secondaryAdapterName == other.secondaryAdapterName &&
               secondaryState == other.secondaryState &&
               secondaryReason == other.secondaryReason &&
               degradedReason == other.degradedReason &&
               scope == other.scope;
    }

    bool operator!=(const Snapshot &other) const {
        return !(*this == other);
    }
};

class Monitor : public QObject {
    Q_OBJECT

    Q_PROPERTY(bool enabled READ isEnabled WRITE setEnabled NOTIFY enabledChanged)
    Q_PROPERTY(QString primaryRoleState READ primaryRoleState NOTIFY statusChanged)
    Q_PROPERTY(QString secondaryRoleState READ secondaryRoleState NOTIFY statusChanged)
    Q_PROPERTY(QString primaryAdapter READ primaryAdapter WRITE setPrimaryAdapter NOTIFY configChanged)
    Q_PROPERTY(QString secondaryAdapter READ secondaryAdapter WRITE setSecondaryAdapter NOTIFY configChanged)
    Q_PROPERTY(QString primaryAdapterName READ primaryAdapterName NOTIFY statusChanged)
    Q_PROPERTY(QString secondaryAdapterName READ secondaryAdapterName NOTIFY statusChanged)
    Q_PROPERTY(QString primaryReason READ primaryReason NOTIFY statusChanged)
    Q_PROPERTY(QString secondaryReason READ secondaryReason NOTIFY statusChanged)
    Q_PROPERTY(QString providerId READ providerId NOTIFY statusChanged)
    Q_PROPERTY(QString providerStatus READ providerStatus NOTIFY statusChanged)
    Q_PROPERTY(QString networkDiscoveryState READ networkDiscoveryState NOTIFY statusChanged)
    Q_PROPERTY(QString degradedReason READ degradedReason NOTIFY statusChanged)
    Q_PROPERTY(QString lastObservationTime READ lastObservationTime NOTIFY statusChanged)
    Q_PROPERTY(QString scope READ scope WRITE setScope NOTIFY configChanged)
    Q_PROPERTY(bool fixtureMode READ isFixtureMode NOTIFY statusChanged)
    Q_PROPERTY(bool conmonRunning READ isConmonRunning NOTIFY statusChanged)
    Q_PROPERTY(bool controllerRunning READ isControllerRunning NOTIFY statusChanged)
    Q_PROPERTY(QVariantList availableAdapters READ availableAdapters NOTIFY adaptersChanged)
    Q_PROPERTY(QString overallStatusText READ overallStatusText NOTIFY statusChanged)

public:
    explicit Monitor(Settings *settings = nullptr, QObject *parent = nullptr);
    ~Monitor() override;

    bool isEnabled() const;
    void setEnabled(bool enable);

    QString primaryRoleState() const;
    QString secondaryRoleState() const;

    QString primaryAdapter() const;
    void setPrimaryAdapter(const QString &adapter);

    QString secondaryAdapter() const;
    void setSecondaryAdapter(const QString &adapter);

    QString primaryAdapterName() const;
    QString secondaryAdapterName() const;

    QString primaryReason() const;
    QString secondaryReason() const;

    QString providerId() const;
    QString providerStatus() const;
    QString networkDiscoveryState() const;
    QString degradedReason() const;
    QString lastObservationTime() const;
    QString scope() const;
    void setScope(const QString &scope);

    bool isFixtureMode() const;
    bool isConmonRunning() const;
    bool isControllerRunning() const;

    QVariantList availableAdapters() const;
    QString overallStatusText() const;

    Q_INVOKABLE void refresh();
    Q_INVOKABLE void autodetectFromController();
    Q_INVOKABLE void injectFixture(const QVariantMap &fixture);
    Q_INVOKABLE void clearFixture();

    static QString stateToString(LinkState state);
    static LinkState stringToState(const QString &stateStr);

signals:
    void enabledChanged(bool enabled);
    void configChanged();
    void statusChanged();
    void adaptersChanged();

private slots:
    void pollStatus();

private:
    void updateAdapters();
    void computeSnapshot();
    LinkState probeInterface(const QString &ifname, QString *reason = nullptr);
    void checkDanteDaemons(bool *conmon, bool *controller);
    QString findFriendlyName(const QString &ifname) const;

    Settings *m_settings = nullptr;
    QTimer m_pollTimer;
    quint64 m_generation = 0;

    bool m_enabled = false;
    QString m_primaryAdapter;
    QString m_secondaryAdapter;
    QString m_scope = QStringLiteral("This Mac: Network Links");

    bool m_inFixtureMode = false;
    Snapshot m_fixtureSnapshot;

    Snapshot m_currentSnapshot;
    QList<AdapterInfo> m_cachedAdapters;
};

} // namespace dante

#endif // DANTEMONITOR_H
