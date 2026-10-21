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
 *  along with this program.  If not, see <http://www.gnu.org/licenses/>.\n */
#include "monitor.h"

#include <QNetworkInterface>
#include <QElapsedTimer>
#include <cstring>

#if defined(Q_OS_MACOS)
#include <CoreFoundation/CoreFoundation.h>
#include <libproc.h>
#include <unistd.h>
#include <sys/ioctl.h>
#include <sys/socket.h>
#include <net/if.h>
#include <net/if_media.h>
#endif

namespace dante {

Monitor::Monitor(Settings *settings, QObject *parent)
    : QObject(parent)
    , m_settings(settings)
{
    if (m_settings) {
        m_enabled = m_settings->value(QStringLiteral("enabled"), false).toBool();
        m_primaryAdapter = m_settings->value(QStringLiteral("primaryAdapter"), QString()).toString();
        m_secondaryAdapter = m_settings->value(QStringLiteral("secondaryAdapter"), QString()).toString();
        m_scope = m_settings->value(QStringLiteral("scope"), QStringLiteral("This Mac: Network Links")).toString();
    }

    connect(&m_pollTimer, &QTimer::timeout, this, &Monitor::pollStatus);
    m_pollTimer.setInterval(1000); // 1 Hz low-frequency check when enabled

    updateAdapters();

    // If no adapters are configured yet, attempt auto-detect from Controller preferences
    if (m_primaryAdapter.isEmpty()) {
        autodetectFromController();
    }

    if (m_enabled) {
        m_pollTimer.start();
    }

    computeSnapshot();
}

Monitor::~Monitor()
{
    m_pollTimer.stop();
}

bool Monitor::isEnabled() const
{
    return m_enabled;
}

void Monitor::setEnabled(bool enable)
{
    if (m_enabled == enable)
        return;

    m_enabled = enable;
    if (m_settings) {
        m_settings->setValue(QStringLiteral("enabled"), m_enabled);
    }

    if (m_enabled) {
        m_pollTimer.start();
    } else {
        m_pollTimer.stop();
    }

    emit enabledChanged(m_enabled);
    computeSnapshot();
}

QString Monitor::stateToString(LinkState state)
{
    switch (state) {
    case LinkState::Up:
        return QStringLiteral("Up");
    case LinkState::Down:
        return QStringLiteral("Down");
    case LinkState::Degraded:
        return QStringLiteral("Degraded");
    case LinkState::Unknown:
        return QStringLiteral("Unknown");
    case LinkState::Stale:
        return QStringLiteral("Stale");
    case LinkState::NotConfigured:
        return QStringLiteral("Not configured");
    case LinkState::Off:
    default:
        return QStringLiteral("Off");
    }
}

LinkState Monitor::stringToState(const QString &stateStr)
{
    if (stateStr.compare(QLatin1String("Up"), Qt::CaseInsensitive) == 0)
        return LinkState::Up;
    if (stateStr.compare(QLatin1String("Down"), Qt::CaseInsensitive) == 0)
        return LinkState::Down;
    if (stateStr.compare(QLatin1String("Degraded"), Qt::CaseInsensitive) == 0)
        return LinkState::Degraded;
    if (stateStr.compare(QLatin1String("Unknown"), Qt::CaseInsensitive) == 0)
        return LinkState::Unknown;
    if (stateStr.compare(QLatin1String("Stale"), Qt::CaseInsensitive) == 0)
        return LinkState::Stale;
    if (stateStr.compare(QLatin1String("Not configured"), Qt::CaseInsensitive) == 0)
        return LinkState::NotConfigured;
    return LinkState::Off;
}

QString Monitor::primaryRoleState() const
{
    const auto &s = m_inFixtureMode ? m_fixtureSnapshot : m_currentSnapshot;
    return stateToString(s.primaryState);
}

QString Monitor::secondaryRoleState() const
{
    const auto &s = m_inFixtureMode ? m_fixtureSnapshot : m_currentSnapshot;
    return stateToString(s.secondaryState);
}

QString Monitor::primaryAdapter() const
{
    return m_primaryAdapter;
}

void Monitor::setPrimaryAdapter(const QString &adapter)
{
    if (m_primaryAdapter == adapter)
        return;

    m_primaryAdapter = adapter;
    if (m_settings) {
        m_settings->setValue(QStringLiteral("primaryAdapter"), m_primaryAdapter);
    }
    emit configChanged();
    computeSnapshot();
}

QString Monitor::secondaryAdapter() const
{
    return m_secondaryAdapter;
}

void Monitor::setSecondaryAdapter(const QString &adapter)
{
    if (m_secondaryAdapter == adapter)
        return;

    m_secondaryAdapter = adapter;
    if (m_settings) {
        m_settings->setValue(QStringLiteral("secondaryAdapter"), m_secondaryAdapter);
    }
    emit configChanged();
    computeSnapshot();
}

QString Monitor::primaryAdapterName() const
{
    const auto &s = m_inFixtureMode ? m_fixtureSnapshot : m_currentSnapshot;
    return s.primaryAdapterName;
}

QString Monitor::secondaryAdapterName() const
{
    const auto &s = m_inFixtureMode ? m_fixtureSnapshot : m_currentSnapshot;
    return s.secondaryAdapterName;
}

QString Monitor::primaryReason() const
{
    const auto &s = m_inFixtureMode ? m_fixtureSnapshot : m_currentSnapshot;
    return s.primaryReason;
}

QString Monitor::secondaryReason() const
{
    const auto &s = m_inFixtureMode ? m_fixtureSnapshot : m_currentSnapshot;
    return s.secondaryReason;
}

QString Monitor::providerId() const
{
    const auto &s = m_inFixtureMode ? m_fixtureSnapshot : m_currentSnapshot;
    return s.providerId;
}

QString Monitor::providerStatus() const
{
    const auto &s = m_inFixtureMode ? m_fixtureSnapshot : m_currentSnapshot;
    return s.providerStatus;
}

QString Monitor::networkDiscoveryState() const
{
    const auto &s = m_inFixtureMode ? m_fixtureSnapshot : m_currentSnapshot;
    return s.discoveryState;
}

QString Monitor::degradedReason() const
{
    const auto &s = m_inFixtureMode ? m_fixtureSnapshot : m_currentSnapshot;
    return s.degradedReason;
}

QString Monitor::lastObservationTime() const
{
    const auto &s = m_inFixtureMode ? m_fixtureSnapshot : m_currentSnapshot;
    if (!s.observationTime.isValid())
        return QStringLiteral("—");
    return s.observationTime.toString(QStringLiteral("hh:mm:ss"));
}

QString Monitor::scope() const
{
    return m_scope;
}

void Monitor::setScope(const QString &scope)
{
    if (m_scope == scope)
        return;

    m_scope = scope;
    if (m_settings) {
        m_settings->setValue(QStringLiteral("scope"), m_scope);
    }
    emit configChanged();
    computeSnapshot();
}

bool Monitor::isFixtureMode() const
{
    return m_inFixtureMode;
}

bool Monitor::isConmonRunning() const
{
    const auto &s = m_inFixtureMode ? m_fixtureSnapshot : m_currentSnapshot;
    return s.conmonRunning;
}

bool Monitor::isControllerRunning() const
{
    const auto &s = m_inFixtureMode ? m_fixtureSnapshot : m_currentSnapshot;
    return s.controllerRunning;
}

QVariantList Monitor::availableAdapters() const
{
    QVariantList list;
    for (const auto &adapter : m_cachedAdapters) {
        QVariantMap map;
        map[QStringLiteral("id")] = adapter.id;
        map[QStringLiteral("name")] = adapter.name;
        map[QStringLiteral("mac")] = adapter.mac;
        map[QStringLiteral("active")] = adapter.active;
        list.append(map);
    }
    return list;
}

QString Monitor::overallStatusText() const
{
    if (!m_enabled && !m_inFixtureMode)
        return QStringLiteral("Dante Monitoring: Off");

    const auto &s = m_inFixtureMode ? m_fixtureSnapshot : m_currentSnapshot;
    QString text;
    if (s.fixtureMode) {
        text += QStringLiteral("[FIXTURE] ");
    }
    text += QStringLiteral("Primary: %1 · Secondary: %2 (%3)")
                .arg(stateToString(s.primaryState),
                     stateToString(s.secondaryState),
                     s.discoveryState);
    return text;
}

void Monitor::refresh()
{
    updateAdapters();
    computeSnapshot();
}

void Monitor::pollStatus()
{
    if (!m_enabled && !m_inFixtureMode)
        return;

    computeSnapshot();
}

void Monitor::autodetectFromController()
{
#if defined(Q_OS_MACOS)
    CFArrayRef intfs = (CFArrayRef)CFPreferencesCopyAppValue(CFSTR("intfs"), CFSTR("com.audinate.dante.controller"));
    if (intfs && CFGetTypeID(intfs) == CFArrayGetTypeID()) {
        CFIndex count = CFArrayGetCount(intfs);
        for (CFIndex i = 0; i < count; i++) {
            CFDictionaryRef dict = (CFDictionaryRef)CFArrayGetValueAtIndex(intfs, i);
            if (dict && CFGetTypeID(dict) == CFDictionaryGetTypeID()) {
                CFDataRef nameData = (CFDataRef)CFDictionaryGetValue(dict, CFSTR("name"));
                if (nameData && CFGetTypeID(nameData) == CFDataGetTypeID()) {
                    const UInt8 *bytes = CFDataGetBytePtr(nameData);
                    CFIndex len = CFDataGetLength(nameData);
                    CFStringRef str = CFStringCreateWithBytes(NULL, bytes, len, kCFStringEncodingUTF32LE, false);
                    if (!str)
                        str = CFStringCreateWithBytes(NULL, bytes, len, kCFStringEncodingUTF16LE, false);
                    if (str) {
                        char buf[128];
                        if (CFStringGetCString(str, buf, sizeof(buf), kCFStringEncodingUTF8)) {
                            QString ifname = QString::fromUtf8(buf).trimmed();
                            if (i == 0 && !ifname.isEmpty()) {
                                m_primaryAdapter = ifname;
                                if (m_settings) m_settings->setValue(QStringLiteral("primaryAdapter"), m_primaryAdapter);
                            } else if (i == 1 && !ifname.isEmpty()) {
                                m_secondaryAdapter = ifname;
                                if (m_settings) m_settings->setValue(QStringLiteral("secondaryAdapter"), m_secondaryAdapter);
                            }
                        }
                        CFRelease(str);
                    }
                }
            }
        }
        CFRelease(intfs);
    }
#endif

    // Fallback if primary is still empty: select first active Ethernet or first interface
    if (m_primaryAdapter.isEmpty()) {
        for (const auto &info : m_cachedAdapters) {
            if (info.active) {
                m_primaryAdapter = info.id;
                if (m_settings) m_settings->setValue(QStringLiteral("primaryAdapter"), m_primaryAdapter);
                break;
            }
        }
    }

    emit configChanged();
    computeSnapshot();
}

void Monitor::injectFixture(const QVariantMap &fixture)
{
    m_inFixtureMode = true;
    m_fixtureSnapshot.generation = ++m_generation;
    m_fixtureSnapshot.fixtureMode = true;
    m_fixtureSnapshot.enabled = true;
    m_fixtureSnapshot.observationTime = QDateTime::currentDateTime();

    if (fixture.contains(QStringLiteral("primaryState"))) {
        m_fixtureSnapshot.primaryState = stringToState(fixture.value(QStringLiteral("primaryState")).toString());
    } else {
        m_fixtureSnapshot.primaryState = LinkState::Up;
    }

    if (fixture.contains(QStringLiteral("secondaryState"))) {
        m_fixtureSnapshot.secondaryState = stringToState(fixture.value(QStringLiteral("secondaryState")).toString());
    } else {
        m_fixtureSnapshot.secondaryState = LinkState::NotConfigured;
    }

    m_fixtureSnapshot.primaryAdapter = fixture.value(QStringLiteral("primaryAdapter"), QStringLiteral("en0")).toString();
    m_fixtureSnapshot.secondaryAdapter = fixture.value(QStringLiteral("secondaryAdapter"), QString()).toString();
    m_fixtureSnapshot.primaryAdapterName = findFriendlyName(m_fixtureSnapshot.primaryAdapter);
    m_fixtureSnapshot.secondaryAdapterName = findFriendlyName(m_fixtureSnapshot.secondaryAdapter);

    m_fixtureSnapshot.primaryReason = fixture.value(QStringLiteral("primaryReason"), QStringLiteral("Fixture active")).toString();
    m_fixtureSnapshot.secondaryReason = fixture.value(QStringLiteral("secondaryReason"), QStringLiteral("Fixture active")).toString();

    m_fixtureSnapshot.conmonRunning = fixture.value(QStringLiteral("conmonRunning"), true).toBool();
    m_fixtureSnapshot.controllerRunning = fixture.value(QStringLiteral("controllerRunning"), true).toBool();

    m_fixtureSnapshot.providerId = QStringLiteral("Fixture Test Provider");
    m_fixtureSnapshot.providerStatus = fixture.value(QStringLiteral("providerStatus"), QStringLiteral("Simulated Test Provider Active")).toString();
    m_fixtureSnapshot.discoveryState = fixture.value(QStringLiteral("discoveryState"), QStringLiteral("No Dante devices detected")).toString();
    m_fixtureSnapshot.degradedReason = fixture.value(QStringLiteral("degradedReason"), QString()).toString();
    m_fixtureSnapshot.scope = m_scope;

    emit statusChanged();
}

void Monitor::clearFixture()
{
    m_inFixtureMode = false;
    computeSnapshot();
}

void Monitor::updateAdapters()
{
    QList<AdapterInfo> newAdapters;
    const auto all = QNetworkInterface::allInterfaces();
    for (const auto &iface : all) {
        if (iface.flags().testFlag(QNetworkInterface::IsLoopBack))
            continue;

        AdapterInfo info;
        info.id = iface.name();
        info.mac = iface.hardwareAddress();

        QString friendly = iface.humanReadableName();
        if (friendly.isEmpty() || friendly == info.id) {
            info.name = info.id;
        } else {
            info.name = QStringLiteral("%1 (%2)").arg(friendly, info.id);
        }

        info.active = (probeInterface(info.id) == LinkState::Up);
        newAdapters.append(info);
    }

    if (m_cachedAdapters.size() != newAdapters.size()) {
        m_cachedAdapters = newAdapters;
        emit adaptersChanged();
    } else {
        bool changed = false;
        for (int i = 0; i < newAdapters.size(); ++i) {
            if (m_cachedAdapters[i].id != newAdapters[i].id ||
                m_cachedAdapters[i].active != newAdapters[i].active ||
                m_cachedAdapters[i].name != newAdapters[i].name) {
                changed = true;
                break;
            }
        }
        if (changed) {
            m_cachedAdapters = newAdapters;
            emit adaptersChanged();
        }
    }
}

QString Monitor::findFriendlyName(const QString &ifname) const
{
    if (ifname.isEmpty())
        return QStringLiteral("Not assigned");

    for (const auto &item : m_cachedAdapters) {
        if (item.id == ifname)
            return item.name;
    }
    return ifname;
}

LinkState Monitor::probeInterface(const QString &ifname, QString *reason)
{
    if (ifname.isEmpty()) {
        if (reason) *reason = QStringLiteral("Role unassigned");
        return LinkState::NotConfigured;
    }

#if defined(Q_OS_MACOS)
    int s = socket(AF_INET, SOCK_DGRAM, 0);
    if (s < 0) {
        if (reason) *reason = QStringLiteral("Socket error");
        return LinkState::Unknown;
    }

    struct ifreq ifr;
    std::memset(&ifr, 0, sizeof(ifr));
    std::strncpy(ifr.ifr_name, ifname.toUtf8().constData(), sizeof(ifr.ifr_name) - 1);

    if (ioctl(s, SIOCGIFFLAGS, &ifr) < 0) {
        close(s);
        if (reason) *reason = QStringLiteral("Interface not found");
        return LinkState::Down;
    }

    if (!(ifr.ifr_flags & IFF_UP)) {
        close(s);
        if (reason) *reason = QStringLiteral("Interface administratively down");
        return LinkState::Down;
    }

    struct ifmediareq ifmr;
    std::memset(&ifmr, 0, sizeof(ifmr));
    std::strncpy(ifmr.ifm_name, ifname.toUtf8().constData(), sizeof(ifmr.ifm_name) - 1);

    if (ioctl(s, SIOCGIFMEDIA, &ifmr) >= 0) {
        if (ifmr.ifm_status & IFM_AVALID) {
            if (ifmr.ifm_status & IFM_ACTIVE) {
                close(s);
                if (reason) *reason = QStringLiteral("Link carrier active");
                return LinkState::Up;
            } else {
                close(s);
                if (reason) *reason = QStringLiteral("No link carrier (unplugged)");
                return LinkState::Down;
            }
        }
    }

    // Fallback for virtual or non-media interfaces
    bool running = (ifr.ifr_flags & IFF_RUNNING) != 0;
    close(s);
    if (running) {
        if (reason) *reason = QStringLiteral("Link running");
        return LinkState::Up;
    } else {
        if (reason) *reason = QStringLiteral("Link not running");
        return LinkState::Down;
    }
#else
    const auto iface = QNetworkInterface::interfaceFromName(ifname);
    if (!iface.isValid()) {
        if (reason) *reason = QStringLiteral("Interface not found");
        return LinkState::Down;
    }
    if (iface.flags().testFlag(QNetworkInterface::IsRunning)) {
        if (reason) *reason = QStringLiteral("Interface running");
        return LinkState::Up;
    }
    if (reason) *reason = QStringLiteral("Interface down");
    return LinkState::Down;
#endif
}

void Monitor::checkDanteDaemons(bool *conmon, bool *controller)
{
    *conmon = false;
    *controller = false;

#if defined(Q_OS_MACOS)
    pid_t pids[2048];
    int bytes = proc_listpids(PROC_ALL_PIDS, 0, pids, sizeof(pids));
    if (bytes > 0) {
        int count = bytes / sizeof(pid_t);
        for (int i = 0; i < count; ++i) {
            if (pids[i] <= 0) continue;
            char path[PROC_PIDPATHINFO_MAXSIZE];
            if (proc_pidpath(pids[i], path, sizeof(path)) > 0) {
                if (!*conmon && std::strstr(path, "conmon_cmm") != nullptr) {
                    *conmon = true;
                }
                if (!*controller && std::strstr(path, "Dante Controller") != nullptr) {
                    *controller = true;
                }
            }
            if (*conmon && *controller)
                break;
        }
    }
#endif
}

void Monitor::computeSnapshot()
{
    if (m_inFixtureMode)
        return;

    Snapshot next;
    next.generation = ++m_generation;
    next.enabled = m_enabled;
    next.fixtureMode = false;
    next.scope = m_scope;
    next.providerId = QStringLiteral("Dante Local Services + macOS Link Monitor");

    if (!m_enabled) {
        next.primaryState = LinkState::Off;
        next.primaryReason = QStringLiteral("Monitoring disabled");
        next.secondaryState = LinkState::Off;
        next.secondaryReason = QStringLiteral("Monitoring disabled");
        next.providerStatus = QStringLiteral("Disabled");
        next.discoveryState = QStringLiteral("Monitoring off");
        next.primaryAdapter = m_primaryAdapter;
        next.secondaryAdapter = m_secondaryAdapter;
        next.primaryAdapterName = findFriendlyName(m_primaryAdapter);
        next.secondaryAdapterName = findFriendlyName(m_secondaryAdapter);

        if (next != m_currentSnapshot) {
            m_currentSnapshot = next;
            emit statusChanged();
        }
        return;
    }

    next.observationTime = QDateTime::currentDateTime();

    // Check daemon state
    checkDanteDaemons(&next.conmonRunning, &next.controllerRunning);

    if (next.conmonRunning) {
        if (next.controllerRunning) {
            next.providerStatus = QStringLiteral("ConMon active · Dante Controller open");
        } else {
            next.providerStatus = QStringLiteral("ConMon daemon active · Dante Controller closed");
        }
        next.discoveryState = QStringLiteral("No Dante devices detected");
    } else {
        next.providerStatus = QStringLiteral("ConMon daemon disconnected / unavailable");
        next.discoveryState = QStringLiteral("Monitoring unavailable");
        next.degradedReason = QStringLiteral("Dante control/monitoring daemon (conmon_cmm) is not running");
    }

    next.primaryAdapter = m_primaryAdapter;
    next.secondaryAdapter = m_secondaryAdapter;
    next.primaryAdapterName = findFriendlyName(m_primaryAdapter);
    next.secondaryAdapterName = findFriendlyName(m_secondaryAdapter);

    next.primaryState = probeInterface(m_primaryAdapter, &next.primaryReason);
    next.secondaryState = probeInterface(m_secondaryAdapter, &next.secondaryReason);

    if (next.primaryState == LinkState::Down || next.secondaryState == LinkState::Down) {
        if (next.degradedReason.isEmpty()) {
            if (next.primaryState == LinkState::Down && next.secondaryState == LinkState::Down) {
                next.degradedReason = QStringLiteral("Both Primary and Secondary network links are down");
            } else if (next.primaryState == LinkState::Down) {
                next.degradedReason = QStringLiteral("Primary network link is down (%1)").arg(next.primaryReason);
            } else if (next.secondaryState == LinkState::Down) {
                next.degradedReason = QStringLiteral("Secondary network link is down (%1)").arg(next.secondaryReason);
            }
        }
    }

    if (next != m_currentSnapshot) {
        m_currentSnapshot = next;
        emit statusChanged();
    }
}

} // namespace dante
