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
#include <QtTest>
#include <QSignalSpy>
#include "dante/monitor.h"
#include "common/settings.h"

class DanteTest : public QObject {
    Q_OBJECT

private slots:
    void initTestCase();
    void cleanupTestCase();

    void testInitialState();
    void testEnableDisableLifecycle();
    void testInterfaceProbing();
    void testDaemonDetection();
    void testFixtureTransitions();
    void testSettingsPersistence();
    void testEmptyNetworkBehavior();
    void testDisconnectedServiceBehavior();
};

void DanteTest::initTestCase()
{
}

void DanteTest::cleanupTestCase()
{
}

void DanteTest::testInitialState()
{
    Settings settings;
    auto group = settings.getGroup(QStringLiteral("test_dante_initial"));
    dante::Monitor monitor(group);

    // Initial state should be Off by default
    QCOMPARE(monitor.isEnabled(), false);
    QCOMPARE(monitor.primaryRoleState(), QStringLiteral("Off"));
    QCOMPARE(monitor.secondaryRoleState(), QStringLiteral("Off"));
    QVERIFY(monitor.overallStatusText().contains(QStringLiteral("Off")));
    QCOMPARE(monitor.isFixtureMode(), false);
}

void DanteTest::testEnableDisableLifecycle()
{
    Settings settings;
    auto group = settings.getGroup(QStringLiteral("test_dante_lifecycle"));
    dante::Monitor monitor(group);

    QSignalSpy enabledSpy(&monitor, &dante::Monitor::enabledChanged);
    QSignalSpy statusSpy(&monitor, &dante::Monitor::statusChanged);

    monitor.setEnabled(true);
    QCOMPARE(monitor.isEnabled(), true);
    QCOMPARE(enabledSpy.count(), 1);
    QVERIFY(statusSpy.count() >= 1);

    // When enabled, states transition away from Off (to Up, Down, or Not configured)
    QVERIFY(monitor.primaryRoleState() != QStringLiteral("Off"));

    monitor.setEnabled(false);
    QCOMPARE(monitor.isEnabled(), false);
    QCOMPARE(enabledSpy.count(), 2);
    QCOMPARE(monitor.primaryRoleState(), QStringLiteral("Off"));
    QCOMPARE(monitor.secondaryRoleState(), QStringLiteral("Off"));
}

void DanteTest::testInterfaceProbing()
{
    Settings settings;
    auto group = settings.getGroup(QStringLiteral("test_dante_probing"));
    dante::Monitor monitor(group);
    monitor.setEnabled(true);

    // 1. Unassigned interface should be Not configured
    monitor.setPrimaryAdapter(QString());
    QCOMPARE(monitor.primaryRoleState(), QStringLiteral("Not configured"));

    // 2. Non-existent interface should be Down
    monitor.setPrimaryAdapter(QStringLiteral("nonexistent_nic99"));
    QCOMPARE(monitor.primaryRoleState(), QStringLiteral("Down"));
    QCOMPARE(monitor.primaryReason(), QStringLiteral("Interface not found"));

    // 3. Known active Wi-Fi adapter (en0) should be Up
    monitor.setPrimaryAdapter(QStringLiteral("en0"));
    QCOMPARE(monitor.primaryRoleState(), QStringLiteral("Up"));
    QCOMPARE(monitor.primaryReason(), QStringLiteral("Link carrier active"));

    // 4. Inactive Ethernet adapter (en4) should be Down with cable unplugged reason
    monitor.setSecondaryAdapter(QStringLiteral("en4"));
    QCOMPARE(monitor.secondaryRoleState(), QStringLiteral("Down"));
    QVERIFY(monitor.secondaryReason().contains(QStringLiteral("carrier")) ||
            monitor.secondaryReason().contains(QStringLiteral("unplugged")));
}

void DanteTest::testDaemonDetection()
{
    Settings settings;
    auto group = settings.getGroup(QStringLiteral("test_dante_daemons"));
    dante::Monitor monitor(group);
    monitor.setEnabled(true);

    // On macOS host, Audinate ConMon daemon (conmon_cmm) is running
    QVERIFY(monitor.isConmonRunning());
    QVERIFY(monitor.providerStatus().contains(QStringLiteral("ConMon")));
}

void DanteTest::testFixtureTransitions()
{
    Settings settings;
    auto group = settings.getGroup(QStringLiteral("test_dante_fixtures"));
    dante::Monitor monitor(group);

    // Inject Up/Up fixture
    QVariantMap f1;
    f1[QStringLiteral("primaryState")] = QStringLiteral("Up");
    f1[QStringLiteral("secondaryState")] = QStringLiteral("Up");
    f1[QStringLiteral("discoveryState")] = QStringLiteral("No Dante devices detected");
    monitor.injectFixture(f1);

    QCOMPARE(monitor.isFixtureMode(), true);
    QCOMPARE(monitor.primaryRoleState(), QStringLiteral("Up"));
    QCOMPARE(monitor.secondaryRoleState(), QStringLiteral("Up"));
    QVERIFY(monitor.overallStatusText().contains(QStringLiteral("[FIXTURE]")));

    // Inject Up/Down fixture (Secondary failure)
    QVariantMap f2;
    f2[QStringLiteral("primaryState")] = QStringLiteral("Up");
    f2[QStringLiteral("secondaryState")] = QStringLiteral("Down");
    f2[QStringLiteral("secondaryReason")] = QStringLiteral("Secondary link loss simulated");
    monitor.injectFixture(f2);

    QCOMPARE(monitor.primaryRoleState(), QStringLiteral("Up"));
    QCOMPARE(monitor.secondaryRoleState(), QStringLiteral("Down"));
    QCOMPARE(monitor.secondaryReason(), QStringLiteral("Secondary link loss simulated"));

    // Inject Degraded state
    QVariantMap f3;
    f3[QStringLiteral("primaryState")] = QStringLiteral("Degraded");
    f3[QStringLiteral("secondaryState")] = QStringLiteral("Up");
    f3[QStringLiteral("degradedReason")] = QStringLiteral("High latency / packet loss observed");
    monitor.injectFixture(f3);

    QCOMPARE(monitor.primaryRoleState(), QStringLiteral("Degraded"));
    QCOMPARE(monitor.degradedReason(), QStringLiteral("High latency / packet loss observed"));

    // Inject Unknown / Stale state
    QVariantMap f4;
    f4[QStringLiteral("primaryState")] = QStringLiteral("Unknown");
    f4[QStringLiteral("secondaryState")] = QStringLiteral("Stale");
    monitor.injectFixture(f4);

    QCOMPARE(monitor.primaryRoleState(), QStringLiteral("Unknown"));
    QCOMPARE(monitor.secondaryRoleState(), QStringLiteral("Stale"));

    // Clear fixture restores live computation
    monitor.clearFixture();
    QCOMPARE(monitor.isFixtureMode(), false);
}

void DanteTest::testSettingsPersistence()
{
    Settings settings;
    auto group = settings.getGroup(QStringLiteral("test_dante_persist"));
    {
        dante::Monitor monitor(group);
        monitor.setEnabled(true);
        monitor.setPrimaryAdapter(QStringLiteral("en0"));
        monitor.setSecondaryAdapter(QStringLiteral("en4"));
    }

    // New instance with same settings group should restore state
    {
        dante::Monitor monitor2(group);
        QCOMPARE(monitor2.isEnabled(), true);
        QCOMPARE(monitor2.primaryAdapter(), QStringLiteral("en0"));
        QCOMPARE(monitor2.secondaryAdapter(), QStringLiteral("en4"));
    }
}

void DanteTest::testEmptyNetworkBehavior()
{
    Settings settings;
    auto group = settings.getGroup(QStringLiteral("test_dante_empty"));
    dante::Monitor monitor(group);
    monitor.setEnabled(true);

    // Empty discovery must report "No Dante devices detected", NOT false network alarms
    QCOMPARE(monitor.networkDiscoveryState(), QStringLiteral("No Dante devices detected"));
}

void DanteTest::testDisconnectedServiceBehavior()
{
    Settings settings;
    auto group = settings.getGroup(QStringLiteral("test_dante_disconnect"));
    dante::Monitor monitor(group);

    // Simulate ConMon daemon being stopped / disconnected
    QVariantMap f;
    f[QStringLiteral("conmonRunning")] = false;
    f[QStringLiteral("controllerRunning")] = false;
    f[QStringLiteral("providerStatus")] = QStringLiteral("ConMon daemon disconnected / unavailable");
    f[QStringLiteral("discoveryState")] = QStringLiteral("Monitoring unavailable");
    f[QStringLiteral("degradedReason")] = QStringLiteral("Dante control/monitoring daemon (conmon_cmm) is not running");
    monitor.injectFixture(f);

    QCOMPARE(monitor.isConmonRunning(), false);
    QCOMPARE(monitor.networkDiscoveryState(), QStringLiteral("Monitoring unavailable"));
    QVERIFY(monitor.providerStatus().contains(QStringLiteral("disconnected")));
    QVERIFY(monitor.degradedReason().contains(QStringLiteral("conmon_cmm")));
}

QTEST_MAIN(DanteTest)
#include "tst_dante.moc"
